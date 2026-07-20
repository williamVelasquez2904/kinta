import 'dart:convert';
import 'package:http/http.dart' as http;

class VentaService {
  static const String _baseUrl = 'https://ecotrago.com/backend';

  // ── Productos ────────────────────────────────────────────
  Future<Map<String, dynamic>> buscarProductos(String busqueda) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api_productos.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'busqueda': busqueda}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error del servidor'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Clientes (sin filtro de vendedor) ───────────────────
  Future<Map<String, dynamic>> buscarClientes({
    required int usuaIde,
    String busqueda = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api_buscar_clientes.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'usua_ide': usuaIde,
              'busqueda': busqueda,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error del servidor'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Crear factura ────────────────────────────────────────
  Future<Map<String, dynamic>> crearFactura({
    required int clienteIde,
    required int usuaIde,
    required int tipoPrecio,
    required int condicion,
    required int diasCredito,
    required double descuento,
    required double flete,
    required double impuesto,
    required double abonoInicial,
    required String observa,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api_crear_factura.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cliente_ide': clienteIde,
              'usua_ide': usuaIde,
              'tipo_precio': tipoPrecio,
              'condicion': condicion,
              'dias_credito': diasCredito,
              'descuento': descuento,
              'flete': flete,
              'impuesto': impuesto,
              'abono_inicial': abonoInicial,
              'observa': observa,
              'items': items,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error del servidor'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Listar mis ventas ────────────────────────────────────
  Future<Map<String, dynamic>> listarFacturas(int usuaIde) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api_facturas_vendedor.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'usua_ide': usuaIde}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error del servidor'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Detalle de una factura ───────────────────────────────
  Future<Map<String, dynamic>> detalleFactura(int facturaIde) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api_factura_detalle.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'factura_ide': facturaIde}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error del servidor'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Datos de la empresa (para nota de entrega) ───────────
  Future<Map<String, dynamic>> obtenerEmpresa() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api_empresa.php'),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error del servidor'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Reporte de ventas por fecha ───────────────────────────
  Future<Map<String, dynamic>> reporteVentas({
    required int usuaIde,
    required String fechaDesde,
    required String fechaHasta,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api_reporte_ventas.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'usua_ide': usuaIde,
              'fecha_desde': fechaDesde,
              'fecha_hasta': fechaHasta,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Error del servidor'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
