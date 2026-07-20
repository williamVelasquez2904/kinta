import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_config.dart';
import '../utils/app_info.dart';

class ConfiguracionScreen extends StatefulWidget {
  final UserModel user;
  const ConfiguracionScreen({super.key, required this.user});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _ventaService = VentaService();

  bool _isLoading = true;
  Map _empresa = {};
  String _errorMsg = '';
  String _dbNombre = AppConfig.clienteId;
  String _dbHost = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _cargarInfo();
  }

  Future<void> _cargarInfo() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
      _dbNombre = AppConfig.clienteId;
      _dbHost = AppConfig.baseUrl;
    });

    try {
      final result = await _ventaService.obtenerEmpresa();
      if (result['success'] == true) {
        final empresa = result['empresa'] ?? {};
        final dbNombre = result['empresa_db'] ??
            result['db_nombre'] ??
            result['bd_nombre'] ??
            AppConfig.clienteId;
        final dbHost = result['empresa_host'] ??
            result['db_host'] ??
            result['host'] ??
            AppConfig.baseUrl;

        setState(() {
          _empresa = empresa;
          _dbNombre = dbNombre.toString();
          _dbHost = dbHost.toString();
        });
      } else {
        setState(() => _errorMsg = result['message'] ?? 'Error al conectar');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Solo tius == 1 (Admin Sistema)
    if (widget.user.tius != 1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuración')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: AppColors.error, size: 52),
              SizedBox(height: 12),
              Text(
                'Solo el Administrador del Sistema\npuede acceder a esta sección',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Banner entorno ─────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConfig.esLocal
                          ? AppColors.warningBg
                          : AppColors.successBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppConfig.esLocal
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppConfig.esLocal
                              ? Icons.computer
                              : Icons.cloud_done_outlined,
                          color: AppConfig.esLocal
                              ? AppColors.warning
                              : AppColors.success,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConfig.esLocal
                                    ? 'ENTORNO LOCAL'
                                    : 'ENTORNO PRODUCCIÓN',
                                style: TextStyle(
                                  color: AppConfig.esLocal
                                      ? AppColors.warning
                                      : AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                AppConfig.baseUrl,
                                style: TextStyle(
                                  color: AppConfig.esLocal
                                      ? AppColors.warning
                                      : AppColors.success,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── App ────────────────────────────────
                  _seccion('APLICACIÓN'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(
                      Icons.apps,
                      'Nombre',
                      AppInfo.nombre,
                      AppColors.primary,
                    ),
                    _fila(
                      Icons.tag,
                      'Versión',
                      AppInfo.versionCompleta,
                      AppColors.textPrimary,
                    ),
                    _fila(
                      Icons.fingerprint,
                      'Cliente ID',
                      AppConfig.clienteId,
                      AppColors.info,
                      negrita: true,
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Conexión ───────────────────────────
                  _seccion('CONEXIÓN'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(
                      Icons.dns_outlined,
                      'Servidor',
                      AppConfig.baseUrl,
                      AppColors.textPrimary,
                    ),
                    _fila(
                      Icons.folder_outlined,
                      'Backend',
                      AppConfig.backendUrl,
                      AppColors.textSecondary,
                    ),
                    _fila(
                      AppConfig.esLocal ? Icons.computer : Icons.cloud_outlined,
                      'Entorno',
                      AppConfig.nombreEntorno,
                      AppConfig.esLocal ? AppColors.warning : AppColors.success,
                      negrita: true,
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Base de datos ─────────────────────
                  _seccion('BASE DE DATOS'),
                  const SizedBox(height: 8),

                  if (_errorMsg.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMsg,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _bloque([
                    _fila(
                      Icons.storage_outlined,
                      'Base de datos',
                      _dbNombre.toUpperCase(),
                      AppColors.primary,
                      negrita: true,
                    ),
                    _fila(
                      Icons.dns_outlined,
                      'Servidor BD',
                      _dbHost,
                      AppColors.textPrimary,
                    ),
                    _fila(
                      Icons.business_outlined,
                      'Empresa',
                      _empresa['empresa_nombre']?.toString() ?? '-',
                      AppColors.textPrimary,
                    ),
                          _fila(
                            Icons.badge_outlined,
                            'RIF',
                            _empresa['empresa_rif']?.toString() ?? '-',
                            AppColors.textSecondary,
                          ),
                          _fila(
                            Icons.phone_outlined,
                            'Teléfono',
                            _empresa['empresa_telefono']?.toString() ?? '-',
                            AppColors.textSecondary,
                          ),
                          _fila(
                            Icons.email_outlined,
                            'Email',
                            _empresa['empresa_email']?.toString() ?? '-',
                            AppColors.textSecondary,
                          ),
                          _filaEstado(
                            Icons.check_circle_outline,
                            'Estado conexión',
                            'Conectado correctamente',
                            AppColors.success,
                          ),
                        ]),

                  const SizedBox(height: 16),

                  // ── Usuario ────────────────────────────
                  _seccion('USUARIO ACTIVO'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(
                      Icons.person_outline,
                      'Nombre',
                      widget.user.nombreCompleto,
                      AppColors.textPrimary,
                    ),
                    _fila(
                      Icons.login,
                      'Login',
                      widget.user.login,
                      AppColors.textSecondary,
                    ),
                    _fila(
                      Icons.admin_panel_settings_outlined,
                      'Tipo',
                      _labelTius(widget.user.tius),
                      AppColors.primary,
                      negrita: true,
                    ),
                  ]),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ── Widgets auxiliares ─────────────────────────────────

  Widget _seccion(String titulo) => Text(
        titulo,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );

  Widget _bloque(List<Widget> hijos) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: hijos),
      );

  Widget _fila(
    IconData icono,
    String label,
    String valor,
    Color color, {
    bool negrita = false,
  }) =>
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icono, color: AppColors.textHint, size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    valor,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 42),
        ],
      );

  Widget _filaEstado(
    IconData icono,
    String label,
    String valor,
    Color color,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icono, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: color, size: 8),
                  const SizedBox(width: 4),
                  Text(
                    valor,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  String _labelTius(int tius) {
    switch (tius) {
      case 1:
        return 'Administrador del Sistema';
      case 2:
        return 'Asistente';
      case 3:
        return 'Administrador de Tienda';
      case 4:
        return 'Vendedor';
      case 5:
        return 'Vendedor Detal';
      default:
        return 'Desconocido';
    }
  }
}
