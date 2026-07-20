import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import 'reporte_pago_screen.dart';

class DetalleVentaScreen extends StatelessWidget {
  final UserModel user;
  final Map venta;
  final String clienteNombre;
  final double saldoCliente;
  final int clienteIde;

  const DetalleVentaScreen({
    super.key,
    required this.user,
    required this.venta,
    required this.clienteNombre,
    required this.saldoCliente,
    required this.clienteIde,
  });

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

  Color _colorVencimiento(dynamic diasVencido) {
    final dias = int.tryParse(diasVencido.toString()) ?? 0;
    if (dias <= 0) return AppColors.success;
    if (dias <= 30) return AppColors.warning;
    return AppColors.error;
  }

  String _labelVencimiento(dynamic diasVencido) {
    final dias = int.tryParse(diasVencido.toString()) ?? 0;
    if (dias <= 0) return 'Vigente — faltan ${dias.abs()} días';
    if (dias == 1) return 'Vencido hace 1 día';
    return 'Vencido hace $dias días';
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
    final saldo = double.tryParse(venta['saldo_calculado'].toString()) ?? 0;
    final abonos = double.tryParse(venta['total_abonos'].toString()) ?? 0;
    final monto = double.tryParse(venta['venta_monto'].toString()) ?? 0;
    final credito =
        double.tryParse(venta['venta_monto_credito'].toString()) ?? 0;
    final flete = double.tryParse(venta['venta_flete'].toString()) ?? 0;
    final desc = double.tryParse(venta['venta_porc_desc'].toString()) ?? 0;
    final asig = double.tryParse(venta['venta_porc_asig'].toString()) ?? 0;
    final condicion = _labelCondicion(venta['venta_condicion']);
    final colorVenc = _colorVencimiento(venta['dias_vencido']);
    final esCredito = int.tryParse(venta['venta_condicion'].toString()) == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Venta Nº ${venta['venta_num'] ?? '-'}'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportePagoScreen(
                    user: user,
                    clienteIde: clienteIde,
                    clienteNombre: clienteNombre,
                    saldoCliente: saldoCliente,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.payment, color: AppColors.primary, size: 18),
            label: const Text(
              'Reportar Pago',
              style: TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header cliente + estado ────────────────────
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cliente',
                                style: TextStyle(
                                    color: AppColors.textHint, fontSize: 11)),
                            Text(
                              clienteNombre,
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
                          color: condicion == 'Crédito'
                              ? AppColors.infoBg
                              : AppColors.successBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          condicion,
                          style: TextStyle(
                            color: condicion == 'Crédito'
                                ? AppColors.info
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Estado vencimiento (solo crédito)
                  if (esCredito) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorVenc.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorVenc.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: colorVenc, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _labelVencimiento(venta['dias_vencido']),
                            style: TextStyle(
                              color: colorVenc,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Sección: Resumen financiero ────────────────
            _seccion('RESUMEN FINANCIERO'),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _filaDato(
                    'Monto total',
                    FormatoNumero.monedaConSimbolo(monto),
                    icono: Icons.attach_money,
                  ),
                  _divider(),
                  _filaDato(
                    'Monto crédito',
                    FormatoNumero.monedaConSimbolo(credito),
                    icono: Icons.credit_card,
                  ),
                  _divider(),
                  _filaDato(
                    'Total abonos',
                    FormatoNumero.monedaConSimbolo(abonos),
                    icono: Icons.payments_outlined,
                    color: AppColors.success,
                  ),
                  _divider(),
                  _filaDato(
                    'Saldo deudor',
                    FormatoNumero.monedaConSimbolo(saldo),
                    icono: Icons.account_balance_wallet,
                    color: saldo > 0 ? AppColors.error : AppColors.success,
                    negrita: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Sección: Fechas y crédito ──────────────────
            _seccion('FECHAS Y CRÉDITO'),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _filaDato(
                    'Fecha de venta',
                    _formatFecha(venta['venta_fecha']),
                    icono: Icons.calendar_today,
                  ),
                  _divider(),
                  _filaDato(
                    'Días de crédito',
                    '${venta['venta_dias_credito'] ?? 0} días',
                    icono: Icons.timer_outlined,
                  ),
                  _divider(),
                  _filaDato(
                    'Fecha vencimiento',
                    _formatFecha(venta['fecha_vencimiento']),
                    icono: Icons.event_busy,
                    color: esCredito ? colorVenc : AppColors.textPrimary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Sección: Descuentos y asignación ──────────
            _seccion('DESCUENTOS Y ASIGNACIÓN'),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _filaDato(
                    'Flete',
                    FormatoNumero.monedaConSimbolo(flete),
                    icono: Icons.local_shipping_outlined,
                  ),
                  _divider(),
                  _filaDato(
                    '% Descuento',
                    '${desc.toStringAsFixed(2)}%',
                    icono: Icons.discount_outlined,
                  ),
                  _divider(),
                  _filaDato(
                    '% Asignación',
                    '${asig.toStringAsFixed(2)}%',
                    icono: Icons.pie_chart_outline,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Botón Reportar Pago ────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportePagoScreen(
                        user: user,
                        clienteIde: clienteIde,
                        clienteNombre: clienteNombre,
                        saldoCliente: saldoCliente,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.payment),
                label: const Text('Reportar Pago'),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo) {
    return Row(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
    );
  }

  Widget _filaDato(
    String label,
    String valor, {
    IconData? icono,
    Color? color,
    bool negrita = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, color: AppColors.textHint, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
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
