import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/permiso_service.dart';
import '../theme/app_theme.dart';

class PermisosScreen extends StatefulWidget {
  final UserModel user;
  const PermisosScreen({super.key, required this.user});

  @override
  State<PermisosScreen> createState() => _PermisosScreenState();
}

class _PermisosScreenState extends State<PermisosScreen>
    with SingleTickerProviderStateMixin {
  final _service = PermisoService();
  late TabController _tabCtrl;

  // Perfiles editables según quién accede
  // tius 1 puede editar 2,3,4,5
  // tius 3 puede editar 2,4,5
  List<Map<String, dynamic>> get _perfiles {
    final todos = [
      {'tius': 2, 'label': 'Asistente', 'icon': Icons.support_agent},
      {'tius': 3, 'label': 'Admin Tienda', 'icon': Icons.store},
      {'tius': 4, 'label': 'Vendedor', 'icon': Icons.point_of_sale},
      {'tius': 5, 'label': 'Vendedor Detal', 'icon': Icons.shopping_bag},
    ];
    if (widget.user.tius == 1) return todos;
    // tius 3 no ve el perfil 3 (no puede editarse a sí mismo ni al 1)
    return todos.where((p) => p['tius'] != 3).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _perfiles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permisos por Perfil'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: _perfiles
              .map((p) => Tab(
                    icon: Icon(p['icon'] as IconData, size: 18),
                    text: p['label'] as String,
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _perfiles
            .map((p) => _PerfilTab(
                  user: widget.user,
                  service: _service,
                  permTius: p['tius'] as int,
                  label: p['label'] as String,
                ))
            .toList(),
      ),
    );
  }
}

// ── Tab de un perfil ───────────────────────────────────────
class _PerfilTab extends StatefulWidget {
  final UserModel user;
  final PermisoService service;
  final int permTius;
  final String label;

  const _PerfilTab({
    required this.user,
    required this.service,
    required this.permTius,
    required this.label,
  });

  @override
  State<_PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<_PerfilTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  List _modulos = [];
  bool _guardando = false;
  String _errorMsg = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    final result = await widget.service.listarPerfil(
      usuaIde: widget.user.usuaIde,
      permTius: widget.permTius,
    );

    if (result['success'] == true) {
      setState(() => _modulos = result['modulos'] ?? []);
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error');
    }

    setState(() => _isLoading = false);
  }

  // Toggle individual — guarda inmediatamente
  Future<void> _togglePermiso(int index, bool value) async {
    setState(() {
      _modulos[index]['perm_estado'] = value ? 1 : 0;
    });

    final result = await widget.service.guardarPermiso(
      usuaIde: widget.user.usuaIde,
      permTius: widget.permTius,
      permSumo: int.tryParse(_modulos[index]['sumo_modu'].toString()) ?? 0,
      permEstado: value ? 1 : 0,
    );

    if (!mounted) return;

    if (result['success'] != true) {
      // Revertir si falló
      setState(() {
        _modulos[index]['perm_estado'] = value ? 0 : 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Activar o desactivar todos
  Future<void> _toggleTodos(bool activar) async {
    setState(() {
      for (var m in _modulos) {
        m['perm_estado'] = activar ? 1 : 0;
      }
      _guardando = true;
    });

    final result = await widget.service.guardarTodos(
      usuaIde: widget.user.usuaIde,
      permTius: widget.permTius,
      permisos: _modulos,
    );

    setState(() => _guardando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  int get _activados => _modulos
      .where((m) => int.tryParse(m['perm_estado'].toString()) == 1)
      .length;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(_errorMsg, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Banner resumen del perfil ──────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          color: AppColors.primaryBg,
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$_activados de '
                      '${_modulos.length} módulos activos',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Barra de progreso circular
              SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value:
                          _modulos.isEmpty ? 0 : _activados / _modulos.length,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                      strokeWidth: 4,
                    ),
                    Text(
                      '$_activados',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Botones activar/desactivar todos ──────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _guardando ? null : () => _toggleTodos(false),
                  icon: const Icon(Icons.toggle_off_outlined, size: 18),
                  label: const Text('Desactivar todo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : () => _toggleTodos(true),
                  icon: const Icon(Icons.toggle_on_outlined, size: 18),
                  label: const Text('Activar todo'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.border),

        // ── Lista de módulos con Switch ────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _modulos.length,
            itemBuilder: (_, i) {
              final m = _modulos[i];
              final activo = int.tryParse(m['perm_estado'].toString()) == 1;
              final sumoModu = int.tryParse(m['sumo_modu'].toString()) ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: activo ? AppColors.surface : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activo
                        ? AppColors.primary.withAlpha(60)
                        : AppColors.border,
                    width: activo ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      // Número del módulo
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: activo
                              ? AppColors.primaryBg
                              : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$sumoModu',
                            style: TextStyle(
                              color: activo
                                  ? AppColors.primary
                                  : AppColors.textHint,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Nombre del módulo
                      Expanded(
                        child: Text(
                          m['sumo_descrip']?.toString() ?? '',
                          style: TextStyle(
                            color: activo
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            fontWeight:
                                activo ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      // Estado badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              activo ? AppColors.successBg : AppColors.errorBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          activo ? 'ON' : 'OFF',
                          style: TextStyle(
                            color: activo ? AppColors.success : AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Switch
                      Switch(
                        value: activo,
                        activeColor: AppColors.primary,
                        onChanged:
                            _guardando ? null : (v) => _togglePermiso(i, v),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Loading overlay al guardar todos
        if (_guardando)
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surface,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Guardando permisos...',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }
}
