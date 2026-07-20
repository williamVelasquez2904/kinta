import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SaldosScreen extends StatelessWidget {
  // ← cambia el nombre
  const SaldosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saldos'), // ← cambia el título
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.balance, // ← cambia el ícono
              size: 64,
              color: AppColors.saldos,
            ),
            SizedBox(height: 16),
            Text(
              'Módulo en construcción',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
