import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _apiUrl =
      'https://ecotrago.com/backend/api_asistente_local.php';

  Future<Map<String, dynamic>> enviarMensaje({
    required String mensaje,
    required String numiden,
    required List<Map<String, String>> historial,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mensaje': mensaje,
              'numiden': numiden,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return {
        'success': false,
        'respuesta': 'Error del servidor ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'respuesta': 'Error de conexión: $e'};
    }
  }
}
