import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class ClienteService {
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      body['cliente_id'] = AppConfig.clienteId;
      final response = await http
          .post(
            Uri.parse(AppConfig.api('api_clientes_crud.php')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) {
          return {
            'success': false,
            'message': 'Respuesta vacía del servidor',
            'statusCode': response.statusCode,
          };
        }
        try {
          return jsonDecode(body);
        } catch (e) {
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor',
            'details': e.toString(),
            'raw': body.length > 1000 ? body.substring(0, 1000) : body,
            'statusCode': response.statusCode,
          };
        }
      }
      return {
        'success': false,
        'message': 'Error del servidor ${response.statusCode}',
        'raw': response.body,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> listar({
    required int usuaIde,
    int? usuaTius,
    String busqueda = '',
    String tipcli = '',
  }) =>
      _post({
        'accion': 'listar',
        'usua_ide': usuaIde,
        if (usuaTius != null) 'usua_tius': usuaTius,
        'busqueda': busqueda,
        'tipcli': tipcli,
      });

  Future<Map<String, dynamic>> detalle({
    required int usuaIde,
    int? usuaTius,
    required int clienIde,
  }) =>
      _post({
        'accion': 'detalle',
        'usua_ide': usuaIde,
        if (usuaTius != null) 'usua_tius': usuaTius,
        'clien_ide': clienIde,
      });

  Future<Map<String, dynamic>> cargarListas() => _post({'accion': 'listas'});

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
    required int clienIde,
    required Map<String, dynamic> datos,
  }) =>
      _post({
        'accion': 'editar',
        'usua_ide': usuaIde,
        'clien_ide': clienIde,
        ...datos,
      });

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
