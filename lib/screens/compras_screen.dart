import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'nueva_compra_screen.dart';
import 'lista_compras_screen.dart';

class ComprasScreen extends StatefulWidget {
  final UserModel user;
  const ComprasScreen({super.key, required this.user});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen>
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
        appBar: AppBar(title: const Text('Compras')),
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
        title: const Text('Compras'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(icon: Icon(Icons.add_shopping_cart), text: 'Nueva Compra'),
            Tab(icon: Icon(Icons.list_alt), text: 'Mis Compras'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NuevaCompraScreen(user: widget.user),
          ListaComprasScreen(user: widget.user),
        ],
      ),
    );
  }
}
