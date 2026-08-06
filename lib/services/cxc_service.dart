import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class CxcService {
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    const String endpoint = 'api_cuentas_cobrar.php';
    try {
      body['cliente_id'] = AppConfig.clienteId;
      final response = await http
          .post(
            Uri.parse(AppConfig.api(endpoint)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('══ CxC POST [${body['accion']}] ══');
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

  // Resumen de todos los clientes con deuda
  Future<Map<String, dynamic>> resumen(int usuaIde) => _post({
        'accion': 'resumen',
        'usua_ide': usuaIde,
      });

  // Estado de cuenta de un cliente
  Future<Map<String, dynamic>> estadoCuenta({
    required int usuaIde,
    required int clienIde,
  }) =>
      _post({
        'accion': 'estado_cuenta',
        'usua_ide': usuaIde,
        'clien_ide': clienIde,
      });

  // Registrar pago
  Future<Map<String, dynamic>> registrarPago({
    required int usuaIde,
    required int facturaIde,
    required int clienIde,
    required double monto,
    required String forma,
    String referencia = '',
    String observa = '',
    required String fecha,
  }) =>
      _post({
        'accion': 'registrar_pago',
        'usua_ide': usuaIde,
        'factura_ide': facturaIde,
        'clien_ide': clienIde,
        'monto': monto,
        'forma': forma,
        'referencia': referencia,
        'observa': observa,
        'fecha': fecha,
      });

  // Anular pago (solo admin)
  Future<Map<String, dynamic>> anularPago({
    required int usuaIde,
    required int pagoIde,
  }) =>
      _post({
        'accion': 'anular_pago',
        'usua_ide': usuaIde,
        'pago_ide': pagoIde,
      });
}
