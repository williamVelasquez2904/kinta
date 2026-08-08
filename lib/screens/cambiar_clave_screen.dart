import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CambiarClaveScreen extends StatefulWidget {
  final UserModel user;
  const CambiarClaveScreen({super.key, required this.user});

  @override
  State<CambiarClaveScreen> createState() => _CambiarClaveScreenState();
}

class _CambiarClaveScreenState extends State<CambiarClaveScreen> {
  final _service = AuthService();
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _verActual = false;
  bool _verNueva = false;
  bool _verConfirm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Indicador de fortaleza de clave ─────────────────────
  int _fortaleza(String clave) {
    if (clave.isEmpty) return 0;
    int score = 0;
    if (clave.length >= 6) score++;
    if (clave.length >= 10) score++;
    if (clave.contains(RegExp(r'[A-Z]'))) score++;
    if (clave.contains(RegExp(r'[0-9]'))) score++;
    if (clave.contains(RegExp(r'[!@#\$%^&*(),.?]'))) score++;
    return score;
  }

  String _labelFortaleza(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Muy débil';
      case 2:
        return 'Débil';
      case 3:
        return 'Regular';
      case 4:
        return 'Fuerte';
      case 5:
        return 'Muy fuerte';
      default:
        return '';
    }
  }

  Color _colorFortaleza(int score) {
    switch (score) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      case 4:
      case 5:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

  Future<void> _cambiarClave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _service.cambiarClave(
      usuaIde: widget.user.usuaIde,
      claveActual: _actualCtrl.text,
      claveNueva: _nuevaCtrl.text,
      claveConfirm: _confirmCtrl.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // Limpiar campos
      _actualCtrl.clear();
      _nuevaCtrl.clear();
      _confirmCtrl.clear();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 24),
              SizedBox(width: 8),
              Text('Clave actualizada'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['message'] ?? 'Tu clave fue actualizada correctamente.',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Usa tu nueva clave la próxima vez que inicies sesión.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // cierra diálogo
                Navigator.pop(context); // regresa a la pantalla anterior
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al cambiar clave'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fortaleza = _fortaleza(_nuevaCtrl.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Clave'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Banner usuario ─────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person,
                          color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.nombreCompleto,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '@${widget.user.login}',
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Clave actual ───────────────────────────
              _seccion('CLAVE ACTUAL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _actualCtrl,
                obscureText: !_verActual,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Clave actual',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _verActual ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _verActual = !_verActual),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Ingresa tu clave actual';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ── Nueva clave ────────────────────────────
              _seccion('NUEVA CLAVE'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nuevaCtrl,
                obscureText: !_verNueva,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nueva clave',
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _verNueva ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _verNueva = !_verNueva),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Ingresa la nueva clave';
                  }
                  if (v.length < 4) {
                    return 'Mínimo 4 caracteres';
                  }
                  if (v == _actualCtrl.text) {
                    return 'Debe ser diferente a la clave actual';
                  }
                  return null;
                },
              ),

              // Indicador de fortaleza
              if (_nuevaCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fortaleza / 5,
                          backgroundColor: AppColors.border,
                          color: _colorFortaleza(fortaleza),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _labelFortaleza(fortaleza),
                      style: TextStyle(
                        color: _colorFortaleza(fortaleza),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Usa mayúsculas, números y símbolos para mayor seguridad',
                  style: TextStyle(color: AppColors.textHint, fontSize: 10),
                ),
              ],

              const SizedBox(height: 16),

              // ── Confirmar clave ────────────────────────
              _seccion('CONFIRMAR NUEVA CLAVE'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: !_verConfirm,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirmar nueva clave',
                  prefixIcon: const Icon(Icons.lock_reset_outlined, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _verConfirm ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _verConfirm = !_verConfirm),
                  ),
                  // Indicador visual de coincidencia
                  suffixIconColor: _confirmCtrl.text.isNotEmpty
                      ? (_confirmCtrl.text == _nuevaCtrl.text
                          ? AppColors.success
                          : AppColors.error)
                      : AppColors.textHint,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Confirma la nueva clave';
                  }
                  if (v != _nuevaCtrl.text) {
                    return 'Las claves no coinciden';
                  }
                  return null;
                },
              ),

              // Badge de coincidencia
              if (_confirmCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _confirmCtrl.text == _nuevaCtrl.text
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 14,
                      color: _confirmCtrl.text == _nuevaCtrl.text
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _confirmCtrl.text == _nuevaCtrl.text
                          ? 'Las claves coinciden'
                          : 'Las claves no coinciden',
                      style: TextStyle(
                        color: _confirmCtrl.text == _nuevaCtrl.text
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // ── Botón ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _cambiarClave,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.lock_reset),
                  label: Text(
                    _isLoading ? 'Actualizando...' : 'Actualizar Clave',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Nota de seguridad ──────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.textHint, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Solo puedes cambiar tu propia clave. '
                        'Después de cambiarla, úsala en tu próximo ingreso.',
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(String t) => Text(t,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ));
}
