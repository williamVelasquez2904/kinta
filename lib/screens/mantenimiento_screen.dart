import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/mantenimiento_service.dart';
import '../theme/app_theme.dart';

class MantenimientoScreen extends StatefulWidget {
  final UserModel user;
  const MantenimientoScreen({super.key, required this.user});

  @override
  State<MantenimientoScreen> createState() => _MantenimientoScreenState();
}

class _MantenimientoScreenState extends State<MantenimientoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final List<Map<String, String>> _tablas = [
    {
      'key': 'departamento',
      'label': 'Departamentos',
      'icon': 'category',
    },
    {
      'key': 'marca',
      'label': 'Marcas',
      'icon': 'sell',
    },
    {
      'key': 'modelo',
      'label': 'Modelos',
      'icon': 'widgets',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tablas.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  IconData _iconTabla(String icon) {
    switch (icon) {
      case 'category':
        return Icons.category_outlined;
      case 'sell':
        return Icons.sell_outlined;
      case 'widgets':
        return Icons.widgets_outlined;
      default:
        return Icons.list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mantenimiento'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: _tablas
              .map((t) => Tab(
                    icon: Icon(_iconTabla(t['icon']!), size: 18),
                    text: t['label'],
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _tablas
            .map((t) => _TablaView(
                  user: widget.user,
                  tabla: t['key']!,
                  label: t['label']!,
                ))
            .toList(),
      ),
    );
  }
}

// ── Vista CRUD de una tabla ────────────────────────────────
class _TablaView extends StatefulWidget {
  final UserModel user;
  final String tabla;
  final String label;

  const _TablaView({
    required this.user,
    required this.tabla,
    required this.label,
  });

  @override
  State<_TablaView> createState() => _TablaViewState();
}

class _TablaViewState extends State<_TablaView>
    with AutomaticKeepAliveClientMixin {
  final _service = MantenimientoService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List _registros = [];
  String _errorMsg = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar([String busqueda = '']) async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    final result = await _service.listar(
      usuaIde: widget.user.usuaIde,
      tabla: widget.tabla,
      busqueda: busqueda,
    );
    if (result['success'] == true) {
      setState(() => _registros = result['registros'] ?? []);
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error');
    }
    setState(() => _isLoading = false);
  }

  // ── Diálogo crear / editar ───────────────────────────
  Future<void> _mostrarDialogo({
    int? ide,
    String descripcionInicial = '',
  }) async {
    final ctrl = TextEditingController(text: descripcionInicial);
    final esEdicion = ide != null;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              esEdicion ? Icons.edit_outlined : Icons.add_circle_outline,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              esEdicion
                  ? 'Editar ${widget.label.replaceAll('s', '').trim()}'
                  : 'Nuevo ${widget.label.replaceAll('s', '').trim()}',
              style: const TextStyle(color: AppColors.primary, fontSize: 15),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Descripción *',
            prefixIcon: const Icon(Icons.description_outlined, size: 18),
            hintText: 'Ingresa el nombre del ${widget.label.toLowerCase()}',
          ),
          onSubmitted: (_) async {
            await _guardar(ctrl, esEdicion, ide);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: Icon(esEdicion ? Icons.save : Icons.add, size: 16),
            label: Text(esEdicion ? 'Guardar' : 'Crear'),
            onPressed: () async {
              await _guardar(ctrl, esEdicion, ide);
            },
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _guardar(
    TextEditingController ctrl,
    bool esEdicion,
    int? ide,
  ) async {
    final desc = ctrl.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La descripción es requerida'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.pop(context);

    Map<String, dynamic> result;
    if (esEdicion) {
      result = await _service.editar(
        usuaIde: widget.user.usuaIde,
        tabla: widget.tabla,
        ide: ide!,
        descripcion: desc,
      );
    } else {
      result = await _service.crear(
        usuaIde: widget.user.usuaIde,
        tabla: widget.tabla,
        descripcion: desc,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );
      if (result['success'] == true) {
        _cargar(_searchCtrl.text);
      }
    }
  }

  Future<void> _confirmarEliminar(Map reg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Eliminar'),
          ],
        ),
        content: Text('¿Eliminar "${reg['descripcion']}"?\n\n'
            'No se puede eliminar si está en uso '
            'en algún producto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final ide = int.tryParse(reg['ide'].toString()) ?? 0;
      final result = await _service.eliminar(
        usuaIde: widget.user.usuaIde,
        tabla: widget.tabla,
        ide: ide,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? ''),
            backgroundColor:
                result['success'] == true ? AppColors.success : AppColors.error,
          ),
        );
        if (result['success'] == true) {
          _cargar(_searchCtrl.text);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // ── Buscador ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _cargar,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Buscar ${widget.label.toLowerCase()}...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _cargar();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Botón añadir
              GestureDetector(
                onTap: () => _mostrarDialogo(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Contador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${_registros.length} ${widget.label.toLowerCase()}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),

        // ── Lista ──────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMsg.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text(_errorMsg,
                              style: const TextStyle(color: AppColors.error)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _cargar,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _registros.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inbox_outlined,
                                  color: AppColors.textHint, size: 52),
                              const SizedBox(height: 12),
                              Text(
                                'No hay ${widget.label.toLowerCase()}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _mostrarDialogo(),
                                icon: const Icon(Icons.add),
                                label: Text(
                                    'Agregar ${widget.label.replaceAll('s', '').trim()}'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _registros.length,
                          itemBuilder: (_, i) {
                            final r = _registros[i];
                            final ide = int.tryParse(r['ide'].toString()) ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Stack(
                                children: [
                                  // Área principal
                                  Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => _mostrarDialogo(
                                        ide: ide,
                                        descripcionInicial:
                                            r['descripcion']?.toString() ?? '',
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            // ID badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryBg,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '#$ide',
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                r['descripcion']?.toString() ??
                                                    '',
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            // Espacio botones
                                            const SizedBox(width: 72),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Botones editar / eliminar
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Editar
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            onTap: () => _mostrarDialogo(
                                              ide: ide,
                                              descripcionInicial:
                                                  r['descripcion']
                                                          ?.toString() ??
                                                      '',
                                            ),
                                            child: Container(
                                              width: 36,
                                              height: double.infinity,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.edit_outlined,
                                                color: AppColors.info,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Eliminar
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            onTap: () => _confirmarEliminar(r),
                                            child: Container(
                                              width: 36,
                                              height: double.infinity,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.error,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
