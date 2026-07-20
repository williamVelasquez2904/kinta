import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'nuevo_ajuste_screen.dart';
import 'lista_ajustes_screen.dart';

class AjustesScreen extends StatefulWidget {
  final UserModel user;
  const AjustesScreen({super.key, required this.user});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen>
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
    if (!widget.user.esAdministrador) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ajustes de Inventario')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: AppColors.error, size: 52),
              SizedBox(height: 12),
              Text('Solo administradores pueden acceder',
                  style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de Inventario'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(icon: Icon(Icons.remove_circle_outline), text: 'Nueva Baja'),
            Tab(icon: Icon(Icons.list_alt), text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NuevoAjusteScreen(user: widget.user),
          ListaAjustesScreen(user: widget.user),
        ],
      ),
    );
  }
}
