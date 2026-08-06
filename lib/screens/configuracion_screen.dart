import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/venta_service.dart';
import '../services/tasa_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_config.dart';
import '../utils/app_info.dart';
//import '../utils/formato_numero.dart';

class ConfiguracionScreen extends StatefulWidget {
  final UserModel user;
  const ConfiguracionScreen({super.key, required this.user});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _ventaService = VentaService();
  final _tasaService = TasaService();

  bool _isLoading = true;
  Map _empresa = {};
  String _errorMsg = '';

  // Tasas
  Map _tasa = {};
  bool _cargandoBcv = false;
  bool _editandoTasa = false;

  final _bcvCtrl = TextEditingController();
  final _paralelaCtrl = TextEditingController();
  final _euroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarInfo();
  }

  @override
  void dispose() {
    _bcvCtrl.dispose();
    _paralelaCtrl.dispose();
    _euroCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarInfo() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      // Empresa
      final resultEmpresa = await _ventaService.obtenerEmpresa();
      if (resultEmpresa['success'] == true) {
        setState(() => _empresa = resultEmpresa['empresa'] ?? {});
      } else {
        setState(
            () => _errorMsg = resultEmpresa['message'] ?? 'Error al conectar');
      }

      // Tasa actual
      final resultTasa = await _tasaService.obtener();
      if (resultTasa['success'] == true) {
        final t = resultTasa['tasa'];
        setState(() {
          _tasa = t;
          _bcvCtrl.text = t['tasa_bcv']?.toString() ?? '0';
          _paralelaCtrl.text = t['tasa_paralela']?.toString() ?? '0';
          _euroCtrl.text = t['tasa_euro']?.toString() ?? '0';
        });
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _actualizarDesdeBcv() async {
    setState(() => _cargandoBcv = true);

    final result = await _tasaService.obtenerDesdeBcv(widget.user.usuaIde);

    if (result['success'] == true) {
      setState(() {
        _bcvCtrl.text = result['bcv'].toString();
        _paralelaCtrl.text = result['paralela'].toString();
        _euroCtrl.text = result['euro'].toString();
      });
      // Guardar automáticamente
      await _tasaService.guardar(
        usuaIde: widget.user.usuaIde,
        bcv: double.tryParse(result['bcv'].toString()) ?? 0,
        paralela: double.tryParse(result['paralela'].toString()) ?? 0,
        euro: double.tryParse(result['euro'].toString()) ?? 0,
        fuente: result['fuente'] ?? 'BCV-API',
        fecha: result['fecha'],
        hora: result['hora'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tasas actualizadas desde BCV'),
            backgroundColor: AppColors.success,
          ),
        );
        _cargarInfo();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al obtener tasas'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _cargandoBcv = false);
  }

  Future<void> _guardarTasaManual() async {
    final bcv = double.tryParse(_bcvCtrl.text) ?? 0;
    final paralela = double.tryParse(_paralelaCtrl.text) ?? 0;
    final euro = double.tryParse(_euroCtrl.text) ?? 0;

    final result = await _tasaService.guardar(
      usuaIde: widget.user.usuaIde,
      bcv: bcv,
      paralela: paralela,
      euro: euro,
      fuente: 'Manual',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );
      if (result['success'] == true) {
        setState(() => _editandoTasa = false);
        _cargarInfo();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

                  // ── Aplicación ─────────────────────────
                  _seccion('APLICACIÓN'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(Icons.apps, 'Nombre', AppInfo.nombre,
                        AppColors.primary),
                    _fila(Icons.tag, 'Versión', AppInfo.versionCompleta,
                        AppColors.textPrimary),
                    _fila(Icons.fingerprint, 'Cliente ID', AppConfig.clienteId,
                        AppColors.info,
                        negrita: true),
                  ]),

                  const SizedBox(height: 16),

                  // ── Conexión ───────────────────────────
                  _seccion('CONEXIÓN'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(Icons.dns_outlined, 'Servidor', AppConfig.baseUrl,
                        AppColors.textPrimary),
                    _fila(Icons.folder_outlined, 'Backend',
                        AppConfig.backendUrl, AppColors.textSecondary),
                    _fila(
                      AppConfig.esLocal ? Icons.computer : Icons.cloud_outlined,
                      'Entorno',
                      AppConfig.nombreEntorno,
                      AppConfig.esLocal ? AppColors.warning : AppColors.success,
                      negrita: true,
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Base de datos ──────────────────────
                  _seccion('BASE DE DATOS'),
                  const SizedBox(height: 8),

                  _errorMsg.isNotEmpty
                      ? Container(
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
                        )
                      : _bloque([
                          _fila(
                            Icons.storage_outlined,
                            'Conectado a',
                            AppConfig.clienteId.toUpperCase(),
                            AppColors.primary,
                            negrita: true,
                          ),
                          _fila(
                            Icons.dataset_outlined,
                            'Base de datos',
                            _empresa['db_nombre']?.toString() ?? '-',
                            AppColors.info,
                            negrita: true,
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

                  // ── Tasas de cambio ────────────────────
                  _seccion('TASAS DE CAMBIO'),
                  const SizedBox(height: 8),

                  // Banner fecha actualización
                  if (_tasa.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.update,
                              color: AppColors.primary, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Actualizado: ${_tasa['tasa_fecha'] ?? '-'}'
                              '  ${_tasa['tasa_hora'] ?? ''}'
                              '  Fuente: ${_tasa['tasa_fuente'] ?? '-'}',
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Tarjetas de tasas
                  Row(
                    children: [
                      _tarjetaTasa('BCV', 'Bs/USD', _tasa['tasa_bcv'],
                          AppColors.primary),
                      const SizedBox(width: 8),
                      _tarjetaTasa('Paralela', 'Bs/USD', _tasa['tasa_paralela'],
                          AppColors.warning),
                      const SizedBox(width: 8),
                      _tarjetaTasa(
                          'Euro', 'Bs/EUR', _tasa['tasa_euro'], AppColors.info),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Botón actualizar desde BCV
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _cargandoBcv ? null : _actualizarDesdeBcv,
                      icon: _cargandoBcv
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.sync, size: 18),
                      label: Text(
                        _cargandoBcv
                            ? 'Consultando BCV...'
                            : 'Actualizar desde BCV',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Edición manual
                  if (_editandoTasa) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EDITAR MANUALMENTE',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _campoTasa(_bcvCtrl, 'Tasa BCV (Bs/USD)'),
                          const SizedBox(height: 8),
                          _campoTasa(_paralelaCtrl, 'Tasa Paralela (Bs/USD)'),
                          const SizedBox(height: 8),
                          _campoTasa(_euroCtrl, 'Tasa Euro (Bs/EUR)'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _editandoTasa = false),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _guardarTasaManual,
                                  icon: const Icon(Icons.save, size: 16),
                                  label: const Text('Guardar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _editandoTasa = true),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar manualmente'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Usuario activo ─────────────────────
                  _seccion('USUARIO ACTIVO'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(Icons.person_outline, 'Nombre',
                        widget.user.nombreCompleto, AppColors.textPrimary),
                    _fila(Icons.login, 'Login', widget.user.login,
                        AppColors.textSecondary),
                    _fila(Icons.admin_panel_settings_outlined, 'Tipo',
                        _labelTius(widget.user.tius), AppColors.primary,
                        negrita: true),
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

  Widget _tarjetaTasa(
      String titulo, String moneda, dynamic valor, Color color) {
    final num = double.tryParse(valor?.toString() ?? '0') ?? 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(moneda,
                style: const TextStyle(color: AppColors.textHint, fontSize: 9)),
            const SizedBox(height: 4),
            Text(
              num > 0 ? num.toStringAsFixed(2) : '--',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoTasa(TextEditingController ctrl, String label) => TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.monetization_on_outlined, size: 18),
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
