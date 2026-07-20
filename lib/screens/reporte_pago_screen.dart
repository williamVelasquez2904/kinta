import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import '../utils/app_config.dart';

class ReportePagoScreen extends StatefulWidget {
  final UserModel user;
  final int clienteIde;
  final String clienteNombre;
  final double saldoCliente;

  const ReportePagoScreen({
    super.key,
    required this.user,
    required this.clienteIde,
    required this.clienteNombre,
    required this.saldoCliente,
  });

  @override
  State<ReportePagoScreen> createState() => _ReportePagoScreenState();
}

class _ReportePagoScreenState extends State<ReportePagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _titularCtrl = TextEditingController();
  final _tasaCtrl = TextEditingController();
  final _comentarioCtrl = TextEditingController();

  final SignatureController _firmaCtrl = SignatureController(
    penStrokeWidth: 2,
    penColor: AppColors.glow,
    exportBackgroundColor: AppColors.surface,
  );

  bool _isLoading = false;
  bool _cargandoCuentas = true;
  XFile? _imagenSoporte;
  List _cuentas = [];
  Map? _cuentaSeleccionada;
  DateTime _fechaPago = DateTime.now();

  // Moneda USD = 1 → no requiere tasa
  bool get _requiereTasa =>
      _cuentaSeleccionada != null &&
      _cuentaSeleccionada!['cuenta_moneda_ide'] != 1;

  String get _monedaLabel => _cuentaSeleccionada?['moneda_abreviada'] ?? '';

  @override
  void initState() {
    super.initState();
    _cargarCuentas();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _referenciaCtrl.dispose();
    _titularCtrl.dispose();
    _tasaCtrl.dispose();
    _comentarioCtrl.dispose();
    _firmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCuentas() async {
    try {
      final response = await http
          .get(
            Uri.parse(AppConfig.api('api_cuentas.php')),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _cuentas = data['cuentas'];
            _cargandoCuentas = false;
          });
        }
      }
    } catch (e) {
      setState(() => _cargandoCuentas = false);
      debugPrint('Error cargando cuentas: $e');
    }
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (imagen != null) setState(() => _imagenSoporte = imagen);
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaPago,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.surface,
          ),
        ),
        child: child!,
      ),
      /*
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.glow,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),*/
    );
    if (fecha != null) setState(() => _fechaPago = fecha);
  }

  Future<void> _guardarPago() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cuentaSeleccionada == null) {
      _mostrarError('Selecciona una cuenta de destino');
      return;
    }

    if (_firmaCtrl.isEmpty) {
      _mostrarError('Capture la firma del cliente');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Imagen soporte → base64
      String? soporteBase64;
      if (_imagenSoporte != null) {
        final bytes = await File(_imagenSoporte!.path).readAsBytes();
        soporteBase64 = base64Encode(bytes);
      }

      // Firma → base64
      String? firmaBase64;
      final Uint8List? firmaBytes = await _firmaCtrl.toPngBytes();
      if (firmaBytes != null) {
        firmaBase64 = base64Encode(firmaBytes);
      }

      final response = await http
          .post(
            Uri.parse(AppConfig.api('api_guardar_pago.php')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pago_cuenta_ide': _cuentaSeleccionada!['cuenta_ide'],
              'pago_cliente_ide': widget.clienteIde,
              'pago_fecha_pago': _fechaPago.toIso8601String(),
              'pago_titular_cuenta_origen': _titularCtrl.text.trim(),
              'pago_monto': double.tryParse(_montoCtrl.text) ?? 0,
              'pago_referencia': _referenciaCtrl.text.trim(),
              'pago_tasa':
                  _requiereTasa ? (double.tryParse(_tasaCtrl.text) ?? 0) : 0,
              'pago_comentario': _comentarioCtrl.text.trim(),
              'soporte_base64': soporteBase64,
              'firma_base64': firmaBase64,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Pago registrado exitosamente!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          _mostrarError(data['message']);
        }
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Pago'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info cliente ───────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cliente',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 12)),
                          Text(widget.clienteNombre,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Saldo deudor',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 12)),
                        Text(
                          FormatoNumero.monedaConSimbolo(widget.saldoCliente),
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _seccion('DATOS DEL PAGO'),
              const SizedBox(height: 12),

              // ── Selector de cuenta ─────────────────────
              _cargandoCuentas
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.glow))
                  : DropdownButtonFormField<Map>(
                      value: _cuentaSeleccionada,
                      dropdownColor: AppColors.surface,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Cuenta destino',
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      hint: const Text('Selecciona una cuenta',
                          style: TextStyle(color: AppColors.textHint)),
                      items: _cuentas
                          .map<DropdownMenuItem<Map>>((c) =>
                              DropdownMenuItem<Map>(
                                value: c,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      c['cuenta_descripcion'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${c['cuenta_cuenta'] ?? ''} · ${c['moneda_abreviada'] ?? ''}',
                                      style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _cuentaSeleccionada = v;
                          _tasaCtrl.clear();
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Selecciona una cuenta' : null,
                    ),

              // ── Badge moneda seleccionada ──────────────
              if (_cuentaSeleccionada != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _requiereTasa
                            ? AppColors.warning.withOpacity(0.2)
                            : AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _requiereTasa
                            ? '⚠ Requiere tasa de cambio ($_monedaLabel)'
                            : '✓ Moneda USD — sin tasa',
                        style: TextStyle(
                          color: _requiereTasa
                              ? AppColors.warning
                              : AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // ── Fecha de pago ──────────────────────────
              GestureDetector(
                onTap: _seleccionarFecha,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      const Text('Fecha de pago: ',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 13)),
                      Text(
                        '${_fechaPago.day.toString().padLeft(2, '0')}/'
                        '${_fechaPago.month.toString().padLeft(2, '0')}/'
                        '${_fechaPago.year}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar,
                          color: AppColors.glow, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Monto ──────────────────────────────────
              TextFormField(
                controller: _montoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Monto del pago',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: _monedaLabel,
                  suffixStyle: const TextStyle(
                      color: AppColors.glow, fontWeight: FontWeight.bold),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el monto';
                  if (double.tryParse(v) == null) return 'Monto inválido';
                  if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),

              // ── Tasa (solo si moneda != USD) ───────────
              if (_requiereTasa) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tasaCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Tasa de cambio ($_monedaLabel / USD)',
                    prefixIcon: const Icon(Icons.currency_exchange),
                    filled: true,
                    fillColor: AppColors.warning.withOpacity(0.08),
                  ),
                  validator: (v) {
                    if (!_requiereTasa) return null;
                    if (v == null || v.isEmpty) return 'Ingresa la tasa';
                    if (double.tryParse(v) == null) return 'Tasa inválida';
                    if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 12),

              // ── Referencia ─────────────────────────────
              TextFormField(
                controller: _referenciaCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Referencia / Confirmación',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),

              const SizedBox(height: 12),

              // ── Titular ────────────────────────────────
              TextFormField(
                controller: _titularCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Titular cuenta origen',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 12),

              // ── Comentario ─────────────────────────────
              TextFormField(
                controller: _comentarioCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  prefixIcon: Icon(Icons.comment_outlined),
                ),
              ),

              const SizedBox(height: 20),
              _seccion('SOPORTE DE PAGO'),
              const SizedBox(height: 12),

              // ── Botones imagen ─────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _botonImagen(
                      icono: Icons.camera_alt,
                      texto: 'Tomar foto',
                      onTap: () => _seleccionarImagen(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _botonImagen(
                      icono: Icons.photo_library,
                      texto: 'Galería',
                      onTap: () => _seleccionarImagen(ImageSource.gallery),
                    ),
                  ),
                ],
              ),

              if (_imagenSoporte != null) ...[
                const SizedBox(height: 10),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_imagenSoporte!.path),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _imagenSoporte = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Center(
                  child: Text('Sin imagen adjunta',
                      style:
                          TextStyle(color: AppColors.textHint, fontSize: 12)),
                ),
              ],

              const SizedBox(height: 20),
              _seccion('FIRMA DEL CLIENTE'),
              const SizedBox(height: 12),

              // ── Canvas firma ───────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glow, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Signature(
                    controller: _firmaCtrl,
                    height: 180,
                    backgroundColor: AppColors.surface,
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _firmaCtrl.clear(),
                  icon: const Icon(Icons.refresh,
                      color: AppColors.textSecondary, size: 18),
                  label: const Text('Limpiar firma',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ),
              ),

              const SizedBox(height: 24),

              // ── Botón guardar ──────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _guardarPago,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'Guardando...' : 'REGISTRAR PAGO',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo) {
    return Row(
      children: [
        Text(titulo,
            style: const TextStyle(
              color: AppColors.glow,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            )),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  Widget _botonImagen({
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icono, color: AppColors.glow, size: 28),
            const SizedBox(height: 6),
            Text(texto,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
