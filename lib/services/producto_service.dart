import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class ProductoService {
  // ── Helper POST ──────────────────────────────────────────
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    const String endpoint = 'api_productos_crud.php';
    try {
      //debugPrint('Body enviado: ${jsonEncode(body)}');
      body['cliente_id'] = AppConfig.clienteId;
      debugPrint('Body enviado: ${jsonEncode(body)}');
      final response = await http
          .post(
            Uri.parse(AppConfig.api(endpoint)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      // Log en consola para debug
      debugPrint('══ POST $endpoint [${body['accion']}] ══');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Respuesta: ${response.body}');
      debugPrint('═══════════════════════════════════════');

      if (response.statusCode == 200) {
        // Respuesta vacía
        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'El servidor devolvió una respuesta vacía.\n'
                'URL: ${AppConfig.api(endpoint)}'
          };
        }

        // Intentar parsear JSON
        try {
          return jsonDecode(response.body);
        } catch (e) {
          // El PHP devolvió HTML (error de PHP, warning, etc.)
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

      // Error HTTP
      return {
        'success': false,
        'message': 'Error HTTP ${response.statusCode}.\n'
            'URL: ${AppConfig.api(endpoint)}'
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'No se pudo conectar al servidor.\n'
            'URL: ${AppConfig.api(endpoint)}\n'
            'Detalle: ${e.message}'
      };
    } on FormatException catch (e) {
      return {
        'success': false,
        'message': 'Error al procesar respuesta JSON.\n'
            'Detalle: ${e.message}'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error inesperado: $e\n'
            'URL: ${AppConfig.api(endpoint)}'
      };
    }
  }

  // ── Listar productos (búsqueda general) ──────────────────
  Future<Map<String, dynamic>> listar({
    String busqueda = '',
    bool soloStock = false,
  }) =>
      _post({
        'accion': 'listar',
        'busqueda': busqueda,
        'solo_stock': soloStock ? 1 : 0,
      });

  // ── Detalle de un producto ───────────────────────────────
  Future<Map<String, dynamic>> detalle(int productoIde) => _post({
        'accion': 'detalle',
        'produc_ide': productoIde,
      });

  // ── Cargar listas (marcas, modelos, unidades, etc.) ──────
  Future<Map<String, dynamic>> cargarListas() => _post({'accion': 'listas'});

  // ── Crear producto ───────────────────────────────────────
  Future<Map<String, dynamic>> crear({
    required int usuaIde,
    required Map<String, dynamic> datos,
    String? fotoBase64,
  }) =>
      _post({
        'accion': 'crear',
        'usua_ide': usuaIde,
        ...datos,
        if (fotoBase64 != null) 'foto_base64': fotoBase64,
      });

  // ── Editar producto ──────────────────────────────────────
  Future<Map<String, dynamic>> editar({
    required int usuaIde,
    required int productoIde,
    required Map<String, dynamic> datos,
    String? fotoBase64,
  }) =>
      _post({
        'accion': 'editar',
        'usua_ide': usuaIde,
        'produc_ide': productoIde,
        ...datos,
        if (fotoBase64 != null) 'foto_base64': fotoBase64,
      });

  // ── Eliminar producto (borrado lógico) ───────────────────
  Future<Map<String, dynamic>> eliminar({
    required int usuaIde,
    required int productoIde,
  }) =>
      _post({
        'accion': 'eliminar',
        'usua_ide': usuaIde,
        'produc_ide': productoIde,
      });

  // ── Listar para reporte de inventario ────────────────────
  Future<Map<String, dynamic>> listarParaReporte({
    required int usuaIde,
    required int usuaTius,
    int departamentoIde = 0,
    String filtroStock = 'todos',
  }) =>
      _post({
        'accion': 'listar_reporte',
        'usua_ide': usuaIde,
        'usua_tius': usuaTius,
        'departamento': departamentoIde,
        'filtro_stock': filtroStock,
      });
}
