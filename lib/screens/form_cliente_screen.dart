import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/cliente_service.dart';
import '../theme/app_theme.dart';

class FormClienteScreen extends StatefulWidget {
  final UserModel user;
  final int? clienIde;

  const FormClienteScreen({
    super.key,
    required this.user,
    this.clienIde,
  });

  @override
  State<FormClienteScreen> createState() => _FormClienteScreenState();
}

class _FormClienteScreenState extends State<FormClienteScreen> {
  final _service = ClienteService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _cargando = true;

  // Listas
  List _tipclis = [];
  List _vendedores = [];

  // Seleccionados
  String _tipcli = 'V';
  int? _vendedor;
  String _empresaEnvio = 'Delivery';
  bool _contriespec = false;

  // Fecha nacimiento
  DateTime _fechaNaci = DateTime(2000, 1, 1);

  // Controladores
  final _codigoCtrl = TextEditingController();
  final _nuidenCtrl = TextEditingController();
  final _nombre1Ctrl = TextEditingController();
  final _nombre2Ctrl = TextEditingController();
  final _apelli1Ctrl = TextEditingController();
  final _apelli2Ctrl = TextEditingController();
  final _direcciCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _paisCtrl = TextEditingController();
  final _telmoviCtrl = TextEditingController();
  final _telmovi2Ctrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _codigoOficinaCtrl = TextEditingController();
  final _nombreOficinaCtrl = TextEditingController();

  bool get _esEdicion => widget.clienIde != null;

  final List<Map<String, String>> _empresasEnvio = [
    {'valor': 'Delivery', 'label': 'Delivery'},
    {'valor': 'MRW', 'label': 'MRW'},
    {'valor': 'Zoom', 'label': 'Zoom'},
    {'valor': 'Tealca', 'label': 'Tealca'},
  ];

  // ── Valor seguro empresa envío ───────────────────────────
  String get _empresaEnvioValida {
    final existe = _empresasEnvio.any((e) => e['valor'] == _empresaEnvio);
    return existe ? _empresaEnvio : 'Delivery';
  }

  // ── Valor seguro vendedor ────────────────────────────────
  int? get _vendedorValido {
    if (_vendedores.isEmpty) return null;
    final existe = _vendedores
        .any((v) => int.tryParse(v['usua_ide'].toString()) == _vendedor);
    return existe ? _vendedor : null;
  }

  @override
  void initState() {
    super.initState();
    debugPrint('╔══ FormClienteScreen.initState ══╗');
    debugPrint('esEdicion: $_esEdicion');
    debugPrint('clienIde : ${widget.clienIde}');
    debugPrint('╚══════════════════════════════════╝');
    _inicializar();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nuidenCtrl.dispose();
    _nombre1Ctrl.dispose();
    _nombre2Ctrl.dispose();
    _apelli1Ctrl.dispose();
    _apelli2Ctrl.dispose();
    _direcciCtrl.dispose();
    _ciudadCtrl.dispose();
    _paisCtrl.dispose();
    _telmoviCtrl.dispose();
    _telmovi2Ctrl.dispose();
    _correoCtrl.dispose();
    _codigoOficinaCtrl.dispose();
    _nombreOficinaCtrl.dispose();
    super.dispose();
  }

  String _fechaSql(DateTime d) => '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _fechaDisplay(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  // ── Inicializar ─────────────────────────────────────────
  Future<void> _inicializar() async {
    setState(() => _cargando = true);
    debugPrint('── _inicializar() inicio ──');

    try {
      debugPrint('Cargando listas...');
      final listas = await _service.cargarListas();
      debugPrint('Resultado listas: $listas');

      if (listas['success'] == true) {
        setState(() {
          _tipclis = listas['tipclis'] ?? [];
          _vendedores = listas['vendedores'] ?? [];
        });
        debugPrint('tipclis   : ${_tipclis.length}');
        debugPrint('vendedores: ${_vendedores.length}');
        for (var v in _vendedores) {
          debugPrint('  vendedor ide=${v['usua_ide']} '
              '${v['usua_nombre']} ${v['usua_apelli']}');
        }
      } else {
        debugPrint('ERROR listas: ${listas['message']}');
      }

      if (_esEdicion) {
        debugPrint('Cargando detalle cliente ${widget.clienIde}...');

        final clienIdeInt = widget.clienIde ?? 0;
        if (clienIdeInt == 0) return;

        final result = await _service.detalle(
          clienIdeInt,
          usuaIde: widget.user.usuaIde,
        );
        debugPrint('Resultado detalle: $result');

        if (result['success'] == true) {
          final c = result['cliente'];
          debugPrint('Datos del cliente: $c');

          final vendedorDb = int.tryParse(c['clien_vendedor'].toString()) ?? 1;

          // Normalizar empresa envío
          final empresaDb =
              c['clien_empresa_envio']?.toString().trim() ?? 'Delivery';
          final empresaValida =
              _empresasEnvio.any((e) => e['valor'] == empresaDb)
                  ? empresaDb
                  : 'Delivery';

          debugPrint('empresaDb     : $empresaDb');
          debugPrint('empresaValida : $empresaValida');

          setState(() {
            _codigoCtrl.text = c['clien_codigo']?.toString() ?? '';
            _nuidenCtrl.text = c['clien_numiden']?.toString() ?? '';
            _nombre1Ctrl.text = c['clien_nombre1']?.toString() ?? '';
            _nombre2Ctrl.text = c['clien_nombre2']?.toString() ?? '';
            _apelli1Ctrl.text = c['clien_apelli1']?.toString() ?? '';
            _apelli2Ctrl.text = c['clien_apelli2']?.toString() ?? '';
            _direcciCtrl.text = c['clien_direcci']?.toString() ?? '';
            _ciudadCtrl.text = c['clien_ciudad']?.toString() ?? '';
            _paisCtrl.text = c['clien_pais']?.toString() ?? '';
            _telmoviCtrl.text = c['clien_telmovi']?.toString() ?? '';
            _telmovi2Ctrl.text = c['clien_telmovi2']?.toString() ?? '';
            _correoCtrl.text = c['clien_correo']?.toString() ?? '';
            _codigoOficinaCtrl.text =
                c['clien_codigo_oficina']?.toString() ?? '';
            _nombreOficinaCtrl.text =
                c['clien_nombre_oficina']?.toString() ?? '';

            _tipcli = c['clien_tipcli']?.toString() ?? 'V';
            _vendedor = vendedorDb;
            _empresaEnvio = empresaValida;
            _contriespec =
                (int.tryParse(c['clien_contriespec'].toString()) ?? 0) == 1;

            final fn = c['clien_fecnaci']?.toString() ?? '';
            if (fn.length >= 10) {
              _fechaNaci = DateTime.tryParse(fn) ?? DateTime(2000, 1, 1);
            }
          });

          debugPrint('Campos cargados:');
          debugPrint('  tipcli      : $_tipcli');
          debugPrint('  vendedor    : $_vendedor');
          debugPrint('  empresaEnvio: $_empresaEnvio');
          debugPrint('  contriespec : $_contriespec');
          debugPrint('  fechaNaci   : $_fechaNaci');
        } else {
          debugPrint('ERROR detalle: ${result['message']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Error al cargar'),
                backgroundColor: AppColors.error,
              ),
            );
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      debugPrint('EXCEPCIÓN en _inicializar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _cargando = false);
    debugPrint('── _inicializar() fin ──');
  }

  // ── Seleccionar fecha ────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaNaci,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (fecha != null && mounted) {
      setState(() => _fechaNaci = fecha);
      debugPrint('Fecha: ${_fechaSql(fecha)}');
    }
  }

  // ── Mostrar error en diálogo ─────────────────────────────
  void _mostrarErrorDialog(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Error del servidor', style: TextStyle(fontSize: 15)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Respuesta del servidor:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: SelectableText(
                  mensaje,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Copia el mensaje y revisa el PHP.',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ── Guardar ──────────────────────────────────────────────
  Future<void> _guardar() async {
    debugPrint('╔══ _guardar() ══╗');

    if (!_formKey.currentState!.validate()) {
      debugPrint('Formulario inválido');
      return;
    }

    setState(() => _isLoading = true);

    final datos = {
      'clien_codigo': _codigoCtrl.text.trim(),
      'clien_tipcli': _tipcli,
      'clien_numiden': _nuidenCtrl.text.trim(),
      'clien_nombre1': _nombre1Ctrl.text.trim(),
      'clien_nombre2': _nombre2Ctrl.text.trim(),
      'clien_apelli1': _apelli1Ctrl.text.trim(),
      'clien_apelli2': _apelli2Ctrl.text.trim(),
      'clien_fecnaci': _fechaSql(_fechaNaci),
      'clien_direcci': _direcciCtrl.text.trim(),
      'clien_ciudad': _ciudadCtrl.text.trim(),
      'clien_pais': _paisCtrl.text.trim(),
      'clien_telmovi': _telmoviCtrl.text.trim(),
      'clien_telmovi2': _telmovi2Ctrl.text.trim(),
      'clien_correo': _correoCtrl.text.trim(),
      'clien_contriespec': _contriespec ? 1 : 0,
      'clien_vendedor': _vendedor ?? 1,
      'clien_empresa_envio': _empresaEnvioValida,
      'clien_codigo_oficina': _codigoOficinaCtrl.text.trim(),
      'clien_nombre_oficina': _nombreOficinaCtrl.text.trim(),
    };

    debugPrint('Acción   : ${_esEdicion ? "editar" : "crear"}');
    debugPrint('clien_ide: ${widget.clienIde}');
    debugPrint('usua_ide : ${widget.user.usuaIde}');
    datos.forEach((k, v) => debugPrint('  $k = $v'));
    debugPrint('════════════════════════════════════════');

    try {
      Map<String, dynamic> result;

      if (_esEdicion) {
        result = await _service.editar(
          usuaIde: widget.user.usuaIde,
          clienIde: widget.clienIde!,
          datos: datos,
        );
      } else {
        result = await _service.crear(
          usuaIde: widget.user.usuaIde,
          datos: datos,
        );
      }

      debugPrint('success: ${result['success']}');
      debugPrint('message: ${result['message']}');
      debugPrint('╚════════════════╝');

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Guardado'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _mostrarErrorDialog(result['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      debugPrint('EXCEPCIÓN: $e');
      if (mounted) _mostrarErrorDialog('Excepción Flutter:\n$e');
    }

    setState(() => _isLoading = false);
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Cliente' : 'Nuevo Cliente'),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Identificación ───────────────────
                    _seccion('IDENTIFICACIÓN'),
                    const SizedBox(height: 8),
                    const Text('Tipo de cliente',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chipTipo('V', 'Venezolano'),
                        _chipTipo('E', 'Extranjero'),
                        _chipTipo('J', 'Jurídico'),
                        _chipTipo('G', 'Gubernamental'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _campo(
                            ctrl: _nuidenCtrl,
                            label: 'Cédula / RIF *',
                            icono: Icons.badge_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _campo(
                            ctrl: _codigoCtrl,
                            label: 'Código',
                            icono: Icons.qr_code,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Nombre ───────────────────────────
                    _seccion('NOMBRE'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            ctrl: _nombre1Ctrl,
                            label: 'Primer nombre *',
                            icono: Icons.person_outline,
                            requerido: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _campo(
                            ctrl: _nombre2Ctrl,
                            label: 'Segundo nombre',
                            icono: Icons.person_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            ctrl: _apelli1Ctrl,
                            label: 'Primer apellido',
                            icono: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _campo(
                            ctrl: _apelli2Ctrl,
                            label: 'Segundo apellido',
                            icono: Icons.person_outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Fecha nacimiento ─────────────────
                    _seccion('FECHA DE NACIMIENTO'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _seleccionarFecha,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_outlined,
                                color: AppColors.textHint, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              _fechaDisplay(_fechaNaci),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar,
                                color: AppColors.textHint, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Contacto ─────────────────────────
                    _seccion('CONTACTO'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            ctrl: _telmoviCtrl,
                            label: 'Celular principal',
                            icono: Icons.phone_outlined,
                            tipo: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _campo(
                            ctrl: _telmovi2Ctrl,
                            label: 'Celular secundario',
                            icono: Icons.phone_outlined,
                            tipo: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _campo(
                      ctrl: _correoCtrl,
                      label: 'Correo electrónico',
                      icono: Icons.email_outlined,
                      tipo: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    // ── Dirección ────────────────────────
                    _seccion('DIRECCIÓN'),
                    const SizedBox(height: 8),
                    _campo(
                      ctrl: _direcciCtrl,
                      label: 'Dirección',
                      icono: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            ctrl: _ciudadCtrl,
                            label: 'Ciudad',
                            icono: Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _campo(
                            ctrl: _paisCtrl,
                            label: 'País',
                            icono: Icons.flag_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Envío ────────────────────────────
                    _seccion('ENVÍO'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      // Valor seguro — evita assertion por duplicados
                      value: _empresaEnvioValida,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(
                        labelText: 'Empresa de envío',
                        prefixIcon:
                            Icon(Icons.local_shipping_outlined, size: 18),
                      ),
                      items: _empresasEnvio
                          .map<DropdownMenuItem<String>>(
                              (e) => DropdownMenuItem<String>(
                                    value: e['valor'],
                                    child: Text(
                                      e['label']!,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13),
                                    ),
                                  ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _empresaEnvio = v);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            ctrl: _codigoOficinaCtrl,
                            label: 'Código oficina',
                            icono: Icons.store_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _campo(
                            ctrl: _nombreOficinaCtrl,
                            label: 'Nombre oficina',
                            icono: Icons.storefront_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Fiscal ───────────────────────────
                    _seccion('DATOS FISCALES'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Contribuyente Especial',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 13),
                        ),
                        subtitle: const Text(
                          'Activar si es contribuyente especial',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 11),
                        ),
                        value: _contriespec,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _contriespec = v),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Vendedor ─────────────────────────
                    _seccion('VENDEDOR ASIGNADO'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _vendedorValido,
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(
                        labelText: 'Vendedor',
                        prefixIcon: Icon(Icons.person_pin_outlined, size: 18),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text(
                            '-- Seleccionar vendedor --',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 13),
                          ),
                        ),
                        ..._vendedores.map<DropdownMenuItem<int>>((v) {
                          final ide =
                              int.tryParse(v['usua_ide'].toString()) ?? 0;
                          return DropdownMenuItem<int>(
                            value: ide,
                            child: Text(
                              '${v['usua_nombre']} '
                              '${v['usua_apelli']}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (v) => setState(() => _vendedor = v),
                    ),

                    const SizedBox(height: 24),

                    // ── Botón guardar ────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _guardar,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: Text(
                          _isLoading
                              ? 'Guardando...'
                              : _esEdicion
                                  ? 'Actualizar Cliente'
                                  : 'Crear Cliente',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Widgets auxiliares ─────────────────────────────────

  Widget _seccion(String t) => Text(t,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ));

  Widget _chipTipo(String valor, String label) {
    final sel = _tipcli == valor;
    return GestureDetector(
      onTap: () => setState(() => _tipcli = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryBg : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? AppColors.primary : AppColors.border,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valor,
              style: TextStyle(
                color: sel ? AppColors.primary : AppColors.textHint,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: sel ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required IconData icono,
    bool requerido = false,
    TextInputType? tipo,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: tipo,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icono, size: 18),
        ),
        validator: requerido
            ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
            : null,
      );
}
