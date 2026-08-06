import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/app_config.dart';
import '../utils/app_info.dart';

class AuditoriaService {
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    try {
      body['cliente_id'] = AppConfig.clienteId;
      final response = await http
          .post(
            Uri.parse(AppConfig.api('api_auditoria.php')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false};
    } catch (e) {
      // La auditoría NUNCA interrumpe el flujo principal
      debugPrint('AuditoriaService error: $e');
      return {'success': false};
    }
  }

  // ── Detectar plataforma ──────────────────────────────────
  String get _dispositivo {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      default:
        return 'Desconocido';
    }
  }

  // ── Método base ──────────────────────────────────────────
  Future<void> registrar({
    required UserModel user,
    required String accion,
    required String modulo,
    required String descripcion,
    String? tabla,
    int? registroIde,
    Map? datoAntes,
    Map? datoDespues,
    String resultado = 'OK',
    String? errorMsg,
  }) async {
    await _post({
      'accion': 'registrar',
      'usua_ide': user.usuaIde,
      'usua_login': user.login,
      'usua_nombre': user.nombreCompleto,
      'usua_tius': user.tius,
      'accion_log': accion,
      'modulo': modulo,
      'descripcion': descripcion,
      'tabla': tabla ?? '',
      'registro_ide': registroIde ?? 0,
      'dato_antes': datoAntes ?? {},
      'dato_despues': datoDespues ?? {},
      'dispositivo': _dispositivo,
      'app_version': AppInfo.versionCompleta,
      'resultado': resultado,
      'error_msg': errorMsg ?? '',
    });
  }

  // ── Shortcuts ────────────────────────────────────────────

  Future<void> login(UserModel user) => registrar(
        user: user,
        accion: 'LOGIN',
        modulo: 'SESION',
        descripcion: 'Inicio de sesión exitoso',
      );

  Future<void> logout(UserModel user) => registrar(
        user: user,
        accion: 'LOGOUT',
        modulo: 'SESION',
        descripcion: 'Cierre de sesión',
      );

  Future<void> loginFallido(String loginIntento) async {
    await _post({
      'accion': 'registrar',
      'cliente_id': AppConfig.clienteId,
      'usua_ide': 0,
      'usua_login': loginIntento,
      'usua_nombre': 'DESCONOCIDO',
      'usua_tius': 0,
      'accion_log': 'LOGIN_FALLIDO',
      'modulo': 'SESION',
      'descripcion': 'Intento de login fallido: $loginIntento',
      'tabla': '',
      'registro_ide': 0,
      'dispositivo': _dispositivo,
      'app_version': AppInfo.versionCompleta,
      'resultado': 'ERROR',
    });
  }

  Future<void> crearVenta(
          UserModel user, int facturaIde, String facturaNum, double total) =>
      registrar(
        user: user,
        accion: 'CREAR',
        modulo: 'VENTA',
        descripcion: 'Venta: $facturaNum — Total: $total',
        tabla: 'tbl_factura_app',
        registroIde: facturaIde,
      );

  Future<void> crearCompra(
          UserModel user, int compraIde, String compraNum, double total) =>
      registrar(
        user: user,
        accion: 'CREAR',
        modulo: 'COMPRA',
        descripcion: 'Compra: $compraNum — Total: $total',
        tabla: 'tbl_compra_app',
        registroIde: compraIde,
      );

  Future<void> confirmarCompra(
          UserModel user, int compraIde, String compraNum) =>
      registrar(
        user: user,
        accion: 'CONFIRMAR',
        modulo: 'COMPRA',
        descripcion: 'Compra confirmada (inventario actualizado): $compraNum',
        tabla: 'tbl_compra_app',
        registroIde: compraIde,
      );

  Future<void> aplicarAjuste(
          UserModel user, int ajusteIde, String ajusteNum, String razon) =>
      registrar(
        user: user,
        accion: 'APLICAR',
        modulo: 'AJUSTE',
        descripcion: 'Ajuste aplicado: $ajusteNum — Razón: $razon',
        tabla: 'tbl_ajuste_app',
        registroIde: ajusteIde,
      );

  Future<void> crearProducto(
          UserModel user, int productoIde, String descripcion) =>
      registrar(
        user: user,
        accion: 'CREAR',
        modulo: 'PRODUCTO',
        descripcion: 'Producto creado: $descripcion',
        tabla: 'tbl_producto',
        registroIde: productoIde,
      );

  Future<void> editarProducto(
          UserModel user, int productoIde, String descripcion) =>
      registrar(
        user: user,
        accion: 'EDITAR',
        modulo: 'PRODUCTO',
        descripcion: 'Producto editado: $descripcion',
        tabla: 'tbl_producto',
        registroIde: productoIde,
      );

  Future<void> eliminarProducto(
          UserModel user, int productoIde, String descripcion) =>
      registrar(
        user: user,
        accion: 'ELIMINAR',
        modulo: 'PRODUCTO',
        descripcion: 'Producto eliminado: $descripcion',
        tabla: 'tbl_producto',
        registroIde: productoIde,
      );

  Future<void> crearCliente(UserModel user, int clienIde, String nombre) =>
      registrar(
        user: user,
        accion: 'CREAR',
        modulo: 'CLIENTE',
        descripcion: 'Cliente creado: $nombre',
        tabla: 'tbl_cliente',
        registroIde: clienIde,
      );

  Future<void> editarCliente(UserModel user, int clienIde, String nombre) =>
      registrar(
        user: user,
        accion: 'EDITAR',
        modulo: 'CLIENTE',
        descripcion: 'Cliente editado: $nombre',
        tabla: 'tbl_cliente',
        registroIde: clienIde,
      );

  Future<void> eliminarCliente(UserModel user, int clienIde, String nombre) =>
      registrar(
        user: user,
        accion: 'ELIMINAR',
        modulo: 'CLIENTE',
        descripcion: 'Cliente eliminado: $nombre',
        tabla: 'tbl_cliente',
        registroIde: clienIde,
      );

  Future<void> exportarReporte(UserModel user, String tipoReporte) => registrar(
        user: user,
        accion: 'EXPORTAR',
        modulo: 'REPORTE',
        descripcion: 'PDF generado: $tipoReporte',
      );

  // ── Listar para la pantalla ──────────────────────────────
  Future<Map<String, dynamic>> listar({
    required int usuaIde,
    String modulo = '',
    required String fechaDesde,
    required String fechaHasta,
    String busqueda = '',
    String resultado = '',
  }) =>
      _post({
        'accion': 'listar',
        'usua_ide': usuaIde,
        'modulo': modulo,
        'fecha_desde': fechaDesde,
        'fecha_hasta': fechaHasta,
        'busqueda': busqueda,
        'resultado': resultado,
      });
  Future<Map<String, dynamic>> eliminar({
    required int usuaIde,
    required String criterio,
    String? fechaDesde,
    String? fechaHasta,
    String? modulo,
  }) =>
      _post({
        'accion': 'eliminar',
        'usua_ide': usuaIde,
        'criterio': criterio,
        if (fechaDesde != null) 'fecha_desde': fechaDesde,
        if (fechaHasta != null) 'fecha_hasta': fechaHasta,
        if (modulo != null) 'modulo': modulo,
      });
}
