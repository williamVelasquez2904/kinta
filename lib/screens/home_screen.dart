import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_info.dart';
import 'login_screen.dart';
//import 'mis_clientes_screen.dart';
//import 'creditos_screen.dart';
//import 'saldos_screen.dart';
//#import 'saldos_ventas_screen.dart';
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

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Map<String, dynamic>> _menuOpciones = [
    /*
    {
      'icon': Icons.people_alt_outlined,
      'label': 'Mis Clientes',
      'color': AppColors.misClientes,
      'colorBg': AppColors.misClientesBg,
      'screen': MisClientesScreen(user: widget.user),
    },*/
    /*
    {
      'icon': Icons.hourglass_empty,
      'label': 'Créditos Vencidos',
      'color': AppColors.creditosVencidos,
      'colorBg': AppColors.creditosBg,
      'screen': const CreditosScreen(),
    },*/
    /*
    {
      'icon': Icons.balance,
      'label': 'Saldos',
      'color': AppColors.saldos,
      'colorBg': AppColors.saldosBg,
      'screen': const SaldosScreen(),
    }, */
    /*
    {
      'icon': Icons.trending_up,
      'label': 'Saldos en Ventas',
      'color': AppColors.saldosVentas,
      'colorBg': AppColors.saldosVentasBg,
      'screen': const SaldosVentasScreen(),
    },*/
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
    if (widget.user.esAdministrador) ...[
      {
        'icon': Icons.business_outlined,
        'label': 'Proveedores',
        'color': AppColors.purple,
        'colorBg': AppColors.purpleBg,
        'screen': ProveedoresScreen(user: widget.user),
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'label': 'Compras',
        'color': AppColors.warning,
        'colorBg': AppColors.warningBg,
        'screen': ComprasScreen(user: widget.user),
      },
    ],
    if (widget.user.accesoVentas)
      {
        'icon': Icons.point_of_sale,
        'label': 'Ventas',
        'color': AppColors.info,
        'colorBg': AppColors.infoBg,
        'screen': VentasScreen(user: widget.user),
      },
    {
      'icon': Icons.bar_chart,
      'label': 'Reporte Ventas',
      'color': AppColors.info,
      'colorBg': AppColors.infoBg,
      'screen': ReporteVentasScreen(user: widget.user),
    },

    //
    {
      'icon': Icons.query_stats,
      'label': 'Ventas por Producto',
      'color': AppColors.info,
      'colorBg': AppColors.infoBg,
      'screen': ReporteProductoScreen(user: widget.user),
    },

    //
    if (widget.user.accesoInventario)
      {
        'icon': Icons.warehouse_outlined,
        'label': 'Reporte Inventario',
        'color': AppColors.purple,
        'colorBg': AppColors.purpleBg,
        'screen': ReporteInventarioScreen(user: widget.user),
      },
    if (widget.user.esAdministrador)
      {
        'icon': Icons.auto_graph,
        'label': 'Gráfica Productos',
        'color': AppColors.success,
        'colorBg': AppColors.successBg,
        'screen': GraficaProductosScreen(user: widget.user),
      },

    if (widget.user.esAdministrador)
      {
        'icon': Icons.remove_circle_outline,
        'label': 'Ajuste Inventario',
        'color': AppColors.error,
        'colorBg': AppColors.errorBg,
        'screen': AjustesScreen(user: widget.user),
      },
    {
      'icon': Icons.smart_toy_outlined,
      'label': 'Asistente Kin',
      'color': AppColors.primary,
      'colorBg': AppColors.primaryBg,
      'screen': AsistenteScreen(user: widget.user),
    },

    if (widget.user.tius == 1)
      {
        'icon': Icons.settings_outlined,
        'label': 'Configuración',
        'color': AppColors.textSecondary,
        'colorBg': AppColors.surfaceAlt,
        'screen': ConfiguracionScreen(user: widget.user),
      },
  ];

  void _navegarA(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
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

                  ..._menuOpciones.map((item) => ListTile(
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
      body: SingleChildScrollView(
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

            // Grid de opciones — responsive
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnas,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 110, // altura fija
                    ),
                    itemCount: _menuOpciones.length,
                    itemBuilder: (context, index) {
                      final item = _menuOpciones[index];
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
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
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
}

// ── Widget tarjeta menú ───────────────────────────────────────
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
