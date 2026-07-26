import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/venta_service.dart';
import '../services/auditoria_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import '../models/carrito_item.dart';
import 'seleccionar_cliente_screen.dart';
import 'buscar_producto_screen.dart';
import 'nota_entrega_screen.dart';

class NuevaVentaScreen extends StatefulWidget {
  final UserModel user;
  const NuevaVentaScreen({super.key, required this.user});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final _ventaService = VentaService();

  // Cliente seleccionado
  int? _clienteIde;
  String? _clienteNombre;

  // Fecha de la venta (por defecto hoy)
  DateTime _fechaVenta = DateTime.now();

  // Configuración de venta
  int _tipoPrecio = 1;
  int _condicion = 0;
  int _diasCredito = 30;

  final _descuentoCtrl = TextEditingController(text: '0');
  final _fleteCtrl = TextEditingController(text: '0');
  final _impuestoCtrl = TextEditingController(text: '0');
  final _abonoCtrl = TextEditingController(text: '0');
  final _observaCtrl = TextEditingController();

  // Carrito
  final List<CarritoItem> _carrito = [];
  bool _isGuardando = false;

  @override
  void dispose() {
    _descuentoCtrl.dispose();
    _fleteCtrl.dispose();
    _impuestoCtrl.dispose();
    _abonoCtrl.dispose();
    _observaCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────
  String _fechaSql(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fechaDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  bool get _esHoy {
    final hoy = DateTime.now();
    return _fechaVenta.year == hoy.year &&
        _fechaVenta.month == hoy.month &&
        _fechaVenta.day == hoy.day;
  }

  // ── Cálculos ──────────────────────────────────────────────
  double get _subtotal {
    double total = 0;
    for (var item in _carrito) {
      total += item.subtotal(_tipoPrecio);
    }
    return total;
  }

  double get _descuentoPct => double.tryParse(_descuentoCtrl.text) ?? 0;
  double get _flete => double.tryParse(_fleteCtrl.text) ?? 0;
  double get _impuestoPct => double.tryParse(_impuestoCtrl.text) ?? 0;
  double get _abonoInicial => double.tryParse(_abonoCtrl.text) ?? 0;

  double get _subtotalConDescuento => _subtotal * (1 - _descuentoPct / 100);

  double get _montoImpuesto => _subtotalConDescuento * (_impuestoPct / 100);

  double get _total => _subtotalConDescuento + _montoImpuesto + _flete;

  double get _saldo => _total - _abonoInicial;

  // ── Seleccionar fecha ──────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaVenta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // No permite fechas futuras
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (fecha != null && mounted) {
      setState(() => _fechaVenta = fecha);
    }
  }

  // ── Seleccionar cliente ────────────────────────────────────
  Future<void> _seleccionarCliente() async {
    final resultado = await Navigator.push<Map>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarClienteScreen(user: widget.user),
      ),
    );

    if (resultado != null && mounted) {
      final ide = int.tryParse(resultado['clien_ide'].toString());
      final nombre = resultado['clien_nombre1']?.toString() ?? '';
      setState(() {
        _clienteIde = ide;
        _clienteNombre = nombre;
      });
    }
  }

  // ── Agregar producto ───────────────────────────────────────
  Future<void> _agregarProducto() async {
    final producto = await Navigator.push<CarritoItem>(
      context,
      MaterialPageRoute(
        builder: (_) => const BuscarProductoScreen(),
      ),
    );

    if (producto != null && mounted) {
      setState(() {
        final existente =
            _carrito.indexWhere((i) => i.productoIde == producto.productoIde);
        if (existente >= 0) {
          _carrito[existente].cantidad += 1;
        } else {
          _carrito.add(producto);
        }
      });
    }
  }

  void _eliminarItem(int index) {
    setState(() => _carrito.removeAt(index));
  }

  void _cambiarCantidad(int index, double delta) {
    setState(() {
      final nuevaCantidad = _carrito[index].cantidad + delta;
      if (nuevaCantidad >= 1 && nuevaCantidad <= _carrito[index].existencia) {
        _carrito[index].cantidad = nuevaCantidad;
      }
    });
  }

  // ── Guardar venta ──────────────────────────────────────────
  Future<void> _guardarVenta() async {
    if (_clienteIde == null) {
      _mostrarError('Selecciona un cliente');
      return;
    }
    if (_carrito.isEmpty) {
      _mostrarError('Agrega al menos un producto');
      return;
    }
    if (_condicion == 1 && _diasCredito <= 0) {
      _mostrarError('Indica los días de crédito');
      return;
    }

    setState(() => _isGuardando = true);

    final items = _carrito
        .map((item) => {
              'produc_ide': item.productoIde,
              'cantidad': item.cantidad,
              'descuento': item.descuento,
              'costo': item.costo,
            })
        .toList();

    final result = await _ventaService.crearFactura(
      clienteIde: _clienteIde!,
      usuaIde: widget.user.usuaIde,
      tipoPrecio: _tipoPrecio,
      condicion: _condicion,
      diasCredito: _condicion == 1 ? _diasCredito : 0,
      descuento: _descuentoPct,
      flete: _flete,
      impuesto: _impuestoPct,
      abonoInicial: _abonoInicial,
      observa: _observaCtrl.text.trim(),
      fechaVenta: _fechaSql(_fechaVenta),
      items: items,
    );

    debugPrint('Registrar Venta - request items: $items');
    debugPrint('Registrar Venta - api response: $result');

    setState(() => _isGuardando = false);

    if (result['success'] == true) {
      await AuditoriaService().crearVenta(
        widget.user,
        result['factura_ide'],
        result['factura_num'],
        _total,
      );
      _limpiarFormulario();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotaEntregaScreen(
              facturaIde: result['factura_ide'],
              facturaNum: result['factura_num'],
            ),
          ),
        );
      }
    } else {
      _mostrarError(result['message'] ?? 'Error al guardar');
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _clienteIde = null;
      _clienteNombre = null;
      _carrito.clear();
      _fechaVenta = DateTime.now();
      _descuentoCtrl.text = '0';
      _fleteCtrl.text = '0';
      _impuestoCtrl.text = '0';
      _abonoCtrl.text = '0';
      _observaCtrl.clear();
      _condicion = 0;
      _diasCredito = 30;
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fecha de la venta ─────────────────────────
            _seccion('FECHA DE VENTA'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _esHoy ? AppColors.border : AppColors.warning,
                    width: _esHoy ? 1 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _esHoy ? AppColors.textHint : AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fechaDisplay(_fechaVenta),
                            style: TextStyle(
                              color: _esHoy
                                  ? AppColors.textPrimary
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _esHoy ? 'Hoy' : 'Fecha modificada',
                            style: TextStyle(
                              color: _esHoy
                                  ? AppColors.textHint
                                  : AppColors.warning,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_calendar,
                      color: _esHoy ? AppColors.textHint : AppColors.warning,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            // Botón rápido para volver a hoy
            if (!_esHoy) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _fechaVenta = DateTime.now()),
                  icon: const Icon(Icons.today, size: 14),
                  label: const Text('Usar fecha de hoy',
                      style: TextStyle(fontSize: 12)),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Cliente ────────────────────────────────────
            _seccion('CLIENTE'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarCliente,
              child: Container(
                key: ValueKey(_clienteIde),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _clienteIde == null
                        ? AppColors.border
                        : AppColors.primary,
                    width: _clienteIde == null ? 1 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _clienteIde == null ? Icons.person_outline : Icons.person,
                      color: _clienteIde == null
                          ? AppColors.textHint
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _clienteNombre ?? 'Toca para seleccionar cliente',
                        style: TextStyle(
                          color: _clienteIde == null
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                          fontWeight: _clienteIde == null
                              ? FontWeight.normal
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      _clienteIde == null
                          ? Icons.chevron_right
                          : Icons.check_circle,
                      color: _clienteIde == null
                          ? AppColors.textHint
                          : AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Tipo de precio ─────────────────────────────
            _seccion('TIPO DE PRECIO'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _chipOpcion(
                    label: 'Precio General',
                    selected: _tipoPrecio == 1,
                    onTap: () => setState(() => _tipoPrecio = 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _chipOpcion(
                    label: 'Precio USD',
                    selected: _tipoPrecio == 2,
                    onTap: () => setState(() => _tipoPrecio = 2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Carrito ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _seccion('PRODUCTOS (${_carrito.length})'),
                TextButton.icon(
                  onPressed: _agregarProducto,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_carrito.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          color: AppColors.textHint, size: 40),
                      SizedBox(height: 8),
                      Text('Carrito vacío',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: List.generate(_carrito.length, (i) {
                    final item = _carrito[i];
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.descripcion,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      FormatoNumero.monedaConSimbolo(
                                          item.precioSegun(_tipoPrecio)),
                                      style: const TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),

                              // Controles cantidad
                              Row(
                                children: [
                                  _btnCantidad(Icons.remove,
                                      () => _cambiarCantidad(i, -1)),
                                  SizedBox(
                                    width: 36,
                                    child: Text(
                                      item.cantidad.toStringAsFixed(0),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _btnCantidad(
                                      Icons.add, () => _cambiarCantidad(i, 1)),
                                ],
                              ),

                              const SizedBox(width: 8),

                              Text(
                                FormatoNumero.monedaConSimbolo(
                                    item.subtotal(_tipoPrecio)),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 20),
                                onPressed: () => _eliminarItem(i),
                              ),
                            ],
                          ),
                        ),
                        if (i < _carrito.length - 1)
                          const Divider(height: 1, color: AppColors.border),
                      ],
                    );
                  }),
                ),
              ),

            const SizedBox(height: 20),

            // ── Condición de pago ──────────────────────────
            _seccion('CONDICIÓN DE PAGO'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _chipOpcion(
                    label: 'Contado',
                    selected: _condicion == 0,
                    onTap: () => setState(() => _condicion = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _chipOpcion(
                    label: 'Crédito',
                    selected: _condicion == 1,
                    onTap: () => setState(() => _condicion = 1),
                  ),
                ),
              ],
            ),

            if (_condicion == 1) ...[
              const SizedBox(height: 12),
              const Text('Días de crédito',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [15, 30, 45, 60, 90]
                    .map((dias) => ChoiceChip(
                          label: Text('$dias días'),
                          selected: _diasCredito == dias,
                          onSelected: (_) =>
                              setState(() => _diasCredito = dias),
                          selectedColor: AppColors.primaryBg,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: _diasCredito == dias
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: _diasCredito == dias
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: _diasCredito == dias
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 20),

            // ── Ajustes adicionales ────────────────────────
            _seccion('AJUSTES'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _campoNumerico(
                    'Descuento %',
                    _descuentoCtrl,
                    Icons.discount_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _campoNumerico(
                    'Flete',
                    _fleteCtrl,
                    Icons.local_shipping_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _campoNumerico(
                    'Impuesto %',
                    _impuestoCtrl,
                    Icons.percent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _campoNumerico(
                    'Abono inicial',
                    _abonoCtrl,
                    Icons.payments_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _observaCtrl,
              maxLines: 2,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                prefixIcon: Icon(Icons.comment_outlined),
              ),
            ),

            const SizedBox(height: 20),

            // ── Totales ────────────────────────────────────
            _seccion('TOTALES'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _filaResumen(
                      'Subtotal', FormatoNumero.monedaConSimbolo(_subtotal)),
                  _filaResumen(
                    'Descuento',
                    '-${FormatoNumero.monedaConSimbolo(_subtotal - _subtotalConDescuento)}',
                    color: AppColors.warning,
                  ),
                  _filaResumen(
                    'Impuesto',
                    '+${FormatoNumero.monedaConSimbolo(_montoImpuesto)}',
                    color: AppColors.info,
                  ),
                  _filaResumen(
                    'Flete',
                    '+${FormatoNumero.monedaConSimbolo(_flete)}',
                    color: AppColors.info,
                  ),
                  const Divider(color: AppColors.border),
                  _filaResumen(
                    'TOTAL',
                    FormatoNumero.monedaConSimbolo(_total),
                    negrita: true,
                    color: AppColors.primary,
                    grande: true,
                  ),
                  if (_abonoInicial > 0) ...[
                    _filaResumen(
                      'Abono inicial',
                      '-${FormatoNumero.monedaConSimbolo(_abonoInicial)}',
                      color: AppColors.success,
                    ),
                    _filaResumen(
                      'Saldo pendiente',
                      FormatoNumero.monedaConSimbolo(_saldo),
                      negrita: true,
                      color: _saldo > 0 ? AppColors.error : AppColors.success,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Botón guardar ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGuardando ? null : _guardarVenta,
                icon: _isGuardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isGuardando ? 'Guardando...' : 'Registrar Venta',
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
    );
  }

  // ── Widgets auxiliares ─────────────────────────────────────

  Widget _seccion(String titulo) => Text(
        titulo,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );

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

  Widget _btnCantidad(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _campoNumerico(
    String label,
    TextEditingController ctrl,
    IconData icono,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono, size: 18),
      ),
    );
  }

  Widget _filaResumen(
    String label,
    String valor, {
    bool negrita = false,
    bool grande = false,
    Color color = AppColors.textPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: grande ? 14 : 12,
              fontWeight: grande ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: grande ? 16 : 13,
              fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
