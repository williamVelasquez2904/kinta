class AppConfig {
  // ── ID del cliente activo ─────────────────────────────────

  //static const String clienteId = 'kinta_demo';
  //static const String clienteId = 'valenpan';
  //static const String clienteId = 'farmamoto'; // Kinta0002
  //static const String clienteId = 'nicely'; // Kinta0008
  //static const String clienteId = 'parmol'; // Kinta0004
  //static const String clienteId = 'aromas'; // Kinta0005
  static const String clienteId = 'FerrehogarMayho'; // Kinta0006
  //static const String clienteId = 'nestor'; // Kinta0008
  //static const String clienteId = 'jeanz'; // Kinta0009 Jean Carlos Leche
  //static const String clienteId = 'demo1'; // kintatie_kinta_demo1

  //FerrehogarMayho

  // ── Nombre de la app base ─────────────────────────────────
  static const String _appNombre = 'Kinta';

  // ── Nombre completo: Kinta-sumimed ────────────────────────
  static String get appNombre => '$_appNombre-$clienteId';

  // ── Entorno ───────────────────────────────────────────────
  //static const Entorno entorno = Entorno.local;
  static const Entorno entorno = Entorno.produccion;

  static const String _urlLocal = 'http://192.168.0.215';

  //static const String _urlProduccion = 'https://ecotrago.com';
  static const String _urlProduccion = 'https://kintatienda.com';

  static String get baseUrl {
    switch (entorno) {
      case Entorno.local:
        return _urlLocal;
      case Entorno.produccion:
        return _urlProduccion;
    }
  }

  static String get backendUrl => '$baseUrl/backend/kinta';
  static String api(String endpoint) => '$backendUrl/$endpoint';
  static bool get esLocal => entorno == Entorno.local;

  static String get nombreEntorno {
    switch (entorno) {
      case Entorno.local:
        return 'LOCAL';
      case Entorno.produccion:
        return 'PRODUCCIÓN';
    }
  }
}

enum Entorno { local, produccion }
