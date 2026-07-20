import 'package:flutter/material.dart';

class AppColors {
  // ── Paleta principal verde esmeralda ──────────────────────
  static const Color primary = Color(0xFF0F6E56); // verde oscuro
  static const Color primaryLight = Color(0xFF1D9E75); // verde medio
  static const Color primaryBg = Color(0xFFE1F5EE); // verde muy claro

  // ── Fondos ────────────────────────────────────────────────
  static const Color background = Color(0xFFF4F6F8); // gris muy claro
  static const Color surface = Color(0xFFFFFFFF); // blanco
  static const Color surfaceAlt = Color(0xFFF8F9FA); // gris suave

  // ── Sidebar ───────────────────────────────────────────────
  static const Color sidebar = Color(0xFFFFFFFF);
  static const Color sidebarBorder = Color(0xFFE8EAED);

  // ── Textos ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // ── Bordes ────────────────────────────────────────────────
  static const Color border = Color(0xFFE8EAED);
  static const Color borderFocus = Color(0xFF0F6E56);

  // ── Semánticos ────────────────────────────────────────────
  static const Color success = Color(0xFF0F6E56);
  static const Color successBg = Color(0xFFE1F5EE);
  static const Color error = Color(0xFFA32D2D);
  static const Color errorBg = Color(0xFFFCEBEB);
  static const Color warning = Color(0xFF854F0B);
  static const Color warningBg = Color(0xFFFAEEDA);
  static const Color info = Color(0xFF185FA5);
  static const Color infoBg = Color(0xFFE6F1FB);
  static const Color purple = Color(0xFF534AB7);
  static const Color purpleBg = Color(0xFFEEEDFE);

  // ── Módulos (acceso rápido) ───────────────────────────────
  static const Color misClientes = Color(0xFF0F6E56);
  static const Color misClientesBg = Color(0xFFE1F5EE);
  static const Color creditosVencidos = Color(0xFFA32D2D);
  static const Color creditosBg = Color(0xFFFCEBEB);
  static const Color saldos = Color(0xFF854F0B);
  static const Color saldosBg = Color(0xFFFAEEDA);
  static const Color saldosVentas = Color(0xFF185FA5);
  static const Color saldosVentasBg = Color(0xFFE6F1FB);
  static const Color clientes = Color(0xFF534AB7);
  static const Color clientesBg = Color(0xFFEEEDFE);

  // ── Glow (compatibilidad con pantallas anteriores) ────────
  static const Color glow = Color(0xFF1D9E75);
  static const Color accent = Color(0xFF0F6E56);
  static const Color accentLight = Color(0xFF1D9E75);
  static const Color divider = Color(0xFFE8EAED);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textSecondary,
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.border,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIconColor: AppColors.textHint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
        elevation: 0,
      ),

      // NavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryBg,
        labelTextStyle: MaterialStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(MaterialState.selected)
                ? AppColors.primary
                : AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(MaterialState.selected)
                ? AppColors.primary
                : AppColors.textHint,
          ),
        ),
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.sidebar,
        surfaceTintColor: Colors.transparent,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
      ),

      // Text
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        headlineMedium: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        headlineSmall: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        titleLarge: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(color: AppColors.textPrimary),
        titleSmall: TextStyle(color: AppColors.textSecondary),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.textHint),
        labelLarge: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: AppColors.textSecondary),
        labelSmall: TextStyle(color: AppColors.textHint),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      // ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
    );
  }
}
