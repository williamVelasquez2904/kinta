import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/carrito_item.dart';
import '../services/venta_service.dart';
import '../services/tasa_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
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
  final _tasaService = TasaService();

  // Cliente
  int? _clienteIde;
  String? _clienteNombre;

  // Fecha
  DateTime _fechaVenta = DateTime.now();

  // Configuración
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

  // Tasas
  Map _tasa = {};

  @override
  void initState() {
    super.initState();
    _cargarTasa();
  }

  @override
  void dispose() {
    _descuentoCtrl.dispose();
    _fleteCtrl.dispose();
    _impuestoCtrl.dispose();
    _abonoCtrl.dispose();
    _observaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarTasa() async {
    final result = await _tasaService.obtener();
    if (result['success'] == true && mounted) {
      setState(() => _tasa = result['tasa'] ?? {});
    }
  }

  // ── Fecha helpers ────────────────────────────────────────
  String _fechaSql(DateTime d) => '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _fechaDisplay(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  bool get _esHoy {
    final hoy = DateTime.now();
    return _fechaVenta.year == hoy.year &&
        _fechaVenta.month == hoy.month &&
        _fechaVenta.day == hoy.day;
  }

  // ── Cálculos ─────────────────────────────────────────────
  double get _subtotal {
    double t = 0;
    for (var item in _carrito) {
      t += item.subtotal(_tipoPrecio);
    }
    return t;
  }

  double get _descuentoPct => double.tryParse(_descuentoCtrl.text) ?? 0;
  double get _flete => double.tryParse(_fleteCtrl.text) ?? 0;
  double get _impuestoPct => double.tryParse(_impuestoCtrl.text) ?? 0;
  double get _abonoInicial => double.tryParse(_abonoCtrl.text) ?? 0;

  double get _subtotalConDescuento => _subtotal * (1 - _descuentoPct / 100);

  double get _montoImpuesto => _subtotalConDescuento * (_impuestoPct / 100);

  double get _total => _subtotalConDescuento + _montoImpuesto + _flete;

  double get _saldo => _total - _abonoInicial;

  // ── Seleccionar fecha ────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaVenta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (fecha != null && mounted) {
      setState(() => _fechaVenta = fecha);
    }
  }

  // ── Seleccionar cliente ──────────────────────────────────
  Future<void> _seleccionarCliente() async {
    final resultado = await Navigator.push<Map>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarClienteScreen(user: widget.user),
      ),
    );
    if (resultado != null && mounted) {
      setState(() {
        _clienteIde = int.tryParse(resultado['clien_ide'].toString());
        _clienteNombre = resultado['clien_nombre1']?.toString() ?? '';
      });
    }
  }

  // ── Agregar producto ─────────────────────────────────────
  Future<void> _agregarProducto() async {
    final item = await Navigator.push<CarritoItem>(
      context,
      MaterialPageRoute(builder: (_) => const BuscarProductoScreen()),
    );
    if (item != null && mounted) {
      setState(() {
        final i = _carrito.indexWhere((e) => e.productoIde == item.productoIde);
        if (i >= 0) {
          _carrito[i].cantidad += item.cantidad;
        } else {
          _carrito.add(item);
        }
      });
    }
  }

  // ── Editar cantidad del carrito ──────────────────────────
  Future<void> _editarCantidad(int index) async {
    final item = _carrito[index];
    final ctrl = TextEditingController(
        text: item.cantidad % 1 == 0
            ? item.cantidad.toStringAsFixed(0)
            : item.cantidad.toStringAsFixed(2));

    final nueva = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            _ImagenCarrito(url: item.foto, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.descripcion,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stock: ${item.existencia % 1 == 0 ? item.existencia.toStringAsFixed(0) : item.existencia.toStringAsFixed(2)}',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                helperText: 'Permite decimales (ej: 1.5)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
              if (v <= 0) return;
              if (v > item.existencia) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Máximo: ${item.existencia}'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(context, v);
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (nueva != null && mounted) {
      setState(() => _carrito[index].cantidad = nueva);
    }
  }

  void _eliminarItem(int index) => setState(() => _carrito.removeAt(index));

  // ── Guardar venta ────────────────────────────────────────
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

    setState(() => _isGuardando = false);

    if (result['success'] == true) {
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
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  // ── Hora formateada ──────────────────────────────────────
  String _horaCorta(dynamic hora) {
    final str = hora?.toString() ?? '';
    return str.length >= 5 ? str.substring(0, 5) : str;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tasas del día ──────────────────────────
            if (_tasa.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fecha y hora de última actualización
                    Row(
                      children: [
                        const Icon(Icons.update,
                            color: AppColors.primary, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Actualizado: '
                            '${_tasa['tasa_fecha'] ?? '-'}'
                            '  ${_horaCorta(_tasa['tasa_hora'])}'
                            '  Fuente: ${_tasa['tasa_fuente'] ?? '-'}',
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Chips de tasas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tasas del día',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            _chipTasa(
                                'BCV', _tasa['tasa_bcv'], AppColors.primary),
                            const SizedBox(width: 8),
                            _chipTasa('Par.', _tasa['tasa_paralela'],
                                AppColors.warning),
                            const SizedBox(width: 8),
                            _chipTasa('€', _tasa['tasa_euro'], AppColors.info),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Fecha de la nota de entrega ────────────
            _seccion('FECHA DE LA NOTA DE ENTREGA'),
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

            // ── Cliente ────────────────────────────────
            _seccion('CLIENTE'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _seleccionarCliente,
              child: Container(
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

            // ── Tipo de precio ─────────────────────────
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

            // ── Carrito ────────────────────────────────
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
                              // ── Imagen ─────────────
                              _ImagenCarrito(url: item.foto, size: 48),
                              const SizedBox(width: 10),

                              // ── Info ───────────────
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
                                        item.precioSegun(_tipoPrecio),
                                      ),
                                      style: const TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Cantidad + subtotal ─
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Cantidad editable
                                  GestureDetector(
                                    onTap: () => _editarCantidad(i),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppColors.primary),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.edit,
                                            size: 10,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.cantidad % 1 == 0
                                                ? item.cantidad
                                                    .toStringAsFixed(0)
                                                : item.cantidad
                                                    .toStringAsFixed(2),
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    FormatoNumero.monedaConSimbolo(
                                      item.subtotal(_tipoPrecio),
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),

                              // ── Eliminar ───────────
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

            // ── Condición de pago ──────────────────────
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

            // ── Ajustes ────────────────────────────────
            _seccion('AJUSTES'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _campoNumerico(
                      'Descuento %', _descuentoCtrl, Icons.discount_outlined),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _campoNumerico(
                      'Flete', _fleteCtrl, Icons.local_shipping_outlined),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _campoNumerico(
                      'Impuesto %', _impuestoCtrl, Icons.percent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _campoNumerico(
                      'Abono inicial', _abonoCtrl, Icons.payments_outlined),
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

            // ── Totales ────────────────────────────────
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

            // ── Botón guardar ──────────────────────────
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
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(
                  _isGuardando ? 'Guardando...' : 'Registrar Nota de Entrega',
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

  Widget _chipOpcion({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
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

  Widget _campoNumerico(
    String label,
    TextEditingController ctrl,
    IconData icono,
  ) =>
      TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icono, size: 18),
        ),
      );

  Widget _filaResumen(
    String label,
    String valor, {
    bool negrita = false,
    bool grande = false,
    Color color = AppColors.textPrimary,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: grande ? 14 : 12,
                  fontWeight: grande ? FontWeight.w600 : FontWeight.normal,
                )),
            Text(valor,
                style: TextStyle(
                  color: color,
                  fontSize: grande ? 16 : 13,
                  fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
                )),
          ],
        ),
      );

  Widget _chipTasa(String label, dynamic valor, Color color) {
    final num = double.tryParse(valor?.toString() ?? '0') ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        '$label: ${num > 0 ? num.toStringAsFixed(2) : "--"}',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Widget imagen en carrito ───────────────────────────────
class _ImagenCarrito extends StatelessWidget {
  final String url;
  final double size;

  const _ImagenCarrito({
    required this.url,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.inventory_2_outlined,
          color: AppColors.textHint,
          size: 20,
        ),
      );
}
