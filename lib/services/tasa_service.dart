import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class TasaService {
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      body['cliente_id'] = AppConfig.clienteId;
      final response = await http
          .post(
            Uri.parse(AppConfig.api('api_tasa.php')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return {'success': false, 'message': 'Respuesta vacía'};
        }
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            'success': false,
            'message': 'Error al procesar respuesta: $e'
          };
        }
      }
      return {'success': false, 'message': 'Error HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> obtener() => _post({'accion': 'obtener'});

  Future<Map<String, dynamic>> obtenerDesdeBcv(int usuaIde) => _post({
        'accion': 'obtener_bcv',
        'usua_ide': usuaIde,
      });

  Future<Map<String, dynamic>> guardar({
    required int usuaIde,
    required double bcv,
    required double paralela,
    required double euro,
    String fuente = 'Manual',
    String? fecha,
    String? hora,
  }) =>
      _post({
        'accion': 'guardar',
        'usua_ide': usuaIde,
        'bcv': bcv,
        'paralela': paralela,
        'euro': euro,
        'fuente': fuente,
        if (fecha != null) 'fecha': fecha,
        if (hora != null) 'hora': hora,
      });

  Future<Map<String, dynamic>> historial(int usuaIde) => _post({
        'accion': 'historial',
        'usua_ide': usuaIde,
      });
}
