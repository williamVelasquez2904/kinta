class AppInfo {
  static const String nombre = 'Kinta';
  //static const String version = '1.0.0- Jul-01-2026 - Versión WEB-Beta';
  static const String version = '1.0.0- Jul-18-2026';
  static const int build = 2;

  /*
  static const String nombre = 'Kinta-Sumimed';
  static const String version = '1.0.0- Jul-01-2026 - Versión WEB';
  static const int build = 1;
  */
  static String get versionCompleta => 'v$version+$build';
}
