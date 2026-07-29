import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/app_config.dart';
import 'auditoria_service.dart';
import 'bcv_service.dart';

final _auditoria = AuditoriaService();

class AuthService {
  Future<Map<String, dynamic>> login(String login, String clave) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.api('api_login.php')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'login': login.trim(),
              'clave': clave.trim(),
              'cliente_id': AppConfig.clienteId, // ← inyectado
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final user = UserModel.fromJson(data, login);
          await _guardarSesion(user);
          await _auditoria.login(user);
          BcvService().actualizarTasaDiaria().then((_) {}).catchError((_) {});
          return {'success': true, 'user': user};
        }
        await _auditoria.loginFallido(login);
        return {'success': false, 'message': data['message']};
      }
      await _auditoria.loginFallido(login);
      return {'success': false, 'message': 'Error del servidor'};
    } catch (e) {
      await _auditoria.loginFallido(login);
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<void> _guardarSesion(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_ide', user.usuaIde);
    await prefs.setString('user_nombre', user.nombre);
    await prefs.setString('user_apellido', user.apellido);
    await prefs.setString('user_login', user.login);
    await prefs.setString('user_numiden', user.numiden);
    await prefs.setInt('user_tius', user.tius);
    await prefs.setBool('is_logged_in', true);
    // Guardar cliente activo en sesión
    await prefs.setString('cliente_id', AppConfig.clienteId);
  }

  Future<UserModel?> getSesionActiva() async {
    final prefs = await SharedPreferences.getInstance();

    // Verificar que la sesión corresponde al cliente activo
    final clienteGuardado = prefs.getString('cliente_id') ?? '';
    if (clienteGuardado != AppConfig.clienteId) {
      // Sesión de otro cliente — cerrar automáticamente
      await prefs.clear();
      return null;
    }

    if (prefs.getBool('is_logged_in') ?? false) {
      return UserModel(
        usuaIde: prefs.getInt('user_ide') ?? 0,
        nombre: prefs.getString('user_nombre') ?? '',
        apellido: prefs.getString('user_apellido') ?? '',
        login: prefs.getString('user_login') ?? '',
        numiden: prefs.getString('user_numiden') ?? '',
        tius: prefs.getInt('user_tius') ?? 0,
      );
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await getSesionActiva();
    if (user != null) {
      await _auditoria.logout(user);
    }
    await prefs.clear();
  }
}
