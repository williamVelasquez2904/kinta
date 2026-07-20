import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class CompraService {
  // ── Helper POST ──────────────────────────────────────────
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      // Inyecta cliente_id automáticamente
      body['cliente_id'] = AppConfig.clienteId;

      final response = await http
          .post(
            Uri.parse(AppConfig.api(endpoint)),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'success': false,
        'message': 'Error del servidor ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ════════════════════════════════════════════════════════
  // PROVEEDORES
  // ════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> listarProveedores({
    required int usuaIde,
    String busqueda = '',
  }) =>
      _post('api_proveedores.php', {
        'accion': 'listar',
        'usua_ide': usuaIde,
        'busqueda': busqueda,
      });

  Future<Map<String, dynamic>> crearProveedor({
    required int usuaIde,
    required String nombre,
    String rif = '',
    String telefono = '',
    String email = '',
    String direccion = '',
    String contacto = '',
  }) =>
      _post('api_proveedores.php', {
        'accion': 'crear',
        'usua_ide': usuaIde,
        'prove_nombre': nombre,
        'prove_rif': rif,
        'prove_telefono': telefono,
        'prove_email': email,
        'prove_direccion': direccion,
        'prove_contacto': contacto,
      });

  Future<Map<String, dynamic>> editarProveedor({
    required int usuaIde,
    required int proveIde,
    required String nombre,
    String rif = '',
    String telefono = '',
    String email = '',
    String direccion = '',
    String contacto = '',
  }) =>
      _post('api_proveedores.php', {
        'accion': 'editar',
        'usua_ide': usuaIde,
        'prove_ide': proveIde,
        'prove_nombre': nombre,
        'prove_rif': rif,
        'prove_telefono': telefono,
        'prove_email': email,
        'prove_direccion': direccion,
        'prove_contacto': contacto,
      });

  Future<Map<String, dynamic>> eliminarProveedor({
    required int usuaIde,
    required int proveIde,
  }) =>
      _post('api_proveedores.php', {
        'accion': 'eliminar',
        'usua_ide': usuaIde,
        'prove_ide': proveIde,
      });

  // ════════════════════════════════════════════════════════
  // COMPRAS
  // ════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> listarCompras({
    required int usuaIde,
    int estado = -1,
    String busqueda = '',
  }) =>
      _post('api_compras.php', {
        'accion': 'listar',
        'usua_ide': usuaIde,
        'estado': estado,
        'busqueda': busqueda,
      });

  Future<Map<String, dynamic>> detalleCompra({
    required int usuaIde,
    required int compraIde,
  }) =>
      _post('api_compras.php', {
        'accion': 'detalle',
        'usua_ide': usuaIde,
        'compra_ide': compraIde,
      });

  Future<Map<String, dynamic>> crearCompra({
    required int usuaIde,
    required int proveIde,
    required String fecha,
    String documento = '',
    double impuesto = 0,
    String observa = '',
    required List<Map<String, dynamic>> items,
  }) =>
      _post('api_compras.php', {
        'accion': 'crear',
        'usua_ide': usuaIde,
        'prove_ide': proveIde,
        'fecha': fecha,
        'documento': documento,
        'impuesto': impuesto,
        'observa': observa,
        'items': items,
      });

  Future<Map<String, dynamic>> confirmarCompra({
    required int usuaIde,
    required int compraIde,
  }) =>
      _post('api_compras.php', {
        'accion': 'confirmar',
        'usua_ide': usuaIde,
        'compra_ide': compraIde,
      });

  Future<Map<String, dynamic>> anularCompra({
    required int usuaIde,
    required int compraIde,
  }) =>
      _post('api_compras.php', {
        'accion': 'anular',
        'usua_ide': usuaIde,
        'compra_ide': compraIde,
      });
}
