import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreditosScreen extends StatelessWidget {
  // ← cambia el nombre
  const CreditosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créditos'), // ← cambia el título
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card, // ← cambia el ícono
              size: 64,
              color: AppColors.saldos,
            ),
            SizedBox(height: 16),
            Text(
              'Módulo Créditos en construcción',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
