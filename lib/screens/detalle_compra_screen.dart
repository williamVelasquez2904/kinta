import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/compra_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';

class DetalleCompraScreen extends StatefulWidget {
  final UserModel user;
  final int compraIde;

  const DetalleCompraScreen({
    super.key,
    required this.user,
    required this.compraIde,
  });

  @override
  State<DetalleCompraScreen> createState() => _DetalleCompraScreenState();
}

class _DetalleCompraScreenState extends State<DetalleCompraScreen> {
  final _service = CompraService();
  bool _isLoading = true;
  bool _accionando = false;
  Map _compra = {};
  List _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.detalleCompra(
        usuaIde: widget.user.usuaIde,
        compraIde: widget.compraIde,
      );
      if (result['success'] == true) {
        setState(() {
          _compra = result['compra'];
          _items = result['items'];
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _confirmar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar recepción'),
        content: const Text(
          '¿Confirmas que recibiste todos los productos?\n\n'
          'Esto actualizará el inventario.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar Recepción'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _accionando = true);
    final result = await _service.confirmarCompra(
      usuaIde: widget.user.usuaIde,
      compraIde: widget.compraIde,
    );
    setState(() => _accionando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );
      if (result['success'] == true) _cargar();
    }
  }

  Future<void> _anular() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular compra'),
        content: const Text('¿Estás seguro de anular esta compra?\n\n'
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _accionando = true);
    final result = await _service.anularCompra(
      usuaIde: widget.user.usuaIde,
      compraIde: widget.compraIde,
    );
    setState(() => _accionando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );
      if (result['success'] == true) _cargar();
    }
  }

  String _labelEstado(dynamic estado) {
    switch (int.tryParse(estado.toString())) {
      case 0:
        return 'Pendiente';
      case 1:
        return 'Recibida';
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

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '-';
    final str = fecha.toString();
    if (str.length < 10) return str;
    return '${str.substring(8, 10)}/${str.substring(5, 7)}/${str.substring(0, 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final estado =
        int.tryParse(_compra['compra_estado']?.toString() ?? '0') ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_compra['compra_num'] ?? 'Detalle Compra'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Estado ───────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgEstado(estado),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          estado == 1
                              ? Icons.check_circle
                              : estado == 2
                                  ? Icons.cancel
                                  : Icons.schedule,
                          color: _colorEstado(estado),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _labelEstado(estado),
                              style: TextStyle(
                                color: _colorEstado(estado),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _compra['compra_num'] ?? '',
                              style: TextStyle(
                                  color: _colorEstado(estado), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Info cabecera ─────────────────────────
                  const Text('INFORMACIÓN',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      )),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _fila('Proveedor', _compra['prove_nombre'] ?? '-'),
                        _fila('RIF', _compra['prove_rif'] ?? '-'),
                        _fila('Teléfono', _compra['prove_telefono'] ?? '-'),
                        _fila('Fecha', _formatFecha(_compra['compra_fecha'])),
                        _fila('Documento', _compra['compra_documento'] ?? '-'),
                        _fila('Registrado por',
                            '${_compra['usua_nombre'] ?? ''} ${_compra['usua_apelli'] ?? ''}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Items ──────────────────────────────────
                  const Text('PRODUCTOS',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      )),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: List.generate(_items.length, (i) {
                        final item = _items[i];
                        final cant = double.tryParse(
                                item['detcomp_cantidad'].toString()) ??
                            0;
                        final costo =
                            double.tryParse(item['detcomp_costo'].toString()) ??
                                0;
                        final subtot = double.tryParse(
                                item['detcomp_subtotal'].toString()) ??
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
                                          item['detcomp_descripcion'] ?? '',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${cant.toStringAsFixed(0)} × ${FormatoNumero.monedaConSimbolo(costo)}',
                                          style: const TextStyle(
                                              color: AppColors.textHint,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    FormatoNumero.monedaConSimbolo(subtot),
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
                              const Divider(height: 1, color: AppColors.border),
                          ],
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Totales ────────────────────────────────
                  const Text('TOTALES',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      )),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _fila(
                            'Subtotal',
                            FormatoNumero.monedaConSimbolo(double.tryParse(
                                    _compra['compra_subtotal'].toString()) ??
                                0)),
                        _fila(
                            'Impuesto',
                            FormatoNumero.monedaConSimbolo(double.tryParse(
                                    _compra['compra_impuesto'].toString()) ??
                                0)),
                        _fila(
                          'TOTAL',
                          FormatoNumero.monedaConSimbolo(double.tryParse(
                                  _compra['compra_total'].toString()) ??
                              0),
                          negrita: true,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  if ((_compra['compra_observa'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('OBSERVACIONES',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        )),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        _compra['compra_observa'].toString(),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Acciones (solo si Pendiente) ──────────
                  if (estado == 0) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _accionando ? null : _confirmar,
                        icon: _accionando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'Confirmar Recepción',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _accionando ? null : _anular,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Anular Compra'),
                      ),
                    ),
                  ],

                  if (estado == 1)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              color: AppColors.success, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Inventario actualizado con esta compra',
                            style: TextStyle(
                                color: AppColors.success,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _fila(String label, String valor,
          {bool negrita = false, Color color = AppColors.textPrimary}) =>
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
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
          const Divider(height: 1, color: AppColors.border, indent: 16),
        ],
      );
}
