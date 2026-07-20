import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/producto_service.dart';
import '../theme/app_theme.dart';

class FormProductoScreen extends StatefulWidget {
  final UserModel user;
  final int? productoIde;

  const FormProductoScreen({
    super.key,
    required this.user,
    this.productoIde,
  });

  @override
  State<FormProductoScreen> createState() => _FormProductoScreenState();
}

class _FormProductoScreenState extends State<FormProductoScreen> {
  final _service = ProductoService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _cargando = true;

  // Foto
  XFile? _nuevaFoto;
  String? _fotoActual;

  // Listas
  List _marcas = [];
  List _modelos = [];
  List _unidades = [];
  List _impuestos = [];
  List _departamentos = [];

  // Seleccionados
  int? _marcaIde;
  int? _modeloIde;
  int? _unidmedIde;
  int? _impuestoIde;
  int? _departamentoIde;
  int _servicio = 0;

  // Controladores
  final _codigoCtrl = TextEditingController();
  final _descripCtrl = TextEditingController();
  final _existenCtrl = TextEditingController(text: '0');
  final _costoCtrl = TextEditingController(text: '0');
  final _precio1Ctrl = TextEditingController(text: '0');
  final _precio2Ctrl = TextEditingController(text: '0');
  final _precio3Ctrl = TextEditingController(text: '0');
  final _precio4Ctrl = TextEditingController(text: '0');
  final _precioDolarCtrl = TextEditingController(text: '0');
  final _colorCtrl = TextEditingController();
  final _tallaCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _observaCtrl = TextEditingController();

  bool get _esEdicion => widget.productoIde != null;

  // ── Helpers ──────────────────────────────────────────────
  int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

  int? _toIntNullable(dynamic v) {
    final parsed = int.tryParse(v?.toString() ?? '0') ?? 0;
    return parsed > 0 ? parsed : null;
  }

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _descripCtrl.dispose();
    _existenCtrl.dispose();
    _costoCtrl.dispose();
    _precio1Ctrl.dispose();
    _precio2Ctrl.dispose();
    _precio3Ctrl.dispose();
    _precio4Ctrl.dispose();
    _precioDolarCtrl.dispose();
    _colorCtrl.dispose();
    _tallaCtrl.dispose();
    _stockCtrl.dispose();
    _observaCtrl.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    setState(() => _cargando = true);

    try {
      // Cargar listas
      final listas =
          await _service.cargarListas().timeout(const Duration(seconds: 15));

      if (listas['success'] == true) {
        setState(() {
          _marcas = listas['marcas'] ?? [];
          _modelos = listas['modelos'] ?? [];
          _unidades = listas['unidades'] ?? [];
          _impuestos = listas['impuestos'] ?? [];
          _departamentos = listas['departamentos'] ?? [];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(listas['message'] ?? 'Error al cargar listas'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }

      // Si es edición, cargar datos del producto
      if (_esEdicion) {
        final result = await _service
            .detalle(widget.productoIde!)
            .timeout(const Duration(seconds: 15));

        if (result['success'] == true) {
          final p = result['producto'];
          setState(() {
            _codigoCtrl.text = p['produc_codigo']?.toString() ?? '';
            _descripCtrl.text = p['produc_descrip']?.toString() ?? '';
            _existenCtrl.text = p['produc_existen']?.toString() ?? '0';
            _costoCtrl.text = p['produc_costo']?.toString() ?? '0';
            _precio1Ctrl.text = p['produc_precio1']?.toString() ?? '0';
            _precio2Ctrl.text = p['produc_precio2']?.toString() ?? '0';
            _precio3Ctrl.text = p['produc_precio3']?.toString() ?? '0';
            _precio4Ctrl.text = p['produc_precio4']?.toString() ?? '0';
            _precioDolarCtrl.text = p['produc_preciodolar']?.toString() ?? '0';
            _colorCtrl.text = p['produc_color']?.toString() ?? '';
            _tallaCtrl.text = p['produc_talla']?.toString() ?? '';
            _stockCtrl.text = p['produc_stock']?.toString() ?? '0';
            _observaCtrl.text = p['produc_observa']?.toString() ?? '';
            _servicio = _toInt(p['produc_servicio']);
            _marcaIde = _toIntNullable(p['produc_marca']);
            _modeloIde = _toIntNullable(p['produc_modelo']);
            _unidmedIde = _toIntNullable(p['produc_unidmed']);
            _impuestoIde = _toIntNullable(p['produc_impuesto']);
            _departamentoIde = _toIntNullable(p['produc_departamento']);
            _fotoActual =
                p['produc_foto']?.toString().startsWith('http') == true
                    ? p['produc_foto'].toString()
                    : null;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Producto no encontrado'),
                backgroundColor: AppColors.error,
              ),
            );
            Navigator.pop(context);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error al inicializar formulario: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (imagen != null && mounted) {
      setState(() => _nuevaFoto = imagen);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? fotoBase64;
    if (_nuevaFoto != null) {
      try {
        if (kIsWeb) {
          final bytes = await _nuevaFoto!.readAsBytes();
          fotoBase64 = base64Encode(bytes);
        } else {
          final bytes = await File(_nuevaFoto!.path).readAsBytes();
          fotoBase64 = base64Encode(bytes);
        }
      } catch (e) {
        debugPrint('Error leyendo foto: $e');
      }
    }

    final datos = {
      'produc_codigo': _codigoCtrl.text.trim(),
      'produc_descrip': _descripCtrl.text.trim(),
      'produc_existen': double.tryParse(_existenCtrl.text) ?? 0,
      'produc_costo': double.tryParse(_costoCtrl.text) ?? 0,
      'produc_precio1': double.tryParse(_precio1Ctrl.text) ?? 0,
      'produc_precio2': double.tryParse(_precio2Ctrl.text) ?? 0,
      'produc_precio3': double.tryParse(_precio3Ctrl.text) ?? 0,
      'produc_precio4': double.tryParse(_precio4Ctrl.text) ?? 0,
      'produc_preciodolar': double.tryParse(_precioDolarCtrl.text) ?? 0,
      'produc_color': _colorCtrl.text.trim(),
      'produc_talla': _tallaCtrl.text.trim(),
      'produc_unidmed': _unidmedIde ?? 0,
      'produc_marca': _marcaIde ?? 0,
      'produc_modelo': _modeloIde ?? 0,
      'produc_impuesto': _impuestoIde ?? 0,
      'produc_departamento': _departamentoIde ?? 0,
      'produc_servicio': _servicio,
      'produc_stock': int.tryParse(_stockCtrl.text) ?? 0,
      'produc_observa': _observaCtrl.text.trim(),
      'produc_tienda': 1,
    };

    try {
      Map<String, dynamic> result;

      if (_esEdicion) {
        result = await _service
            .editar(
              usuaIde: widget.user.usuaIde,
              productoIde: widget.productoIde!,
              datos: datos,
              fotoBase64: fotoBase64,
            )
            .timeout(const Duration(seconds: 20));
      } else {
        result = await _service
            .crear(
              usuaIde: widget.user.usuaIde,
              datos: datos,
              fotoBase64: fotoBase64,
            )
            .timeout(const Duration(seconds: 20));
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Producto' : 'Nuevo Producto'),
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
                    // ── Foto ──────────────────────────────
                    _seccion('FOTO DEL PRODUCTO'),
                    const SizedBox(height: 8),
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _nuevaFoto != null
                                ? kIsWeb
                                    ? Image.network(
                                        _nuevaFoto!.path,
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_nuevaFoto!.path),
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      )
                                : _fotoActual != null
                                    ? Image.network(
                                        _fotoActual!,
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _iconoFoto(),
                                      )
                                    : _iconoFoto(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!kIsWeb) ...[
                                _btnFoto(
                                  Icons.camera_alt,
                                  'Cámara',
                                  () => _seleccionarFoto(ImageSource.camera),
                                ),
                                const SizedBox(width: 12),
                              ],
                              _btnFoto(
                                Icons.photo_library,
                                'Galería',
                                () => _seleccionarFoto(ImageSource.gallery),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Info general ───────────────────────
                    _seccion('INFORMACIÓN GENERAL'),
                    const SizedBox(height: 8),
                    _campo(
                      ctrl: _codigoCtrl,
                      label: 'Código',
                      icono: Icons.qr_code,
                    ),
                    const SizedBox(height: 10),
                    _campo(
                      ctrl: _descripCtrl,
                      label: 'Descripción',
                      icono: Icons.description_outlined,
                      requerido: true,
                    ),
                    const SizedBox(height: 10),

                    // Tipo: Producto o Servicio
                    Row(
                      children: [
                        Expanded(
                          child: _chipOpcion(
                            label: 'Producto',
                            selected: _servicio == 0,
                            onTap: () => setState(() => _servicio = 0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _chipOpcion(
                            label: 'Servicio',
                            selected: _servicio == 1,
                            onTap: () => setState(() => _servicio = 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _campo(
                        ctrl: _colorCtrl,
                        label: 'Color',
                        icono: Icons.palette_outlined),
                    const SizedBox(height: 10),
                    _campo(
                        ctrl: _tallaCtrl,
                        label: 'Talla',
                        icono: Icons.straighten),

                    const SizedBox(height: 20),

                    // ── Clasificación ──────────────────────
                    _seccion('CLASIFICACIÓN'),
                    const SizedBox(height: 8),

                    _dropdown(
                      label: 'Departamento',
                      value: _departamentoIde,
                      items: _departamentos,
                      ideKey: 'depart_ide',
                      descKey: 'depart_descrip',
                      icono: Icons.category_outlined,
                      onChanged: (v) => setState(() => _departamentoIde = v),
                    ),
                    const SizedBox(height: 10),
                    _dropdown(
                      label: 'Marca',
                      value: _marcaIde,
                      items: _marcas,
                      ideKey: 'marca_ide',
                      descKey: 'marca_descrip',
                      icono: Icons.branding_watermark_outlined,
                      onChanged: (v) => setState(() => _marcaIde = v),
                    ),
                    const SizedBox(height: 10),
                    _dropdown(
                      label: 'Modelo',
                      value: _modeloIde,
                      items: _modelos,
                      ideKey: 'modelo_ide',
                      descKey: 'modelo_descrip',
                      icono: Icons.build_outlined,
                      onChanged: (v) => setState(() => _modeloIde = v),
                    ),
                    const SizedBox(height: 10),
                    _dropdown(
                      label: 'Unidad de medida',
                      value: _unidmedIde,
                      items: _unidades,
                      ideKey: 'unidmed_ide',
                      descKey: 'unidmed_descrip',
                      icono: Icons.straighten_outlined,
                      onChanged: (v) => setState(() => _unidmedIde = v),
                    ),
                    const SizedBox(height: 10),
                    _dropdown(
                      label: 'Impuesto %',
                      value: _impuestoIde,
                      items: _impuestos,
                      ideKey: 'impuesto_ide',
                      descKey: 'impuesto_porcent',
                      icono: Icons.percent,
                      onChanged: (v) => setState(() => _impuestoIde = v),
                    ),

                    const SizedBox(height: 20),

                    // ── Stock ──────────────────────────────
                    _seccion('STOCK'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            ctrl: _existenCtrl,
                            label: 'Existencia',
                            icono: Icons.inventory_2_outlined,
                            numero: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _campo(
                            ctrl: _stockCtrl,
                            label: 'Stock mínimo',
                            icono: Icons.warning_amber_outlined,
                            numero: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Precios ────────────────────────────
                    _seccion('PRECIOS'),
                    const SizedBox(height: 8),
                    _campo(
                      ctrl: _costoCtrl,
                      label: 'Costo',
                      icono: Icons.price_check,
                      numero: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            ctrl: _precio1Ctrl,
                            label: 'Precio 1',
                            icono: Icons.attach_money,
                            numero: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _campo(
                            ctrl: _precio2Ctrl,
                            label: 'Precio 2',
                            icono: Icons.attach_money,
                            numero: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            ctrl: _precio3Ctrl,
                            label: 'Precio 3',
                            icono: Icons.attach_money,
                            numero: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _campo(
                            ctrl: _precio4Ctrl,
                            label: 'Precio 4',
                            icono: Icons.attach_money,
                            numero: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _campo(
                      ctrl: _precioDolarCtrl,
                      label: 'Precio USD',
                      icono: Icons.attach_money,
                      numero: true,
                    ),

                    const SizedBox(height: 20),

                    // ── Observaciones ──────────────────────
                    _seccion('OBSERVACIONES'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _observaCtrl,
                      maxLines: 3,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (opcional)',
                        prefixIcon: Icon(Icons.comment_outlined),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Botón guardar ──────────────────────
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
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isLoading
                              ? 'Guardando...'
                              : _esEdicion
                                  ? 'Actualizar Producto'
                                  : 'Crear Producto',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
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

  // ── Widgets auxiliares ─────────────────────────────────────

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Text(
          titulo,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required IconData icono,
    bool requerido = false,
    bool numero = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: numero
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
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

  Widget _dropdown({
    required String label,
    required int? value,
    required List items,
    required String ideKey,
    required String descKey,
    required IconData icono,
    required Function(int?) onChanged,
  }) {
    final ids = items.map((i) => int.tryParse(i[ideKey].toString())).toList();
    final valorValido = ids.contains(value) ? value : null;

    return DropdownButtonFormField<int>(
      value: valorValido,
      dropdownColor: AppColors.surface,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono, size: 18),
      ),
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text(
            '-- Seleccionar --',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ),
        ...items.map<DropdownMenuItem<int>>((item) => DropdownMenuItem<int>(
              value: int.tryParse(item[ideKey].toString()),
              child: Text(
                item[descKey]?.toString() ?? '',
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
      onChanged: (v) => onChanged(v),
    );
  }

  Widget _chipOpcion({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBg : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _iconoFoto() => Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.primary, size: 40),
            SizedBox(height: 6),
            Text('Sin foto',
                style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ],
        ),
      );

  Widget _btnFoto(IconData icono, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icono, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
