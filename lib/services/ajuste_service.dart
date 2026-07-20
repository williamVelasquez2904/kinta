import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class AjusteService {
  // ── Helper POST ──────────────────────────────────────────
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      // Inyecta cliente_id automáticamente
      body['cliente_id'] = AppConfig.clienteId;

      final response = await http
          .post(
            Uri.parse(AppConfig.api('api_ajustes.php')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'success': false,
        'message': 'Error del servidor ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Listar ajustes ───────────────────────────────────────
  Future<Map<String, dynamic>> listar({
    required int usuaIde,
    int estado = -1,
    String busqueda = '',
  }) =>
      _post({
        'accion': 'listar',
        'usua_ide': usuaIde,
        'estado': estado,
        'busqueda': busqueda,
      });

  // ── Detalle de un ajuste ─────────────────────────────────
  Future<Map<String, dynamic>> detalle({
    required int usuaIde,
    required int ajusteIde,
  }) =>
      _post({
        'accion': 'detalle',
        'usua_ide': usuaIde,
        'ajuste_ide': ajusteIde,
      });

  // ── Crear ajuste (Borrador — NO toca stock) ──────────────
  Future<Map<String, dynamic>> crear({
    required int usuaIde,
    required String razon,
    required String descripcion,
    required String fecha,
    required List<Map<String, dynamic>> items,
  }) =>
      _post({
        'accion': 'crear',
        'usua_ide': usuaIde,
        'razon': razon,
        'descripcion': descripcion,
        'fecha': fecha,
        'items': items,
      });

  // ── Aplicar ajuste (descuenta del inventario) ────────────
  Future<Map<String, dynamic>> aplicar({
    required int usuaIde,
    required int ajusteIde,
  }) =>
      _post({
        'accion': 'aplicar',
        'usua_ide': usuaIde,
        'ajuste_ide': ajusteIde,
      });

  // ── Anular ajuste (solo si está en Borrador) ─────────────
  Future<Map<String, dynamic>> anular({
    required int usuaIde,
    required int ajusteIde,
  }) =>
      _post({
        'accion': 'anular',
        'usua_ide': usuaIde,
        'ajuste_ide': ajusteIde,
      });
}
