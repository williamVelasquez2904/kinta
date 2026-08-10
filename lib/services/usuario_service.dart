import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class UsuarioService {
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    const String endpoint = 'api_usuarios.php';
    try {
      body['cliente_id'] = AppConfig.clienteId;
      final response = await http
          .post(
            Uri.parse(AppConfig.api(endpoint)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('══ Usuarios [${body['accion']}] ══');
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
    String busqueda = '',
  }) =>
      _post({
        'accion': 'listar',
        'usua_ide': usuaIde,
        'busqueda': busqueda,
      });

  Future<Map<String, dynamic>> crear({
    required int usuaIde,
    required Map<String, dynamic> datos,
  }) =>
      _post({
        'accion': 'crear',
        'usua_ide': usuaIde,
        ...datos,
      });

  Future<Map<String, dynamic>> editar({
    required int usuaIde,
    required int targetIde,
    required Map<String, dynamic> datos,
  }) =>
      _post({
        'accion': 'editar',
        'usua_ide': usuaIde,
        'target_ide': targetIde,
        ...datos,
      });

  Future<Map<String, dynamic>> cambiarClave({
    required int usuaIde,
    required int targetIde,
    required String nuevaClave,
  }) =>
      _post({
        'accion': 'cambiar_clave',
        'usua_ide': usuaIde,
        'target_ide': targetIde,
        'nueva_clave': nuevaClave,
      });

  Future<Map<String, dynamic>> cambiarEstado({
    required int usuaIde,
    required int targetIde,
    required int nuevoEstado,
  }) =>
      _post({
        'accion': 'cambiar_estado',
        'usua_ide': usuaIde,
        'target_ide': targetIde,
        'nuevo_estado': nuevoEstado,
      });
}
