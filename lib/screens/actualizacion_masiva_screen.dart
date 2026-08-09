import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/actualizacion_masiva_service.dart';
import '../theme/app_theme.dart';

// ── Modelo de fila editable ────────────────────────────────
class _FilaProducto {
  final int productoIde;
  final String codigo;
  final String descripcion;
  final String departamento;
  final String unidad;

  final double existenOriginal;
  final double costoOriginal;
  final double precio1Original;
  final double precioUsdOriginal;

  late TextEditingController existenCtrl;
  late TextEditingController costoCtrl;
  late TextEditingController precio1Ctrl;
  late TextEditingController precioUsdCtrl;

  bool modificado = false;
  bool guardando = false;
  bool guardado = false;
  bool error = false;

  _FilaProducto({
    required this.productoIde,
    required this.codigo,
    required this.descripcion,
    required this.departamento,
    required this.unidad,
    required this.existenOriginal,
    required this.costoOriginal,
    required this.precio1Original,
    required this.precioUsdOriginal,
  }) {
    existenCtrl = TextEditingController(text: _fmt(existenOriginal));
    costoCtrl = TextEditingController(text: _fmt(costoOriginal));
    precio1Ctrl = TextEditingController(text: _fmt(precio1Original));
    precioUsdCtrl = TextEditingController(text: _fmt(precioUsdOriginal));
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double get existenActual =>
      double.tryParse(existenCtrl.text.replaceAll(',', '.')) ?? existenOriginal;
  double get costoActual =>
      double.tryParse(costoCtrl.text.replaceAll(',', '.')) ?? costoOriginal;
  double get precio1Actual =>
      double.tryParse(precio1Ctrl.text.replaceAll(',', '.')) ?? precio1Original;
  double get precioUsdActual =>
      double.tryParse(precioUsdCtrl.text.replaceAll(',', '.')) ??
      precioUsdOriginal;

  bool get tieneCambios =>
      existenActual != existenOriginal ||
      costoActual != costoOriginal ||
      precio1Actual != precio1Original ||
      precioUsdActual != precioUsdOriginal;

  void dispose() {
    existenCtrl.dispose();
    costoCtrl.dispose();
    precio1Ctrl.dispose();
    precioUsdCtrl.dispose();
  }
}

// ── Pantalla principal ─────────────────────────────────────
class ActualizacionMasivaScreen extends StatefulWidget {
  final UserModel user;
  const ActualizacionMasivaScreen({super.key, required this.user});

  @override
  State<ActualizacionMasivaScreen> createState() =>
      _ActualizacionMasivaScreenState();
}

class _ActualizacionMasivaScreenState extends State<ActualizacionMasivaScreen> {
  final _service = ActualizacionMasivaService();
  final _searchCtrl = TextEditingController();

  List<_FilaProducto> _filas = [];
  List _departamentos = [];
  int _depto = 0;
  bool _isLoading = true;
  bool _guardandoTodo = false;
  String _errorMsg = '';

  // ── Anchos fijos de columnas ─────────────────────────────
  static const double _wExist = 110;
  static const double _wCosto = 130;
  static const double _wPrecio = 130;
  static const double _wUsd = 110;
  static const double _wEst = 32;

  int get _modificados => _filas.where((f) => f.tieneCambios).length;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final f in _filas) f.dispose();
    super.dispose();
  }

  Future<void> _cargar([String busqueda = '']) async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    for (final f in _filas) f.dispose();

    final result = await _service.listar(
      usuaIde: widget.user.usuaIde,
      departamento: _depto,
      busqueda: busqueda,
    );

    if (result['success'] == true) {
      final prods = result['productos'] as List? ?? [];
      final deptos = result['departamentos'] as List? ?? [];
      setState(() {
        _departamentos = deptos;
        _filas = prods
            .map((p) => _FilaProducto(
                  productoIde: int.tryParse(p['produc_ide'].toString()) ?? 0,
                  codigo: p['produc_codigo']?.toString() ?? '',
                  descripcion: p['produc_descrip']?.toString() ?? '',
                  departamento: p['depart_descrip']?.toString() ?? '-',
                  unidad: p['unidmed_descrip']?.toString() ?? '',
                  existenOriginal:
                      double.tryParse(p['produc_existen'].toString()) ?? 0,
                  costoOriginal:
                      double.tryParse(p['produc_costo'].toString()) ?? 0,
                  precio1Original:
                      double.tryParse(p['produc_precio1'].toString()) ?? 0,
                  precioUsdOriginal:
                      double.tryParse(p['produc_preciodolar'].toString()) ?? 0,
                ))
            .toList();
      });
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _autoGuardarFila(int index) async {
    final fila = _filas[index];
    if (!fila.tieneCambios) return;

    setState(() {
      fila.guardando = true;
      fila.error = false;
    });

    final result = await _service.actualizarFila(
      usuaIde: widget.user.usuaIde,
      productoIde: fila.productoIde,
      existen: fila.existenActual,
      costo: fila.costoActual,
      precio1: fila.precio1Actual,
      precioUsd: fila.precioUsdActual,
    );

    setState(() {
      fila.guardando = false;
      fila.guardado = result['success'] == true;
      fila.error = result['success'] != true;
      fila.modificado = result['success'] == true;
    });

    if (result['success'] == true) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => fila.guardado = false);
    }
  }

  Future<void> _guardarTodo() async {
    final conCambios = _filas.where((f) => f.tieneCambios).toList();

    if (conCambios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sin cambios para guardar'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.save_alt, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Guardar todo'),
          ],
        ),
        content: Text(
          '¿Actualizar ${conCambios.length} producto(s) '
          'con cambios?\n\n'
          'Se registrará en el historial de ajustes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Confirmar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _guardandoTodo = true);

    final productosData = conCambios
        .map((f) => {
              'produc_ide': f.productoIde,
              'produc_existen': f.existenActual,
              'produc_costo': f.costoActual,
              'produc_precio1': f.precio1Actual,
              'produc_preciodolar': f.precioUsdActual,
            })
        .toList();

    final result = await _service.actualizarTodo(
      usuaIde: widget.user.usuaIde,
      productos: productosData,
    );

    setState(() => _guardandoTodo = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
      if (result['success'] == true) {
        _cargar(_searchCtrl.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualización Masiva'),
        actions: [
          if (_modificados > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_modificados cambio(s)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargar(_searchCtrl.text),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surface,
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _depto,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Departamento',
                    prefixIcon: Icon(Icons.category_outlined, size: 18),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: 0,
                      child: Text(
                        'Todos los departamentos',
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 13),
                      ),
                    ),
                    ..._departamentos.map<DropdownMenuItem<int>>((d) =>
                        DropdownMenuItem<int>(
                          value: int.tryParse(d['depart_ide'].toString()) ?? 0,
                          child: Text(
                            d['depart_descrip']?.toString() ?? '',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                          ),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _depto = v ?? 0);
                    _cargar(_searchCtrl.text);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _cargar,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o código...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              _cargar();
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),

          // ── Cabecera fija ─────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Columna producto ocupa el resto
                const Expanded(
                  child: Text(
                    'Producto',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                _cabecera('Exist.', _wExist),
                _cabecera('Costo', _wCosto),
                _cabecera('Precio1', _wPrecio),
                _cabecera('P.USD', _wUsd),
                SizedBox(width: _wEst),
              ],
            ),
          ),

          // ── Matriz ────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMsg.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 48),
                            const SizedBox(height: 12),
                            Text(_errorMsg,
                                style: const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _cargar,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _filas.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    color: AppColors.textHint, size: 52),
                                SizedBox(height: 12),
                                Text('Sin productos',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filas.length,
                            itemBuilder: (_, i) => _buildFila(i),
                          ),
          ),

          // ── Barra inferior ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  '${_filas.length} productos'
                  '  •  $_modificados con cambios',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: (_guardandoTodo || _modificados == 0)
                        ? null
                        : _guardarTodo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _modificados > 0 ? AppColors.success : null,
                    ),
                    icon: _guardandoTodo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_alt, size: 18),
                    label: Text(
                      _guardandoTodo
                          ? 'Guardando...'
                          : 'Guardar todo ($_modificados)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Fila de la matriz ──────────────────────────────────
  Widget _buildFila(int index) {
    final fila = _filas[index];

    Color fondoFila = index % 2 == 0 ? AppColors.surface : AppColors.surfaceAlt;

    if (fila.guardado) fondoFila = AppColors.successBg;
    if (fila.error) fondoFila = AppColors.errorBg;
    if (fila.tieneCambios && !fila.guardando) fondoFila = AppColors.warningBg;

    return Container(
      decoration: BoxDecoration(
        color: fondoFila,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
          left: fila.tieneCambios
              ? const BorderSide(color: AppColors.warning, width: 3)
              : fila.guardado
                  ? const BorderSide(color: AppColors.success, width: 3)
                  : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre + código + depto
            Row(
              children: [
                Expanded(
                  child: Text(
                    fila.descripcion,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (fila.codigo.isNotEmpty) ...[
                  Text(
                    fila.codigo,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 10),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    fila.departamento,
                    style:
                        const TextStyle(color: AppColors.primary, fontSize: 9),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Campos editables alineados con cabecera
            Row(
              children: [
                // Espacio igual al "Expanded" de la cabecera
                const Expanded(child: SizedBox()),

                _celdaEditable(
                  ctrl: fila.existenCtrl,
                  ancho: _wExist,
                  color: AppColors.info,
                  onFocusLost: () => _autoGuardarFila(index),
                  onChange: () => setState(() {}),
                ),
                _celdaEditable(
                  ctrl: fila.costoCtrl,
                  ancho: _wCosto,
                  color: AppColors.warning,
                  onFocusLost: () => _autoGuardarFila(index),
                  onChange: () => setState(() {}),
                ),
                _celdaEditable(
                  ctrl: fila.precio1Ctrl,
                  ancho: _wPrecio,
                  color: AppColors.primary,
                  onFocusLost: () => _autoGuardarFila(index),
                  onChange: () => setState(() {}),
                ),
                _celdaEditable(
                  ctrl: fila.precioUsdCtrl,
                  ancho: _wUsd,
                  color: AppColors.success,
                  onFocusLost: () => _autoGuardarFila(index),
                  onChange: () => setState(() {}),
                ),

                // Indicador de estado
                SizedBox(
                  width: _wEst,
                  child: Center(
                    child: fila.guardando
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2))
                        : fila.guardado
                            ? const Icon(Icons.check_circle,
                                color: AppColors.success, size: 18)
                            : fila.error
                                ? const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 18)
                                : fila.tieneCambios
                                    ? const Icon(Icons.circle,
                                        color: AppColors.warning, size: 10)
                                    : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets auxiliares ─────────────────────────────────

  Widget _cabecera(String texto, double ancho) => SizedBox(
        width: ancho,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );

  Widget _celdaEditable({
    required TextEditingController ctrl,
    required double ancho,
    required Color color,
    required VoidCallback onFocusLost,
    required VoidCallback onChange,
  }) =>
      SizedBox(
        width: ancho,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) onFocusLost();
            },
            child: TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => onChange(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color.withAlpha(80)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: color.withAlpha(40)),
                ),
                filled: true,
                fillColor: color.withAlpha(10),
              ),
            ),
          ),
        ),
      );
}
