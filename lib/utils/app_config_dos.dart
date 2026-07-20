/// ╔══════════════════════════════════════════════════════════╗
/// ║           CONFIGURACIÓN GLOBAL DE LA APP                 ║
/// ║  Para un nuevo cliente solo cambia clienteId y baseUrl   ║
/// ╚══════════════════════════════════════════════════════════╝
class AppConfig {
  // ── ID del cliente activo ─────────────────────────────────
  // Este valor debe coincidir con la clave en config/clientes.php
  //static const String clienteId = 'valenpan';
  static const String clienteId = 'sumimed';

  // ── URL del servidor donde están los PHP ─────────────────
  // Puede ser local o remota — los PHP son los mismos para todos
  //static const Entorno entorno = Entorno.local;
  static const Entorno entorno = Entorno.produccion;

  static const String _urlLocal = 'http://192.168.0.215';
  static const String _urlProduccion = 'https://ecotrago.com';

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

  // ── Nombre del entorno activo ─────────────────────────────
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
