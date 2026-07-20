import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class VentaService {
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
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = response.body;
        if (body.trim().isEmpty) {
          return {'success': false, 'message': 'Respuesta vacía del servidor'};
        }
        try {
          return jsonDecode(body);
        } catch (e) {
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor',
            'details': e.toString(),
            'raw': body.length > 1000 ? body.substring(0, 1000) : body,
          };
        }
      }
      return {
        'success': false,
        'message': 'Error del servidor ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Helper GET ───────────────────────────────────────────
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final uri = Uri.parse(AppConfig.api(endpoint)).replace(queryParameters: {
        'cliente_id': AppConfig.clienteId,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body;
        if (body.trim().isEmpty) {
          return {'success': false, 'message': 'Respuesta vacía del servidor'};
        }
        try {
          return jsonDecode(body);
        } catch (e) {
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor',
            'details': e.toString(),
            'raw': body.length > 1000 ? body.substring(0, 1000) : body,
          };
        }
      }
      return {
        'success': false,
        'message': 'Error del servidor ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ── Productos ────────────────────────────────────────────
  Future<Map<String, dynamic>> buscarProductos(String busqueda) =>
      _post('api_productos.php', {'busqueda': busqueda});

  // ── Clientes ─────────────────────────────────────────────
  Future<Map<String, dynamic>> buscarClientes({
    required int usuaIde,
    String busqueda = '',
  }) =>
      _post('api_buscar_clientes.php', {
        'usua_ide': usuaIde,
        'busqueda': busqueda,
      });

  // ── Crear factura ─────────────────────────────────────────
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
    required String fechaVenta,
    required List<Map<String, dynamic>> items,
  }) =>
      _post('api_crear_factura.php', {
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
        'fecha_venta': fechaVenta,
        'items': items,
      });

  // ── Listar mis ventas ─────────────────────────────────────
  Future<Map<String, dynamic>> listarFacturas(int usuaIde) =>
      _post('api_facturas_vendedor.php', {'usua_ide': usuaIde});

  // ── Detalle de una factura ────────────────────────────────
  Future<Map<String, dynamic>> detalleFactura(int facturaIde) =>
      _post('api_factura_detalle.php', {'factura_ide': facturaIde});

  // ── Datos de la empresa ───────────────────────────────────
  Future<Map<String, dynamic>> obtenerEmpresa() => _get('api_empresa.php');

  // ── Reporte de ventas por rango de fecha ──────────────────
  Future<Map<String, dynamic>> reporteVentas({
    required int usuaIde,
    required String fechaDesde,
    required String fechaHasta,
  }) =>
      _post('api_reporte_ventas.php', {
        'usua_ide': usuaIde,
        'fecha_desde': fechaDesde,
        'fecha_hasta': fechaHasta,
      });

  // ── Reporte por producto ──────────────────────────────────
  Future<Map<String, dynamic>> reporteProducto({
    required int usuaIde,
    required String busqueda,
    required String fechaDesde,
    required String fechaHasta,
  }) =>
      _post('api_reporte_producto.php', {
        'usua_ide': usuaIde,
        'busqueda': busqueda,
        'fecha_desde': fechaDesde,
        'fecha_hasta': fechaHasta,
      });

  // ── Gráfica productos más vendidos ───────────────────────
  Future<Map<String, dynamic>> graficaProductos({
    required int usuaIde,
    required String fechaDesde,
    required String fechaHasta,
    int departamento = 0,
  }) =>
      _post('api_grafica_productos.php', {
        'usua_ide': usuaIde,
        'fecha_desde': fechaDesde,
        'fecha_hasta': fechaHasta,
        'departamento': departamento,
      });
}
