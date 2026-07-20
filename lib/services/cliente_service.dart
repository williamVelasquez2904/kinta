import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class ClienteService {
  // ── Helper POST ──────────────────────────────────────────
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    const String endpoint = 'api_clientes_crud.php';
    try {
      body['cliente_id'] = AppConfig.clienteId;

      final response = await http
          .post(
            Uri.parse(AppConfig.api(endpoint)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('══ POST $endpoint [${body['accion']}] ══');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Respuesta: ${response.body}');
      debugPrint('═══════════════════════════════════════');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return {
            'success': false,
            'message': 'Respuesta vacía del servidor.\n'
                'URL: ${AppConfig.api(endpoint)}'
          };
        }
        try {
          return jsonDecode(response.body);
        } catch (e) {
          final preview = response.body.length > 400
              ? response.body.substring(0, 400)
              : response.body;
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor.\n'
                'El PHP devolvió:\n$preview'
          };
        }
      }

      return {
        'success': false,
        'message': 'Error HTTP ${response.statusCode}.\n'
            'URL: ${AppConfig.api(endpoint)}'
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor.\n'
            'Detalle: ${e.message}'
      };
    } on FormatException catch (e) {
      return {
        'success': false,
        'message': 'Error al procesar respuesta JSON.\n'
            'Detalle: ${e.message}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // ── Listar clientes ──────────────────────────────────────
  Future<Map<String, dynamic>> listar({
    required int usuaIde,
    String busqueda = '',
    String tipcli = '',
  }) =>
      _post({
        'accion': 'listar',
        'usua_ide': usuaIde,
        'busqueda': busqueda,
        'tipcli': tipcli,
      });
  /*
  // ── Detalle de un cliente ────────────────────────────────
  Future<Map<String, dynamic>> detalle(int clienIde) => _post({
        'accion': 'detalle',
        'clien_ide': clienIde,
      });*/
  Future<Map<String, dynamic>> detalle(
    int clienIde, {
    required int usuaIde,
  }) =>
      _post({
        'accion': 'detalle',
        'usua_ide': usuaIde,
        'clien_ide': clienIde,
      });

  // ── Cargar listas auxiliares ─────────────────────────────
  Future<Map<String, dynamic>> cargarListas() => _post({'accion': 'listas'});

  // ── Crear cliente ────────────────────────────────────────
  Future<Map<String, dynamic>> crear({
    required int usuaIde,
    required Map<String, dynamic> datos,
  }) =>
      _post({
        'accion': 'crear',
        'usua_ide': usuaIde,
        ...datos,
      });

  // ── Editar cliente ───────────────────────────────────────
  Future<Map<String, dynamic>> editar({
    required int usuaIde,
    required int clienIde,
    required Map<String, dynamic> datos,
  }) =>
      _post({
        'accion': 'editar',
        'usua_ide': usuaIde,
        'clien_ide': clienIde,
        ...datos,
      });

  // ── Eliminar cliente ─────────────────────────────────────
  Future<Map<String, dynamic>> eliminar({
    required int usuaIde,
    required int clienIde,
  }) =>
      _post({
        'accion': 'eliminar',
        'usua_ide': usuaIde,
        'clien_ide': clienIde,
      });
}
