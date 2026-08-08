import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class MantenimientoService {
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    const String endpoint = 'api_mantenimiento.php';
    try {
      body['cliente_id'] = AppConfig.clienteId;

      final response = await http
          .post(
            Uri.parse(AppConfig.api(endpoint)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('══ Mantenimiento [${body['tabla']}]'
          ' [${body['accion']}] ══');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body  : ${response.body}');

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
    required String tabla,
    String busqueda = '',
  }) =>
      _post({
        'accion': 'listar',
        'tabla': tabla,
        'usua_ide': usuaIde,
        'busqueda': busqueda,
      });

  Future<Map<String, dynamic>> crear({
    required int usuaIde,
    required String tabla,
    required String descripcion,
  }) =>
      _post({
        'accion': 'crear',
        'tabla': tabla,
        'usua_ide': usuaIde,
        'descripcion': descripcion,
      });

  Future<Map<String, dynamic>> editar({
    required int usuaIde,
    required String tabla,
    required int ide,
    required String descripcion,
  }) =>
      _post({
        'accion': 'editar',
        'tabla': tabla,
        'usua_ide': usuaIde,
        'ide': ide,
        'descripcion': descripcion,
      });

  Future<Map<String, dynamic>> eliminar({
    required int usuaIde,
    required String tabla,
    required int ide,
  }) =>
      _post({
        'accion': 'eliminar',
        'tabla': tabla,
        'usua_ide': usuaIde,
        'ide': ide,
      });
}
