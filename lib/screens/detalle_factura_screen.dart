// ════════════════════════════════════════════════════════════
// detalle_factura_screen.dart
// ════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import 'nota_entrega_screen.dart';

class DetalleFacturaScreen extends StatefulWidget {
  final int facturaIde;
  const DetalleFacturaScreen({super.key, required this.facturaIde});

  @override
  State<DetalleFacturaScreen> createState() => _DetalleFacturaScreenState();
}

class _DetalleFacturaScreenState extends State<DetalleFacturaScreen> {
  final _ventaService = VentaService();

  bool _isLoading = true;
  String _errorMsg = '';
  Map _factura = {};
  List _items = [];

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    final result = await _ventaService.detalleFactura(widget.facturaIde);

    if (result['success'] == true) {
      setState(() {
        _factura = result['factura'];
        _items = result['items'];
      });
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error desconocido');
    }

    setState(() => _isLoading = false);
  }

  String _formatFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '-';
    try {
      final d = DateTime.parse(fecha);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return fecha.length >= 10 ? fecha.substring(0, 10) : fecha;
    }
  }

  String _labelEstado(dynamic estado) {
    switch (int.tryParse(estado.toString())) {
      case 0:
        return 'Pendiente';
      case 1:
        return 'Aprobada';
      case 2:
        return 'Anulada';
      default:
        return 'N/D';
    }
  }

  Color _colorEstado(dynamic estado) {
    switch (int.tryParse(estado.toString())) {
      case 0:
        return AppColors.warning;
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  Color _bgEstado(dynamic estado) {
    switch (int.tryParse(estado.toString())) {
      case 0:
        return AppColors.warningBg;
      case 1:
        return AppColors.successBg;
      case 2:
        return AppColors.errorBg;
      default:
        return AppColors.surfaceAlt;
    }
  }

  String _labelCondicion(dynamic c) {
    return int.tryParse(c.toString()) == 1 ? 'Crédito' : 'Contado';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_factura['factura_num'] ?? 'Detalle Venta'),
        actions: [
          if (_factura.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Imprimir',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotaEntregaScreen(
                      facturaIde: widget.facturaIde,
                      facturaNum: _factura['factura_num'] ?? '',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMsg.isNotEmpty
              ? Center(
                  child: Text(_errorMsg,
                      style: const TextStyle(color: AppColors.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Cliente',
                                          style: TextStyle(
                                              color: AppColors.textHint,
                                              fontSize: 11)),
                                      Text(
                                        _factura['clien_nombre1'] ?? '',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        _bgEstado(_factura['factura_estado']),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _labelEstado(_factura['factura_estado']),
                                    style: TextStyle(
                                      color: _colorEstado(
                                          _factura['factura_estado']),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: AppColors.textHint, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  _formatFecha(_factura['factura_fecha']),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.payments_outlined,
                                    color: AppColors.textHint, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  _labelCondicion(
                                      _factura['factura_condicion']),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                ),
                                if (int.tryParse(_factura['factura_condicion']
                                            .toString()) ==
                                        1 &&
                                    _factura['factura_dias_credito'] !=
                                        null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${_factura['factura_dias_credito']} días)',
                                    style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Items ─────────────────────────────
                      const Text('Productos',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          )),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: List.generate(_items.length, (i) {
                            final item = _items[i];
                            final cant = double.tryParse(
                                    item['detfac_cantidad'].toString()) ??
                                0;
                            final precio = double.tryParse(
                                    item['detfac_precio'].toString()) ??
                                0;
                            final desc = double.tryParse(
                                    item['detfac_descuento'].toString()) ??
                                0;
                            final subtotal = double.tryParse(
                                    item['detfac_subtotal'].toString()) ??
                                0;

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['detfac_descripcion'] ?? '',
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${cant.toStringAsFixed(2)} x '
                                              '${FormatoNumero.monedaConSimbolo(precio)}'
                                              '${desc > 0 ? '  (-${desc.toStringAsFixed(0)}%)' : ''}',
                                              style: const TextStyle(
                                                color: AppColors.textHint,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        FormatoNumero.monedaConSimbolo(
                                            subtotal),
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (i < _items.length - 1)
                                  const Divider(
                                      height: 1, color: AppColors.border),
                              ],
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Totales ───────────────────────────
                      const Text('Totales',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          )),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _filaTotal(
                                'Subtotal', _factura['factura_subtotal']),
                            _divider(),
                            _filaTotal(
                                'Descuento (%)', _factura['factura_descuento'],
                                esPorcentaje: true),
                            _divider(),
                            _filaTotal('Flete', _factura['factura_flete']),
                            _divider(),
                            _filaTotal(
                                'Impuesto', _factura['factura_impuesto']),
                            _divider(),
                            _filaTotal('Total', _factura['factura_total'],
                                negrita: true, color: AppColors.primary),
                            _divider(),
                            _filaTotal('Abono inicial',
                                _factura['factura_abono_inicial'],
                                color: AppColors.success),
                            _divider(),
                            _filaTotal('Saldo', _factura['factura_saldo'],
                                negrita: true,
                                color: (double.tryParse(
                                                _factura['factura_saldo']
                                                    .toString()) ??
                                            0) >
                                        0
                                    ? AppColors.error
                                    : AppColors.success),
                          ],
                        ),
                      ),

                      if ((_factura['factura_observa'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Observaciones',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            )),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _factura['factura_observa'],
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── Botón imprimir ──────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotaEntregaScreen(
                                  facturaIde: widget.facturaIde,
                                  facturaNum: _factura['factura_num'] ?? '',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Imprimir Nota de Entrega'),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _filaTotal(
    String label,
    dynamic valor, {
    bool esPorcentaje = false,
    bool negrita = false,
    Color color = AppColors.textPrimary,
  }) {
    final num = double.tryParse(valor.toString()) ?? 0;
    final texto = esPorcentaje
        ? '${num.toStringAsFixed(2)}%'
        : FormatoNumero.monedaConSimbolo(num);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: AppColors.border, indent: 16);
}
