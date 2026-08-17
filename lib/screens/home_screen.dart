import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/permiso_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_info.dart';
import 'login_screen.dart';
import 'clientes_screen.dart';
import 'asistente_screen.dart';
import 'ventas_screen.dart';
import 'productos_screen.dart';
import 'reporte_ventas_screen.dart';
import 'reporte_inventario_screen.dart';
import 'reporte_producto_screen.dart';
import 'grafica_productos_screen.dart';
import 'compras_screen.dart';
import 'proveedores_screen.dart';
import 'ajustes_screen.dart';
import 'configuracion_screen.dart';
import 'auditoria_screen.dart';
import 'cuentas_cobrar_screen.dart';
import 'cambiar_clave_screen.dart';
import 'mantenimiento_screen.dart';
import 'carga_masiva_productos_screen.dart';
import 'actualizacion_masiva_screen.dart';
import 'usuarios_screen.dart';
import 'permisos_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _permisoService = PermisoService();
  List<String> _modulosPermitidos = [];
  bool _permisosListos = false;

  List<Map<String, dynamic>> get _menuOpciones {
    final items = <Map<String, dynamic>>[
      {
        'icon': Icons.person_search,
        'label': 'Clientes',
        'color': AppColors.clientes,
        'colorBg': AppColors.clientesBg,
        'screen': ClientesScreen(user: widget.user),
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Productos',
        'color': AppColors.purple,
        'colorBg': AppColors.purpleBg,
        'screen': ProductosScreen(user: widget.user),
      },
    ];

    // La opción 'Proveedores' se incluye por defecto y será filtrada
    // por los permisos de sesión. Antes estaba solo para administradores,
    // lo que impedía que usuarios con permiso (tius = 2) la vieran.
    items.add({
      'icon': Icons.business_outlined,
      'label': 'Proveedores',
      'color': AppColors.purple,
      'colorBg': AppColors.purpleBg,
      'screen': ProveedoresScreen(user: widget.user),
    });

    // Incluir 'Compras' por defecto y permitir que el filtro de permisos
    // decida si se muestra en la sesión actual (igual que Proveedores).
    items.add({
      'icon': Icons.shopping_bag_outlined,
      'label': 'Compras',
      'color': AppColors.warning,
      'colorBg': AppColors.warningBg,
      'screen': ComprasScreen(user: widget.user),
    });

    if (widget.user.accesoVentas) {
      items.add({
        'icon': Icons.point_of_sale,
        'label': 'Notas de Entrega',
        'color': AppColors.info,
        'colorBg': AppColors.infoBg,
        'screen': VentasScreen(user: widget.user),
      });
    }

    items.addAll([
      {
        'icon': Icons.bar_chart,
        'label': 'Reporte Notas de Entrega',
        'color': AppColors.info,
        'colorBg': AppColors.infoBg,
        'screen': ReporteVentasScreen(user: widget.user),
      },
      {
        'icon': Icons.query_stats,
        'label': 'Notas por Producto',
        'color': AppColors.info,
        'colorBg': AppColors.infoBg,
        'screen': ReporteProductoScreen(user: widget.user),
      },
    ]);

    // El módulo 'Reporte Inventario' se añade por defecto y queda sujeto
    // al filtrado por permisos de sesión. Antes estaba restringido a
    // administradores únicamente (via `accesoInventario`), lo que impedía
    // que perfiles con permiso explicito lo vieran.
    items.add({
      'icon': Icons.warehouse_outlined,
      'label': 'Reporte Inventario',
      'color': AppColors.purple,
      'colorBg': AppColors.purpleBg,
      'screen': ReporteInventarioScreen(user: widget.user),
    });

    // Incluir 'Gráfica Productos' en la lista general; el filtrado por
    // permisos decidirá si se muestra en la sesión actual.
    items.add({
      'icon': Icons.auto_graph,
      'label': 'Gráfica Productos',
      'color': AppColors.success,
      'colorBg': AppColors.successBg,
      'screen': GraficaProductosScreen(user: widget.user),
    });

    items.add({
      'icon': Icons.account_balance_wallet,
      'label': 'Cuentas x Cobrar',
      'color': AppColors.error,
      'colorBg': AppColors.errorBg,
      'screen': CuentasCobrarScreen(user: widget.user),
    });

    // Añadir 'Ajuste Inventario' a la lista general; el filtrado por permisos
    // decide si se muestra en la sesión actual.
    items.add({
      'icon': Icons.remove_circle_outline,
      'label': 'Ajuste Inventario',
      'color': AppColors.error,
      'colorBg': AppColors.errorBg,
      'screen': AjustesScreen(user: widget.user),
    });

    items.add({
      'icon': Icons.smart_toy_outlined,
      'label': 'Asistente Kin',
      'color': AppColors.primary,
      'colorBg': AppColors.primaryBg,
      'screen': AsistenteScreen(user: widget.user),
    });

    // Incluir 'Actualiz. Masiva' en la lista general; su visibilidad
    // será controlada por los permisos de sesión.
    items.add({
      'icon': Icons.table_chart_outlined,
      'label': 'Actualiz. Masiva',
      'color': AppColors.info,
      'colorBg': AppColors.infoBg,
      'screen': ActualizacionMasivaScreen(user: widget.user),
    });

    // Incluir 'Carga Masiva Productos' en la lista general; filtrado
    // por permisos decidirá su visibilidad.
    items.add({
      'icon': Icons.upload_file_outlined,
      'label': 'Carga Masiva Productos',
      'color': AppColors.success,
      'colorBg': AppColors.successBg,
      'screen': CargaMasivaProductosScreen(user: widget.user),
    });

    // Añadir 'Mantenimiento' a la lista general; será mostrado según permisos.
    items.add({
      'icon': Icons.build_outlined,
      'label': 'Mantenimiento',
      'color': AppColors.purple,
      'colorBg': AppColors.purpleBg,
      'screen': MantenimientoScreen(user: widget.user),
    });

    if (widget.user.tius == 1) {
      items.add({
        'icon': Icons.history,
        'label': 'Auditoría',
        'color': AppColors.purple,
        'colorBg': AppColors.purpleBg,
        'screen': AuditoriaScreen(user: widget.user),
      });
    }

    if (widget.user.esAdministrador) {
      items.addAll([
        {
          'icon': Icons.manage_accounts_outlined,
          'label': 'Usuarios',
          'color': AppColors.purple,
          'colorBg': AppColors.purpleBg,
          'screen': UsuariosScreen(user: widget.user),
        },
      ]);
    }

    // 'Permisos' solo para superusuario (tius == 1)
    if (widget.user.tius == 1) {
      items.add({
        'icon': Icons.admin_panel_settings_outlined,
        'label': 'Permisos',
        'color': const Color(0xFF6366F1),
        'colorBg': const Color(0xFFF0F0FF),
        'screen': PermisosScreen(user: widget.user),
      });
    }

    if (widget.user.tius == 1) {
      items.add({
        'icon': Icons.settings_outlined,
        'label': 'Configuración',
        'color': AppColors.textSecondary,
        'colorBg': AppColors.surfaceAlt,
        'screen': ConfiguracionScreen(user: widget.user),
      });
    }

    return items;
  }

  List<Map<String, dynamic>> get _opcionesFiltradas {
    if (!_permisosListos) return [];
    if (_modulosPermitidos.isEmpty) return _menuOpciones;

    final permisosNormalizados =
        _modulosPermitidos.map((p) => _normalizarModulo(p)).toSet();

    debugPrint('PERMISOS NORMALIZADOS: $permisosNormalizados');

    return _menuOpciones.where((item) {
      final label = item['label'] as String;
      final sinFiltro = ['Auditoría', 'Configuración'];
      if (sinFiltro.contains(label)) return true;
      final labelNormalizado = _normalizarModulo(label);
      return permisosNormalizados.contains(labelNormalizado);
    }).toList();
  }

  String _normalizarModulo(String valor) {
    final texto = valor
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .trim();

    final sinSeparadores = texto
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final alias = {
      'reporte ventas': 'reporte notas de entrega',
      'ventas': 'notas de entrega',
      'reporte notas de entrega': 'reporte notas de entrega',
      'reporte notas': 'reporte notas de entrega',
      'notas de entrega': 'notas de entrega',
      'reporte inventario': 'reporte inventario',
      'notas por producto': 'notas por producto',
      'grafica productos': 'grafica productos',
    };

    return alias[sinSeparadores] ?? sinSeparadores;
  }

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  Future<void> _cargarPermisos() async {
    final result = await _permisoService.misPermisos(widget.user.usuaIde);
    debugPrint('RESULTADO misPermisos: $result');
    if (!mounted) return;

    if (result['success'] == true) {
      final permisos = result['permisos'] as List? ?? [];
      final lista = permisos
          .map((p) => p['sumo_descrip']?.toString().trim() ?? '')
          .where((p) => p.isNotEmpty)
          .toList();

      debugPrint('PERMISOS BRUTOS: $lista');
      debugPrint(
          'PERMISOS NORMALIZADOS (antes de setState): ${lista.map((p) => _normalizarModulo(p)).toList()}');
      debugPrint(
          '¿Tiene Proveedores? => ${lista.any((p) => _normalizarModulo(p) == 'proveedores' || _normalizarModulo(p) == 'proveedores')}');
      debugPrint(
          '¿Tiene Compras? => ${lista.any((p) => _normalizarModulo(p) == 'compras')}');
      debugPrint(
          '¿Tiene Reporte Notas de Entrega? => ${lista.any((p) => _normalizarModulo(p) == 'reporte notas de entrega')}');
      debugPrint(
          '¿Tiene Reporte Inventario? => ${lista.any((p) => _normalizarModulo(p) == 'reporte inventario')}');
      debugPrint(
          '¿Tiene Grafica Productos? => ${lista.any((p) => _normalizarModulo(p) == 'grafica productos')}');

      setState(() {
        _modulosPermitidos = lista;
        _permisosListos = true;
      });
    } else {
      setState(() => _permisosListos = true);
    }
  }

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
      backgroundColor: AppColors.background,

      // ── FAB — Asistente ────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarA(AsistenteScreen(user: widget.user)),
        backgroundColor: AppColors.primary,
        tooltip: 'Asistente Kin',
        child: const Icon(Icons.eco, color: Colors.white),
      ),

      // ── AppBar ─────────────────────────────────────────────
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.eco,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(AppInfo.nombre),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'Asistente Kin',
            onPressed: () => _navegarA(AsistenteScreen(user: widget.user)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),

      // ── Drawer ─────────────────────────────────────────────
      drawer: Drawer(
        child: Column(
          children: [
            // Nombre de la app
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.only(top: 12, left: 16),
              child: Row(
                children: [
                  const Icon(Icons.eco, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    AppInfo.nombre,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Header usuario
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.user.nombre.isNotEmpty
                          ? widget.user.nombre[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.user.nombreCompleto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Debug: imprimir descripción de tipo de usuario
                  // (se puede quitar después de comprobar)
                  Builder(builder: (_) {
                    debugPrint(
                        'DEBUG tipoUsuarioDescripcion: ${widget.user.tipoUsuarioDescripcion}');
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.tipoUsuarioDescripcion,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.user.login,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Opciones
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Text(
                      'MÓDULOS',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  if (!_permisosListos)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else
                    ...opciones.map((item) => ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item['colorBg'],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item['icon'],
                              color: item['color'],
                              size: 18,
                            ),
                          ),
                          title: Text(
                            item['label'],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _navegarA(item['screen']);
                          },
                        )),

                  const Divider(height: 24),

                  // Cerrar sesión
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                    title: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await AuthService().logout();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Footer versión
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${AppInfo.nombre} © ${DateTime.now().year}',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppInfo.versionCompleta,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Body ───────────────────────────────────────────────
      body: _selectedIndex == 1
          ? _buildPerfil()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner bienvenida
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenido,',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.user.nombreCompleto,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '¿Qué te gustaría hacer hoy?',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Título menú
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Menú de opciones',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (!_permisosListos)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final ancho = constraints.maxWidth;
                          final columnas = ancho > 900
                              ? 6
                              : ancho > 600
                                  ? 4
                                  : 3;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columnas,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              mainAxisExtent: 110,
                            ),
                            itemCount: opciones.length,
                            itemBuilder: (context, index) {
                              final item = opciones[index];
                              return _MenuCard(
                                icon: item['icon'],
                                label: item['label'],
                                color: item['color'],
                                colorBg: item['colorBg'],
                                onTap: () => _navegarA(item['screen']),
                              );
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),

      // ── Footer ─────────────────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryBg,
        elevation: 1,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildPerfil() {
    final opcionesPermitidas = _opcionesFiltradas;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 40,
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
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 13,
                  ),
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
                    widget.user.tipoUsuarioDescripcion,
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
          _perfilSeccion('INFORMACIÓN'),
          const SizedBox(height: 8),
          _perfilBloque([
            _perfilFila(
              Icons.badge_outlined,
              'Cédula',
              widget.user.numiden.isNotEmpty ? widget.user.numiden : '-',
            ),
            _perfilFila(
              Icons.admin_panel_settings_outlined,
              'Nivel',
              '${widget.user.tius} — ${widget.user.tipoUsuarioDescripcion}',
            ),
          ]),
          const SizedBox(height: 20),
          _perfilSeccion('MÓDULOS HABILITADOS (${opcionesPermitidas.length})'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: _permisosListos
                ? (opcionesPermitidas.isEmpty
                    ? const Text(
                        'No hay módulos asignados para esta sesión.',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: opcionesPermitidas.map((op) {
                          final color = op['color'] as Color;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color.withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(op['icon'] as IconData,
                                    color: color, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  op['label'] as String,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ))
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          _perfilSeccion('ACCIONES'),
          const SizedBox(height: 8),
          _perfilAction(
            icon: Icons.lock_reset,
            label: 'Cambiar mi clave',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CambiarClaveScreen(user: widget.user),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _perfilAction(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            color: AppColors.error,
            onTap: () async {
              await AuthService().logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              AppInfo.versionCompleta,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _perfilSeccion(String title) => Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );

  Widget _perfilBloque(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );

  Widget _perfilFila(IconData icon, String label, String value) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textHint, size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 42),
        ],
      );

  Widget _perfilAction({
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
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    color: color.withAlpha(120), size: 20),
              ],
            ),
          ),
        ),
      );
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color colorBg;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.colorBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
