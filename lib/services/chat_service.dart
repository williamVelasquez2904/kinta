import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class ChatService {
  Future<Map<String, dynamic>> enviarMensaje({
    required String mensaje,
    required String numiden,
    required List<Map<String, String>> historial,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.api('api_asistente_local.php')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mensaje': mensaje,
              'numiden': numiden,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'respuesta': 'Error del servidor'};
    } catch (e) {
      return {'success': false, 'respuesta': 'Error de conexión: $e'};
    }
  }
}
