import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MonitorService {
  // La URL del monitor apunta siempre al servidor
  // central, no al cliente específico
  static const String _endpoint =
      'https://kintatienda.com/backend/kinta/api_monitor.php';

  // Clave de acceso al monitor
  static const String _apiKey = 'kinta_monitor_2026';

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      body['clave_api'] = _apiKey;

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('══ Monitor [${body['accion']}] ══');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return {'success': false, 'message': 'Respuesta vacía'};
        }
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {'success': false, 'message': 'Error: ${response.body}'};
        }
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> resumen() => _post({'accion': 'resumen'});

  Future<Map<String, dynamic>> listar({
    String clienteId = '',
    String accionF = '',
    String moduloF = '',
    String resultadoF = '',
    String busqueda = '',
    String fechaDesde = '',
    String fechaHasta = '',
    int limit = 100,
  }) =>
      _post({
        'accion': 'listar',
        'cliente_id': clienteId,
        'accion_f': accionF,
        'modulo_f': moduloF,
        'resultado_f': resultadoF,
        'busqueda': busqueda,
        'fecha_desde': fechaDesde.isNotEmpty ? fechaDesde : _hoy(),
        'fecha_hasta': fechaHasta.isNotEmpty ? fechaHasta : _hoy(),
        'limit': limit,
      });

  Future<Map<String, dynamic>> eliminar({int? ide}) => _post({
        'accion': 'eliminar',
        if (ide != null) 'ide': ide,
      });

  Future<Map<String, dynamic>> limpiar() => _post({'accion': 'limpiar'});

  String _hoy() {
    final d = DateTime.now();
    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
