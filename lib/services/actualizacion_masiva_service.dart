import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class ActualizacionMasivaService {
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    const endpoint = 'api_actualizacion_masiva.php';
    try {
      body['cliente_id'] = AppConfig.clienteId;
      final response = await http
          .post(
            Uri.parse(AppConfig.api(endpoint)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('══ ActMasiva [${body['accion']}] ══');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return {'success': false, 'message': 'Respuesta vacía'};
        }
        try {
          return jsonDecode(response.body);
        } catch (e) {
          final p = response.body.length > 300
              ? response.body.substring(0, 300)
              : response.body;
          return {'success': false, 'message': 'Error PHP:\n$p'};
        }
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> listar({
    required int usuaIde,
    int departamento = 0,
    String busqueda = '',
  }) =>
      _post({
        'accion': 'listar',
        'usua_ide': usuaIde,
        'departamento': departamento,
        'busqueda': busqueda,
      });

  Future<Map<String, dynamic>> actualizarFila({
    required int usuaIde,
    required int productoIde,
    required double existen,
    required double costo,
    required double precio1,
    required double precioUsd,
  }) =>
      _post({
        'accion': 'actualizar_fila',
        'usua_ide': usuaIde,
        'produc_ide': productoIde,
        'produc_existen': existen,
        'produc_costo': costo,
        'produc_precio1': precio1,
        'produc_preciodolar': precioUsd,
      });

  Future<Map<String, dynamic>> actualizarTodo({
    required int usuaIde,
    required List<Map<String, dynamic>> productos,
  }) =>
      _post({
        'accion': 'actualizar_todo',
        'usua_ide': usuaIde,
        'productos': productos,
      });
}
