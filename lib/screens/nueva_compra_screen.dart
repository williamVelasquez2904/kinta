import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/compra_service.dart';
import '../services/producto_service.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import 'detalle_compra_screen.dart';

class NuevaCompraScreen extends StatefulWidget {
  final UserModel user;
  const NuevaCompraScreen({super.key, required this.user});

  @override
  State<NuevaCompraScreen> createState() => _NuevaCompraScreenState();
}

class _NuevaCompraScreenState extends State<NuevaCompraScreen> {
  final _compraService = CompraService();
  final _ventaService = VentaService();
  final _productoService = ProductoService();
  final _docCtrl = TextEditingController();
  final _observaCtrl = TextEditingController();
  final _impuestoCtrl = TextEditingController(text: '0');
  final _searchProdCtrl = TextEditingController();

  DateTime _fecha = DateTime.now();
  int? _proveIde;
  String? _proveNombre;
  List _proveedores = [];
  List _carrito = [];
  bool _isGuardando = false;

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  @override
  void dispose() {
    _docCtrl.dispose();
    _observaCtrl.dispose();
    _impuestoCtrl.dispose();
    _searchProdCtrl.dispose();
    super.dispose();
  }

  String _fechaSql(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fechaDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _cargarProveedores() async {
    final result =
        await _compraService.listarProveedores(usuaIde: widget.user.usuaIde);
    if (result['success'] == true && mounted) {
      setState(() => _proveedores = result['proveedores'] ?? []);
    }
  }

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

  Future<void> _buscarYAgregarProducto() async {
    final busqueda = _searchProdCtrl.text.trim();
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

    // Si hay varios, mostrar lista para elegir
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
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Seleccionar producto',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: productos.length,
                itemBuilder: (_, i) {
                  final p = productos[i];
                  return ListTile(
                    title: Text(p['produc_descrip'] ?? ''),
                    subtitle: Text('Cód: ${p['produc_codigo'] ?? '-'}'),
                    trailing: Text(
                      'Stock: ${double.tryParse(p['produc_existen'].toString())?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11),
                    ),
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    if (seleccionado == null) return;

    // Cargar detalle completo del producto para mostrar el costo actual.
    seleccionado = await _cargarDetalleProducto(seleccionado);

    // ── Mostrar formulario con todos los campos ──────────────
    await _mostrarFormularioProducto(seleccionado);
  }

  Future<Map> _cargarDetalleProducto(Map producto) async {
    if (producto['produc_ide'] == null) return producto;

    try {
      final result = await _productoService
          .detalle(int.parse(producto['produc_ide'].toString()))
          .timeout(const Duration(seconds: 15));

      if (result['success'] == true && result['producto'] is Map) {
        return result['producto'] as Map;
      }
    } catch (_) {}

    return producto;
  }

  Future<void> _mostrarFormularioProducto(Map producto) async {
    // Controladores con valores actuales del producto
    final cantCtrl = TextEditingController(text: '1');
    final costoCtrl = TextEditingController(
        text:
            (double.tryParse(producto['produc_costo']?.toString() ?? '0') ?? 0)
                .toStringAsFixed(2));
    final precio1Ctrl = TextEditingController(
        text: (double.tryParse(producto['produc_precio1']?.toString() ?? '0') ??
                0)
            .toStringAsFixed(2));
    final precio2Ctrl = TextEditingController(
        text: (double.tryParse(producto['produc_precio2']?.toString() ?? '0') ??
                0)
            .toStringAsFixed(2));
    final precioUsdCtrl = TextEditingController(
        text: (double.tryParse(
                    producto['produc_preciodolar']?.toString() ?? '0') ??
                0)
            .toStringAsFixed(2));

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              producto['produc_descrip'] ?? '',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              'Cód: ${producto['produc_codigo'] ?? '-'}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cantidad
              const Text(
                'CANTIDAD A INGRESAR',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: cantCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cantidad *',
                  prefixIcon: Icon(Icons.add_box_outlined, size: 18),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Precios actuales (editables)
              const Text(
                'PRECIOS ACTUALES (editables)',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),

              // Costo
              TextField(
                controller: costoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Costo',
                  prefixIcon: Icon(Icons.price_check, size: 18),
                ),
              ),
              const SizedBox(height: 8),

              // Precio 1
              TextField(
                controller: precio1Ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio 1 (COP)',
                  prefixIcon: Icon(Icons.attach_money, size: 18),
                ),
              ),
              const SizedBox(height: 8),

              // Precio 2
              TextField(
                controller: precio2Ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio 2 (Bs.)',
                  prefixIcon: Icon(Icons.attach_money, size: 18),
                ),
              ),
              const SizedBox(height: 8),

              // Precio USD
              TextField(
                controller: precioUsdCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio USD',
                  prefixIcon: Icon(Icons.attach_money, size: 18),
                ),
              ),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.warning, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Los precios se actualizarán al confirmar la recepción de la compra.',
                        style:
                            TextStyle(color: AppColors.warning, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_shopping_cart, size: 16),
            label: const Text('Agregar'),
            onPressed: () {
              final cant = double.tryParse(cantCtrl.text) ?? 0;
              final costo = double.tryParse(costoCtrl.text) ?? 0;
              final precio1 = double.tryParse(precio1Ctrl.text) ?? 0;
              final precio2 = double.tryParse(precio2Ctrl.text) ?? 0;
              final precioUsd = double.tryParse(precioUsdCtrl.text) ?? 0;

              if (cant <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La cantidad debe ser mayor a 0'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              setState(() {
                final idx = _carrito.indexWhere((c) =>
                    c['produc_ide'].toString() ==
                    producto['produc_ide'].toString());
                if (idx >= 0) {
                  // Actualizar si ya existe
                  _carrito[idx]['cantidad'] = cant;
                  _carrito[idx]['costo'] = costo;
                  _carrito[idx]['precio1'] = precio1;
                  _carrito[idx]['precio2'] = precio2;
                  _carrito[idx]['precio_usd'] = precioUsd;
                } else {
                  _carrito.add({
                    'produc_ide': producto['produc_ide'],
                    'descripcion': producto['produc_descrip'],
                    'cantidad': cant,
                    'costo': costo,
                    'precio1': precio1,
                    'precio2': precio2,
                    'precio_usd': precioUsd,
                  });
                }
              });
              Navigator.pop(context);
              _searchProdCtrl.clear();
            },
          ),
        ],
      ),
    );
  }

  void _editarItem(int index) {
    final item = _carrito[index];
    // Crear un mapa compatible con el formato de producto
    final productoMock = {
      'produc_ide': item['produc_ide'],
      'produc_descrip': item['descripcion'],
      'produc_codigo': '',
      'produc_costo': item['costo'],
      'produc_precio1': item['precio1'],
      'produc_precio2': item['precio2'],
      'produc_preciodolar': item['precio_usd'],
    };
    _mostrarFormularioProducto(productoMock);
  }

  void _eliminarItem(int i) => setState(() => _carrito.removeAt(i));

  double get _subtotal => _carrito.fold(
      0,
      (sum, item) =>
          sum + (item['cantidad'] as double) * (item['costo'] as double));

  double get _impuestoPct => double.tryParse(_impuestoCtrl.text) ?? 0;

  double get _total => _subtotal * (1 + _impuestoPct / 100);

  Future<void> _guardar() async {
    if (_proveIde == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un proveedor'),
          backgroundColor: AppColors.warning,
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
              'precio1': c['precio1'],
              'precio2': c['precio2'],
              'precio_usd': c['precio_usd'],
            })
        .toList();

    final result = await _compraService.crearCompra(
      usuaIde: widget.user.usuaIde,
      proveIde: _proveIde!,
      fecha: _fechaSql(_fecha),
      documento: _docCtrl.text.trim(),
      impuesto: _impuestoPct,
      observa: _observaCtrl.text.trim(),
      items: items,
    );

    setState(() => _isGuardando = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Compra registrada'),
          backgroundColor: AppColors.success,
        ),
      );
      final compraIde = int.tryParse(result['compra_ide'].toString()) ?? 0;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleCompraScreen(
            user: widget.user,
            compraIde: compraIde,
          ),
        ),
      );
      setState(() {
        _proveIde = null;
        _proveNombre = null;
        _carrito.clear();
        _docCtrl.clear();
        _observaCtrl.clear();
        _impuestoCtrl.text = '0';
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
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fecha ──────────────────────────────────────
            _seccion('FECHA DE COMPRA'),
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

            // ── Proveedor ──────────────────────────────────
            _seccion('PROVEEDOR'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _proveIde,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                labelText: 'Seleccionar proveedor',
                prefixIcon: Icon(Icons.business_outlined, size: 18),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('-- Seleccionar --',
                      style:
                          TextStyle(color: AppColors.textHint, fontSize: 13)),
                ),
                ..._proveedores
                    .map<DropdownMenuItem<int>>((p) => DropdownMenuItem<int>(
                          value: int.tryParse(p['prove_ide'].toString()),
                          child: Text(
                            p['prove_nombre']?.toString() ?? '',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
              ],
              onChanged: (v) {
                setState(() {
                  _proveIde = v;
                  try {
                    final p = _proveedores.firstWhere(
                        (p) => int.tryParse(p['prove_ide'].toString()) == v);
                    _proveNombre = p['prove_nombre']?.toString();
                  } catch (_) {
                    _proveNombre = null;
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // ── Documento ──────────────────────────────────
            _seccion('REFERENCIA'),
            const SizedBox(height: 8),
            TextField(
              controller: _docCtrl,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'N° Factura del proveedor (opcional)',
                prefixIcon: Icon(Icons.receipt_outlined, size: 18),
              ),
            ),

            const SizedBox(height: 16),

            // ── Productos ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _seccion('PRODUCTOS (${_carrito.length})'),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchProdCtrl,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o código...',
                      prefixIcon: Icon(Icons.search, size: 18),
                    ),
                    onSubmitted: (_) => _buscarYAgregarProducto(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _buscarYAgregarProducto,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  child: const Icon(Icons.add, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Carrito ────────────────────────────────────
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
                      Icon(Icons.inventory_2_outlined,
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
                    final costo = item['costo'] as double;
                    final precio1 = item['precio1'] as double;
                    final precio2 = item['precio2'] as double;
                    final precioUsd = item['precio_usd'] as double;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['descripcion'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Resumen de precios
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 2,
                                      children: [
                                        _chipPrecio(
                                            'Cant',
                                            cant.toStringAsFixed(0),
                                            AppColors.info),
                                        _chipPrecio(
                                            'Costo',
                                            FormatoNumero.monedaConSimbolo(
                                                costo),
                                            AppColors.warning),
                                        _chipPrecio(
                                            'P1',
                                            FormatoNumero.monedaConSimbolo(
                                                precio1),
                                            AppColors.primary),
                                        _chipPrecio(
                                            'Bs.',
                                            FormatoNumero.moneda(precio2),
                                            AppColors.purple),
                                        _chipPrecio(
                                            'USD',
                                            '\$${precioUsd.toStringAsFixed(2)}',
                                            AppColors.success),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    FormatoNumero.monedaConSimbolo(
                                        cant * costo),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Editar
                                      GestureDetector(
                                        onTap: () => _editarItem(i),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.edit_outlined,
                                              color: AppColors.info, size: 18),
                                        ),
                                      ),
                                      // Eliminar
                                      GestureDetector(
                                        onTap: () => _eliminarItem(i),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.error,
                                              size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

            const SizedBox(height: 16),

            // ── Impuesto y observaciones ───────────────────
            _seccion('AJUSTES'),
            const SizedBox(height: 8),
            TextField(
              controller: _impuestoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Impuesto %',
                prefixIcon: Icon(Icons.percent, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _observaCtrl,
              maxLines: 2,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                prefixIcon: Icon(Icons.comment_outlined, size: 18),
              ),
            ),

            const SizedBox(height: 16),

            // ── Totales ────────────────────────────────────
            _seccion('TOTALES'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _filaTotal('Subtotal (costo)',
                      FormatoNumero.monedaConSimbolo(_subtotal)),
                  _filaTotal(
                    'Impuesto (${_impuestoPct.toStringAsFixed(0)}%)',
                    '+${FormatoNumero.monedaConSimbolo(_total - _subtotal)}',
                    color: AppColors.info,
                  ),
                  const Divider(color: AppColors.border),
                  _filaTotal(
                    'TOTAL',
                    FormatoNumero.monedaConSimbolo(_total),
                    negrita: true,
                    color: AppColors.primary,
                    grande: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Botón guardar ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGuardando ? null : _guardar,
                icon: _isGuardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(
                  _isGuardando ? 'Registrando...' : 'Registrar Compra',
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

  Widget _chipPrecio(String label, String valor, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label: ',
                style: TextStyle(
                    color: color, fontSize: 9, fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: valor,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

  Widget _filaTotal(String label, String valor,
          {bool negrita = false,
          bool grande = false,
          Color color = AppColors.textPrimary}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: grande ? 14 : 12)),
            Text(valor,
                style: TextStyle(
                  color: color,
                  fontSize: grande ? 16 : 13,
                  fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
                )),
          ],
        ),
      );
}
