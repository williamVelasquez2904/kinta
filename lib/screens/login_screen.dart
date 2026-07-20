import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../utils/app_info.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _authService = AuthService();
  final _ingresarFocusNode = FocusNode();

  bool _isLoading = false;
  bool _ocultarClave = true;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _claveCtrl.dispose();
    _ingresarFocusNode.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _authService.login(
      _loginCtrl.text,
      _claveCtrl.text,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'] as UserModel;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${user.nombreCompleto}!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error desconocido'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Row(
              children: [
                // ── Panel izquierdo (solo en pantallas anchas) ──
                if (size.width > 700)
                  Expanded(
                    child: Container(
                      height: size.height,
                      color: AppColors.primary,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.eco,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppInfo.nombre,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gestión comercial',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Decoración
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                _featureItem(Icons.people_alt_outlined,
                                    'Gestión de clientes'),
                                const SizedBox(height: 16),
                                _featureItem(Icons.receipt_long_outlined,
                                    'Control de pagos'),
                                const SizedBox(height: 16),
                                _featureItem(Icons.trending_up_outlined,
                                    'Seguimiento de saldos'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            AppInfo.versionCompleta,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Panel derecho — Formulario ──────────────────
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 48),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo móvil (solo pantallas angostas)
                          if (size.width <= 700) ...[
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBg,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.eco,
                                      color: AppColors.primary,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppInfo.nombre,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Título
                          const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ingresa tus credenciales para continuar',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Campo Usuario
                          const Text(
                            'Usuario',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _loginCtrl,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Tu usuario',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingresa tu usuario';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Campo Contraseña
                          const Text(
                            'Contraseña',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _claveCtrl,
                            obscureText: _ocultarClave,
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Tu contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _ocultarClave
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textHint,
                                ),
                                onPressed: () => setState(
                                    () => _ocultarClave = !_ocultarClave),
                              ),
                            ),
                            onFieldSubmitted: (_) {
                              if (!_isLoading) {
                                _iniciarSesion();
                              }
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              if (v.length < 4) {
                                return 'Mínimo 4 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Botón Ingresar
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              focusNode: _ingresarFocusNode,
                              onPressed: _isLoading ? null : _iniciarSesion,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Ingresar',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Footer
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '${AppInfo.nombre} © ${DateTime.now().year}',
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppInfo.versionCompleta,
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureItem(IconData icono, String texto) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          texto,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
