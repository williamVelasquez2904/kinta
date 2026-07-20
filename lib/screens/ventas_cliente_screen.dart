import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import 'reporte_pago_screen.dart';
import 'detalle_venta_screen.dart';
import '../utils/app_config.dart';

class VentasClienteScreen extends StatefulWidget {
  final UserModel user;
  final int clienteIde;
  final String clienteNombre;
  final double saldoCliente;

  const VentasClienteScreen({
    super.key,
    required this.user,
    required this.clienteIde,
    required this.clienteNombre,
    required this.saldoCliente,
  });

  @override
  State<VentasClienteScreen> createState() => _VentasClienteScreenState();
}

class _VentasClienteScreenState extends State<VentasClienteScreen> {
  bool _isLoading = true;
  String _errorMsg = '';
  List _ventas = [];
  double _totalMonto = 0;
  double _totalAbonos = 0;
  double _totalSaldo = 0;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.api('api_ventas_cliente.php')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'cliente_ide': widget.clienteIde}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _ventas = data['ventas'];
            _totalMonto = double.tryParse(data['total_monto'].toString()) ?? 0;
            _totalAbonos =
                double.tryParse(data['total_abonos'].toString()) ?? 0;
            _totalSaldo = double.tryParse(data['total_saldo'].toString()) ?? 0;
          });
        } else {
          setState(() => _errorMsg = data['message']);
        }
      } else {
        setState(() => _errorMsg = 'Error del servidor ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error de conexión: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _colorVencimiento(dynamic diasVencido) {
    final dias = int.tryParse(diasVencido.toString()) ?? 0;
    if (dias <= 0) return AppColors.success; // vigente
    if (dias <= 30) return AppColors.warning; // vencido reciente
    return AppColors.error; // vencido crítico
  }

  String _labelVencimiento(dynamic diasVencido) {
    final dias = int.tryParse(diasVencido.toString()) ?? 0;
    if (dias <= 0) return 'Vigente (${dias.abs()} días)';
    if (dias == 1) return 'Vencido hace 1 día';
    return 'Vencido hace $dias días';
  }

  String _formatFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '-';
    try {
      final d = DateTime.parse(fecha);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return fecha.substring(0, 10);
    }
  }

  String _labelCondicion(dynamic condicion) {
    final c = int.tryParse(condicion.toString()) ?? -1;
    switch (c) {
      case 0:
        return 'Contado';
      case 1:
        return 'Crédito';
      default:
        return 'N/D';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.clienteNombre,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Botón Reportar Pago en AppBar
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportePagoScreen(
                    user: widget.user,
                    clienteIde: widget.clienteIde,
                    clienteNombre: widget.clienteNombre,
                    saldoCliente: widget.saldoCliente,
                  ),
                ),
              );
              _cargarVentas();
            },
            icon: const Icon(Icons.payment, color: AppColors.primary, size: 18),
            label: const Text(
              'Reportar Pago',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVentas,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Resumen 3 columnas ─────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clienteNombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _resumenCol(
                        'Total Ventas',
                        FormatoNumero.monedaConSimbolo(_totalMonto),
                        AppColors.info,
                      ),
                    ),
                    Expanded(
                      child: _resumenCol(
                        'Total Abonos',
                        FormatoNumero.monedaConSimbolo(_totalAbonos),
                        AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _resumenCol(
                        'Saldo Deudor',
                        FormatoNumero.monedaConSimbolo(_totalSaldo),
                        AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Contador ventas ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_ventas.length} ventas',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_ventas.isNotEmpty)
                  Text(
                    'Toca una venta para ver detalles',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Lista ventas ───────────────────────────────
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
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _errorMsg,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _cargarVentas,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _ventas.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long,
                                    color: AppColors.textHint, size: 52),
                                SizedBox(height: 12),
                                Text('Sin ventas registradas',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 15)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _ventas.length,
                            itemBuilder: (context, index) {
                              final v = _ventas[index];
                              final saldo = double.tryParse(
                                      v['saldo_calculado'].toString()) ??
                                  0;
                              final abonos = double.tryParse(
                                      v['total_abonos'].toString()) ??
                                  0;
                              final monto = double.tryParse(
                                      v['venta_monto'].toString()) ??
                                  0;
                              final colorVenc =
                                  _colorVencimiento(v['dias_vencido']);
                              final condicion =
                                  _labelCondicion(v['venta_condicion']);

                              return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetalleVentaScreen(
                                          user: widget.user,
                                          venta: v,
                                          clienteNombre: widget.clienteNombre,
                                          saldoCliente: widget.saldoCliente,
                                          clienteIde: widget.clienteIde,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: saldo > 0
                                            ? colorVenc.withOpacity(0.4)
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Fila 1: Nº + Condición + Saldo
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.receipt_outlined,
                                                    color: AppColors.textHint,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Nº ${v['venta_num'] ?? '-'}',
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: condicion ==
                                                              'Crédito'
                                                          ? AppColors.infoBg
                                                          : AppColors.successBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      condicion,
                                                      style: TextStyle(
                                                        color: condicion ==
                                                                'Crédito'
                                                            ? AppColors.info
                                                            : AppColors.success,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                FormatoNumero.monedaConSimbolo(
                                                    saldo),
                                                style: TextStyle(
                                                  color: saldo > 0
                                                      ? AppColors.error
                                                      : AppColors.success,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 10),
                                          const Divider(
                                              color: AppColors.border,
                                              height: 1),
                                          const SizedBox(height: 10),

                                          // Fila 2: Fechas
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _infoItem(
                                                  Icons.calendar_today,
                                                  'Fecha venta',
                                                  _formatFecha(
                                                      v['venta_fecha']),
                                                ),
                                              ),
                                              Expanded(
                                                child: _infoItem(
                                                  Icons.event_busy,
                                                  'Vencimiento',
                                                  _formatFecha(
                                                      v['fecha_vencimiento']),
                                                ),
                                              ),
                                              Expanded(
                                                child: _infoItem(
                                                  Icons.timer_outlined,
                                                  'Días crédito',
                                                  '${v['venta_dias_credito'] ?? 0} días',
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 10),

                                          // Fila 3: Montos
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _infoItem(
                                                  Icons.attach_money,
                                                  'Monto',
                                                  FormatoNumero
                                                      .monedaConSimbolo(monto),
                                                ),
                                              ),
                                              Expanded(
                                                child: _infoItem(
                                                  Icons.payments_outlined,
                                                  'Abonos',
                                                  FormatoNumero
                                                      .monedaConSimbolo(abonos),
                                                ),
                                              ),
                                              Expanded(
                                                child: _infoItem(
                                                  Icons.account_balance_wallet,
                                                  'Saldo',
                                                  FormatoNumero
                                                      .monedaConSimbolo(saldo),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Estado vencimiento
                                          if (int.tryParse(v['venta_condicion']
                                                  .toString()) ==
                                              1) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                color:
                                                    colorVenc.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    color: colorVenc,
                                                    size: 13,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _labelVencimiento(
                                                        v['dias_vencido']),
                                                    style: TextStyle(
                                                      color: colorVenc,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ));
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _resumenCol(String label, String valor, Color color) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textHint, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _infoItem(IconData icono, String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: AppColors.textHint, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textHint, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
