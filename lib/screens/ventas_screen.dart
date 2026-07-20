import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'nueva_venta_screen.dart';
import 'mis_ventas_screen.dart';

class VentasScreen extends StatefulWidget {
  final UserModel user;
  const VentasScreen({super.key, required this.user});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Validación de acceso (solo tius 3 o 5) ──────────────
    if (!widget.user.accesoVentas) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ventas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppColors.error,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Acceso restringido',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No tienes permisos para acceder a este módulo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(icon: Icon(Icons.add_shopping_cart), text: 'Nueva Venta'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Mis Ventas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NuevaVentaScreen(user: widget.user),
          MisVentasScreen(user: widget.user),
        ],
      ),
    );
  }
}
