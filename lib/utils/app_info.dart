import 'app_config.dart';

class AppInfo {
  //static const String _nombre = 'Kinta';
  //static const String _nombre = 'Kinta';
  static const String version =
      '1.0.0 - Versión WEB JUL-2026'; // VERSION DE LA APP
  static const int build = 24; // DIA DE COMPILACION

  // Nombre base
  static String get nombre => AppConfig.appNombre;

  // Versión completa: Kinta-sumimed v1.0.0+1
  static String get versionCompleta =>
      '${AppConfig.appNombre} v$version+$build';
}
