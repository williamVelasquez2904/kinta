import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

/// Servicio para la carga masiva de productos desde Excel.
/// El archivo se parsea en el cliente (Flutter); este servicio solo
/// envía/recibe JSON con el backend.
class CargaMasivaProductosService {
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.api('api_carga_masiva_productos.php')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cliente_id': AppConfig.clienteId,
          ...body,
        }),
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Error del servidor (${response.statusCode})',
        };
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;

      return {
        'success': false,
        'message': 'Respuesta inesperada del servidor',
      };
    } catch (e) {
      // Preview del error para depurar rápido si el backend devolvió HTML
      // (típico de un error PHP no capturado) en lugar de JSON.
      final preview = e.toString();
      return {
        'success': false,
        'message':
            'Error de conexión: ${preview.length > 200 ? preview.substring(0, 200) : preview}',
      };
    }
  }

  /// Consulta cuáles códigos ya existen en la base de datos del cliente.
  /// Devuelve un mapa: { codigo: {produc_ide, produc_descrip, produc_existen, produc_costo, produc_precio1, produc_preciodolar, produc_departamento} }
  Future<Map<String, dynamic>> verificarCodigos(List<String> codigos) {
    return _post({'accion': 'verificar', 'codigos': codigos});
  }

  /// Ejecuta la importación masiva.
  /// [accionExistente] debe ser 'actualizar' o 'omitir'.
  /// Cada producto en [productos] debe traer: produc_codigo, produc_descrip,
  /// produc_existen, produc_costo, produc_precio1, produc_preciodolar,
  /// produc_departamento.
  Future<Map<String, dynamic>> importar({
    required List<Map<String, dynamic>> productos,
    required String accionExistente,
  }) {
    return _post({
      'accion': 'importar',
      'accion_existente': accionExistente,
      'productos': productos,
    });
  }
}
