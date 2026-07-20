import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/ajuste_service.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import 'detalle_ajuste_screen.dart';

class NuevoAjusteScreen extends StatefulWidget {
  final UserModel user;
  const NuevoAjusteScreen({super.key, required this.user});

  @override
  State<NuevoAjusteScreen> createState() => _NuevoAjusteScreenState();
}

class _NuevoAjusteScreenState extends State<NuevoAjusteScreen> {
  final _ajusteService = AjusteService();
  final _ventaService = VentaService();
  final _descripCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  DateTime _fecha = DateTime.now();
  String _razon = 'DETERIORO';
  List _carrito = [];
  bool _isGuardando = false;

  // Razones disponibles
  final List<Map<String, dynamic>> _razones = [
    {
      'valor': 'DETERIORO',
      'label': 'Deterioro',
      'icon': Icons.broken_image_outlined,
      'color': AppColors.error
    },
    {
      'valor': 'VENCIMIENTO',
      'label': 'Vencimiento',
      'icon': Icons.event_busy_outlined,
      'color': AppColors.warning
    },
    {
      'valor': 'DONACION',
      'label': 'Donación',
      'icon': Icons.volunteer_activism,
      'color': AppColors.success
    },
    {
      'valor': 'ROBO',
      'label': 'Robo/Pérdida',
      'icon': Icons.security_outlined,
      'color': AppColors.error
    },
    {
      'valor': 'OTRO',
      'label': 'Otro motivo',
      'icon': Icons.help_outline,
      'color': AppColors.textSecondary
    },
  ];

  @override
  void dispose() {
    _descripCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fechaSql(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fechaDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (fecha != null && mounted) setState(() => _fecha = fecha);
  }

  Future<void> _buscarYAgregar() async {
    final busqueda = _searchCtrl.text.trim();
    if (busqueda.isEmpty) return;

    final result = await _ventaService.buscarProductos(busqueda);
    if (result['success'] != true) return;

    final productos = result['productos'] as List;
    if (productos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto no encontrado'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    Map? seleccionado;
    if (productos.length == 1) {
      seleccionado = productos.first;
    } else {
      seleccionado = await showModalBottomSheet<Map>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: productos.length,
          itemBuilder: (_, i) {
            final p = productos[i];
            final existen =
                double.tryParse(p['produc_existen'].toString()) ?? 0;
            return ListTile(
              title: Text(p['produc_descrip'] ?? ''),
              subtitle: Text('Stock: ${existen.toStringAsFixed(0)}'),
              onTap: () => Navigator.pop(context, p),
            );
          },
        ),
      );
    }

    if (seleccionado == null) return;

    final existencia =
        double.tryParse(seleccionado['produc_existen'].toString()) ?? 0;

    // Pedir cantidad
    final cantCtrl = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(seleccionado!['produc_descrip'] ?? '',
                style: const TextStyle(fontSize: 14)),
            Text(
              'Stock disponible: ${existencia.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ],
        ),
        content: TextField(
          controller: cantCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Cantidad a dar de baja',
            prefixIcon: Icon(Icons.remove_circle_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final cant = double.tryParse(cantCtrl.text) ?? 0;
              if (cant <= 0) return;
              if (cant > existencia) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Stock insuficiente. Disponible: ${existencia.toStringAsFixed(0)}'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              setState(() {
                final idx = _carrito.indexWhere((c) =>
                    c['produc_ide'].toString() ==
                    seleccionado!['produc_ide'].toString());
                if (idx >= 0) {
                  _carrito[idx]['cantidad'] =
                      (_carrito[idx]['cantidad'] as double) + cant;
                } else {
                  _carrito.add({
                    'produc_ide': seleccionado!['produc_ide'],
                    'descripcion': seleccionado['produc_descrip'],
                    'cantidad': cant,
                    'costo': double.tryParse(
                            seleccionado['produc_costo'].toString()) ??
                        0,
                    'existencia': existencia,
                  });
                }
              });
              Navigator.pop(context);
              _searchCtrl.clear();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (_descripCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La descripción del motivo es obligatoria'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isGuardando = true);

    final items = _carrito
        .map((c) => {
              'produc_ide': c['produc_ide'],
              'descripcion': c['descripcion'],
              'cantidad': c['cantidad'],
              'costo': c['costo'],
            })
        .toList();

    final result = await _ajusteService.crear(
      usuaIde: widget.user.usuaIde,
      razon: _razon,
      descripcion: _descripCtrl.text.trim(),
      fecha: _fechaSql(_fecha),
      items: items,
    );

    setState(() => _isGuardando = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor: AppColors.success,
        ),
      );

      final ajusteIde = int.tryParse(result['ajuste_ide'].toString()) ?? 0;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleAjusteScreen(
            user: widget.user,
            ajusteIde: ajusteIde,
          ),
        ),
      );

      setState(() {
        _carrito.clear();
        _descripCtrl.clear();
        _razon = 'DETERIORO';
        _fecha = DateTime.now();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final razonActual = _razones.firstWhere((r) => r['valor'] == _razon,
        orElse: () => _razones.first);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fecha ────────────────────────────────────
            _seccion('FECHA DEL AJUSTE'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.textHint, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _fechaDisplay(_fecha),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar,
                        color: AppColors.textHint, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Razón de baja ─────────────────────────────
            _seccion('RAZÓN DE BAJA'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _razones.map((r) {
                final sel = _razon == r['valor'];
                return GestureDetector(
                  onTap: () => setState(() => _razon = r['valor']),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? (r['color'] as Color).withAlpha(30)
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? r['color'] as Color : AppColors.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(r['icon'] as IconData,
                            color:
                                sel ? r['color'] as Color : AppColors.textHint,
                            size: 16),
                        const SizedBox(width: 6),
                        Text(
                          r['label'] as String,
                          style: TextStyle(
                            color: sel
                                ? r['color'] as Color
                                : AppColors.textSecondary,
                            fontWeight:
                                sel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ── Descripción obligatoria ────────────────────
            _seccion('DESCRIPCIÓN DEL MOTIVO *'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (razonActual['color'] as Color).withAlpha(100),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _descripCtrl,
                maxLines: 3,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Describe detalladamente el motivo '
                      'de la baja de inventario...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Icon(
                      razonActual['icon'] as IconData,
                      color: razonActual['color'] as Color,
                      size: 20,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Productos ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _seccion('PRODUCTOS A DAR DE BAJA '
                    '(${_carrito.length})'),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Buscar producto por nombre o código...',
                      prefixIcon: Icon(Icons.search, size: 18),
                    ),
                    onSubmitted: (_) => _buscarYAgregar(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _buscarYAgregar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  child: const Icon(Icons.search, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_carrito.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.remove_shopping_cart_outlined,
                          color: AppColors.textHint, size: 36),
                      SizedBox(height: 8),
                      Text('Sin productos agregados',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: List.generate(_carrito.length, (i) {
                    final item = _carrito[i];
                    final cant = item['cantidad'] as double;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.errorBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.remove_circle_outline,
                                    color: AppColors.error, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['descripcion'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Stock actual: ${(item['existencia'] as double).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.errorBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '-${cant.toStringAsFixed(0)} uds',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 20),
                                onPressed: () =>
                                    setState(() => _carrito.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                        if (i < _carrito.length - 1)
                          const Divider(height: 1, color: AppColors.border),
                      ],
                    );
                  }),
                ),
              ),

            const SizedBox(height: 24),

            // ── Botón guardar ─────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isGuardando ? null : _guardar,
                icon: _isGuardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.remove_circle_outline),
                label: Text(
                  _isGuardando
                      ? 'Registrando...'
                      : 'Registrar Baja de Inventario',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String t) => Text(t,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ));
}
