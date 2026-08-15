import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/permiso_service.dart';
//import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_info.dart';
import 'clientes_screen.dart';
import 'productos_screen.dart';
import 'proveedores_screen.dart';
import 'compras_screen.dart';
import 'ventas_screen.dart';
import 'reporte_ventas_screen.dart';
import 'reporte_producto_screen.dart';
import 'reporte_inventario_screen.dart';
import 'grafica_productos_screen.dart';
import 'cuentas_cobrar_screen.dart';
import 'ajustes_screen.dart';
import 'asistente_screen.dart';
import 'mantenimiento_screen.dart';
import 'actualizacion_masiva_screen.dart';
import 'usuarios_screen.dart';
import 'auditoria_screen.dart';
import 'configuracion_screen.dart';
//import 'sincronizacion_screen.dart';
import 'permisos_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _permisoService = PermisoService();

  List<String> _modulosPermitidos = [];
  bool _permisosListos = false;
  int _tabIndex = 0;

  // ── Todas las opciones del menú ──────────────────────────
  List<Map<String, dynamic>> get _todasOpciones {
    final bool esAdmin = widget.user.esAdministrador;
    final bool esTius1 = widget.user.tius == 1;

    return [
      // ── Siempre visibles según permiso ───────────────────
      {
        'label': 'Clientes',
        'icon': Icons.people_outline,
        'color': const Color(0xFF5B8CFF),
        'bg': const Color(0xFFEEF2FF),
        'screen': ClientesScreen(user: widget.user),
      },
      {
        'label': 'Productos',
        'icon': Icons.inventory_2_outlined,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFECFDF5),
        'screen': ProductosScreen(user: widget.user),
      },
      {
        'label': 'Proveedores',
        'icon': Icons.business_outlined,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'screen': ProveedoresScreen(user: widget.user),
      },
      {
        'label': 'Compras',
        'icon': Icons.shopping_bag_outlined,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'screen': ComprasScreen(user: widget.user),
      },
      {
        'label': 'Notas de Entrega',
        'icon': Icons.receipt_outlined,
        'color': AppColors.primary,
        'bg': AppColors.primaryBg,
        'screen': VentasScreen(user: widget.user),
      },
      {
        'label': 'Reporte Notas',
        'icon': Icons.bar_chart_outlined,
        'color': const Color(0xFF0EA5E9),
        'bg': const Color(0xFFEFF6FF),
        'screen': ReporteVentasScreen(user: widget.user),
      },
      {
        'label': 'Notas por Producto',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFFEC4899),
        'bg': const Color(0xFFFDF2F8),
        'screen': ReporteProductoScreen(user: widget.user),
      },
      {
        'label': 'Reporte Inventario',
        'icon': Icons.warehouse_outlined,
        'color': const Color(0xFF6366F1),
        'bg': const Color(0xFFF0F0FF),
        'screen': ReporteInventarioScreen(user: widget.user),
      },
      {
        'label': 'Gráfica Productos',
        'icon': Icons.insert_chart_outlined,
        'color': const Color(0xFF14B8A6),
        'bg': const Color(0xFFEFFEFD),
        'screen': GraficaProductosScreen(user: widget.user),
      },
      {
        'label': 'Cuentas x Cobrar',
        'icon': Icons.account_balance_wallet_outlined,
        'color': const Color(0xFFEF4444),
        'bg': const Color(0xFFFFF1F2),
        'screen': CuentasCobrarScreen(user: widget.user),
      },
      {
        'label': 'Ajuste Inventario',
        'icon': Icons.tune_outlined,
        'color': const Color(0xFFF97316),
        'bg': const Color(0xFFFFF7ED),
        'screen': AjustesScreen(user: widget.user),
      },
      {
        'label': 'Asistente Kinta',
        'icon': Icons.smart_toy_outlined,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFECFDF5),
        'screen': AsistenteScreen(user: widget.user),
      },

      /*
      {
        'label': 'Sincronización',
        'icon': Icons.sync_outlined,
        'color': const Color(0xFF0EA5E9),
        'bg': const Color(0xFFEFF6FF),
        'screen': SincronizacionScreen(user: widget.user),
      },*/

      // ── Solo admin (tius 1 y 3) ──────────────────────────
      if (esAdmin) ...[
        {
          'label': 'Mantenimiento',
          'icon': Icons.build_outlined,
          'color': const Color(0xFF8B5CF6),
          'bg': const Color(0xFFF5F3FF),
          'screen': MantenimientoScreen(user: widget.user),
        },
        {
          'label': 'Actualiz. Masiva',
          'icon': Icons.table_chart_outlined,
          'color': const Color(0xFF0EA5E9),
          'bg': const Color(0xFFEFF6FF),
          'screen': ActualizacionMasivaScreen(user: widget.user),
        },
        {
          'label': 'Usuarios',
          'icon': Icons.manage_accounts_outlined,
          'color': const Color(0xFF8B5CF6),
          'bg': const Color(0xFFF5F3FF),
          'screen': UsuariosScreen(user: widget.user),
        },
        {
          'label': 'Permisos',
          'icon': Icons.admin_panel_settings_outlined,
          'color': const Color(0xFF6366F1),
          'bg': const Color(0xFFF0F0FF),
          'screen': PermisosScreen(user: widget.user),
        },
      ],

      // ── Solo tius 1 ──────────────────────────────────────
      if (esTius1) ...[
        {
          'label': 'Auditoría',
          'icon': Icons.history_outlined,
          'color': const Color(0xFFEF4444),
          'bg': const Color(0xFFFFF1F2),
          'screen': AuditoriaScreen(user: widget.user),
        },
        {
          'label': 'Configuración',
          'icon': Icons.settings_outlined,
          'color': const Color(0xFF6B7280),
          'bg': const Color(0xFFF9FAFB),
          'screen': ConfiguracionScreen(user: widget.user),
        },
      ],
    ];
  }

  // ── Filtrar según permisos cargados ─────────────────────
  List<Map<String, dynamic>> get _opcionesFiltradas {
    if (!_permisosListos) return [];
    if (_modulosPermitidos.isEmpty) return _todasOpciones;

    return _todasOpciones.where((op) {
      final label = op['label'] as String;
      // Opciones de admin (Permisos, Auditoría, Config)
      // siempre visibles si el usuario tiene el nivel
      final sinFiltro = ['Permisos', 'Auditoría', 'Configuración'];
      if (sinFiltro.contains(label)) return true;
      return _modulosPermitidos.contains(label);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
    //_iniciarSyncAutomatico();
  }

  Future<void> _cargarPermisos() async {
    final result = await _permisoService.misPermisos(widget.user.usuaIde);
    if (mounted) {
      if (result['success'] == true) {
        final permisos = result['permisos'] as List? ?? [];
        setState(() {
          _modulosPermitidos =
              permisos.map((p) => p['sumo_descrip'].toString()).toList();
          _permisosListos = true;
        });
      } else {
        // Falla silenciosa → mostrar todo
        setState(() => _permisosListos = true);
      }
    }
  }
  /*
  void _iniciarSyncAutomatico() {
    SyncService().estadoConexion.listen((online) {
      if (online) {
        debugPrint('Conexión detectada — sincronizando...');
        SyncService().sincronizarPendientes().then((r) {
          debugPrint('AutoSync: ${r.mensaje}');
        });
      }
    });
  } */

  void _navegarA(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opciones = _opcionesFiltradas;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.eco,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
        title: Text(
          AppInfo.nombre,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textHint),
            onPressed: () {},
          ),
        ],
      ),
      body: _tabIndex == 0 ? _buildInicio(opciones) : _buildPerfil(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        mini: true,
        onPressed: () => _navegarA(AsistenteScreen(user: widget.user)),
        child:
            const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
      ),
    );
  }

  // ── Tab Inicio ───────────────────────────────────────────
  Widget _buildInicio(List<Map<String, dynamic>> opciones) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner bienvenida ──────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bienvenido,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        widget.user.nombreCompleto.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '¿Qué te gustaría hacer hoy?',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),

          // ── Menú de opciones ───────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Menú de opciones',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // Loading de permisos
          if (!_permisosListos)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text('Cargando módulos...',
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: opciones.length,
                itemBuilder: (_, i) {
                  final op = opciones[i];
                  return _tarjetaModulo(
                    label: op['label'] as String,
                    icon: op['icon'] as IconData,
                    color: op['color'] as Color,
                    bg: op['bg'] as Color,
                    screen: op['screen'] as Widget,
                  );
                },
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _tarjetaModulo({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required Widget screen,
  }) =>
      Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navegarA(screen),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // ── Tab Perfil ───────────────────────────────────────────
  Widget _buildPerfil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar y nombre
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.user.nombreCompleto,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  '@${widget.user.login}',
                  style:
                      const TextStyle(color: AppColors.textHint, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    _labelTius(widget.user.tius),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Datos del perfil
          _seccionPerfil('INFORMACIÓN'),
          const SizedBox(height: 8),
          _bloqueInfo([
            _filaInfo(
                Icons.badge_outlined, 'Cédula', widget.user.numiden ?? '-'),
            _filaInfo(Icons.admin_panel_settings_outlined, 'Nivel',
                '${widget.user.tius} — ${_labelTius(widget.user.tius)}'),
          ]),

          const SizedBox(height: 20),

          // Módulos habilitados
          _seccionPerfil('MÓDULOS HABILITADOS'
              ' (${_opcionesFiltradas.length})'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _opcionesFiltradas.map((op) {
                final color = op['color'] as Color;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(op['icon'] as IconData, color: color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        op['label'] as String,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Acciones
          _seccionPerfil('ACCIONES'),
          const SizedBox(height: 8),

          // Cambiar clave
          _botonPerfil(
            icon: Icons.lock_reset,
            label: 'Cambiar mi clave',
            color: AppColors.primary,
            onTap: () {
              // Navegar a cambiar clave
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (_) => CambiarClaveScreen(
              //       user: widget.user)));
            },
          ),

          const SizedBox(height: 10),

          // Cerrar sesión
          _botonPerfil(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            color: AppColors.error,
            onTap: _confirmarLogout,
          ),

          const SizedBox(height: 20),

          // Versión
          Center(
            child: Text(
              AppInfo.versionCompleta,
              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _confirmarLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  // ── Widgets auxiliares ─────────────────────────────────

  Widget _seccionPerfil(String t) => Text(t,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ));

  Widget _bloqueInfo(List<Widget> hijos) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: hijos),
      );

  Widget _filaInfo(IconData i, String label, String valor) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(i, color: AppColors.textHint, size: 18),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const Spacer(),
                Text(valor,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    )),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 42),
        ],
      );

  Widget _botonPerfil({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                const Spacer(),
                Icon(Icons.chevron_right,
                    color: color.withAlpha(120), size: 20),
              ],
            ),
          ),
        ),
      );

  String _labelTius(int t) {
    switch (t) {
      case 1:
        return 'Administrador del Sistema';
      case 2:
        return 'Asistente';
      case 3:
        return 'Administrador de Tienda';
      case 4:
        return 'Vendedor';
      case 5:
        return 'Vendedor Detal';
      default:
        return 'Desconocido';
    }
  }
}
