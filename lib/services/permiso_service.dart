import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class PermisoService {
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    const String endpoint = 'api_permisos.php';
    try {
      body['cliente_id'] = AppConfig.clienteId;
      final response = await http
          .post(
            Uri.parse(AppConfig.api(endpoint)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('══ Permisos [${body['accion']}] ══');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body  : ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return {'success': false, 'message': 'Respuesta vacía'};
        }
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {'success': false, 'message': 'Error PHP: ${response.body}'};
        }
      }
      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Obtener permisos del usuario logueado
  Future<Map<String, dynamic>> misPermisos(int usuaIde) => _post({
        'accion': 'mis_permisos',
        'usua_ide': usuaIde,
      });

  // Listar permisos de un perfil para administrar
  Future<Map<String, dynamic>> listarPerfil({
    required int usuaIde,
    required int permTius,
  }) =>
      _post({
        'accion': 'listar_perfil',
        'usua_ide': usuaIde,
        'perm_tius': permTius,
      });

  // Guardar un permiso individual (toggle)
  Future<Map<String, dynamic>> guardarPermiso({
    required int usuaIde,
    required int permTius,
    required int permSumo,
    required int permEstado,
  }) =>
      _post({
        'accion': 'guardar_permiso',
        'usua_ide': usuaIde,
        'perm_tius': permTius,
        'perm_sumo': permSumo,
        'perm_estado': permEstado,
      });

  // Guardar todos los permisos de un perfil
  Future<Map<String, dynamic>> guardarTodos({
    required int usuaIde,
    required int permTius,
    required List permisos,
  }) =>
      _post({
        'accion': 'guardar_todos',
        'usua_ide': usuaIde,
        'perm_tius': permTius,
        'permisos': permisos,
      });
}
