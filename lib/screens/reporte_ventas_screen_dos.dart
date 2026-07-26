import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../services/auditoria_service.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import '../utils/reporte_ventas_pdf.dart';
import 'detalle_factura_screen.dart';

class ReporteVentasScreen extends StatefulWidget {
  final UserModel user;
  const ReporteVentasScreen({super.key, required this.user});

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen> {
  final _ventaService = VentaService();

  DateTime _fechaDesde = DateTime.now().subtract(const Duration(days: 7));
  DateTime _fechaHasta = DateTime.now();

  bool _isLoading = false;
  bool _generandoPdf = false;
  String _errorMsg = '';

  bool _esAdmin = false;
  int _totalFacturas = 0;
  double _totalGeneral = 0;
  double _totalCosto = 0;
  double _totalGanancia = 0;
  List _resumenVendedores = [];
  List _facturas = [];

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  String _fechaSql(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _buscar() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    final result = await _ventaService.reporteVentas(
      usuaIde: widget.user.usuaIde,
      fechaDesde: _fechaSql(_fechaDesde),
      fechaHasta: _fechaSql(_fechaHasta),
    );

    if (result['success'] == true) {
      setState(() {
        _esAdmin = result['es_admin'] ?? false;
        _totalFacturas = result['total_facturas'] ?? 0;
        _totalGeneral =
            double.tryParse(result['total_general'].toString()) ?? 0;
        _totalCosto = double.tryParse(result['total_costo'].toString()) ?? 0;
        _totalGanancia =
            double.tryParse(result['total_ganancia'].toString()) ?? 0;
        _resumenVendedores = result['resumen_vendedores'] ?? [];
        _facturas = result['facturas'] ?? [];
      });
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error desconocido');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esDesde ? _fechaDesde : _fechaHasta,
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
        ),
        child: child!,
      ),
    );

    if (fecha != null) {
      setState(() {
        if (esDesde) {
          _fechaDesde = fecha;
        } else {
          _fechaHasta = fecha;
        }
      });
    }
  }

  Future<void> _generarPdf() async {
    setState(() => _generandoPdf = true);

    try {
      final resultEmpresa = await _ventaService.obtenerEmpresa();
      final empresa =
          resultEmpresa['success'] == true ? resultEmpresa['empresa'] : {};

      final pdf = await ReporteVentasPdf.generar(
        empresa: empresa,
        fechaDesde: _formatFecha(_fechaDesde),
        fechaHasta: _formatFecha(_fechaHasta),
        nombreUsuario: widget.user.nombreCompleto,
        esAdmin: _esAdmin,
        totalGeneral: _totalGeneral,
        totalCosto: _totalCosto,
        totalGanancia: _totalGanancia,
        totalFacturas: _totalFacturas,
        resumenVendedores: _resumenVendedores,
        facturas: _facturas,
      );

      await AuditoriaService()
          .exportarReporte(widget.user, 'Reporte de Ventas');

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name:
            'Reporte_Ventas_${_fechaSql(_fechaDesde)}_${_fechaSql(_fechaHasta)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _generandoPdf = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /*title: const Text('Reporte de Ventas'),*/
        title: const Text('Reporte de Notas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _buscar,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Selector de fechas ─────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _campoFecha(
                        'Desde',
                        _fechaDesde,
                        () => _seleccionarFecha(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _campoFecha(
                        'Hasta',
                        _fechaHasta,
                        () => _seleccionarFecha(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _buscar,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Buscar'),
                  ),
                ),
              ],
            ),
          ),

          // ── Contenido ─────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMsg.isNotEmpty
                    ? Center(
                        child: Text(_errorMsg,
                            style: const TextStyle(color: AppColors.error)))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // ── Fila 1: Total vendido + Facturas
                          Row(
                            children: [
                              Expanded(
                                child: _tarjetaResumen(
                                  'Total Notas',
                                  FormatoNumero.monedaConSimbolo(_totalGeneral),
                                  AppColors.primary,
                                  Icons.attach_money,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _tarjetaResumen(
                                  'Facturas',
                                  '$_totalFacturas',
                                  AppColors.info,
                                  Icons.receipt_long,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // ── Fila 2: Costo + Ganancia
                          Row(
                            children: [
                              Expanded(
                                child: _tarjetaResumen(
                                  'Costo Total',
                                  FormatoNumero.monedaConSimbolo(_totalCosto),
                                  AppColors.warning,
                                  Icons.price_check,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _tarjetaResumen(
                                  'Ganancia',
                                  FormatoNumero.monedaConSimbolo(
                                      _totalGanancia),
                                  _totalGanancia >= 0
                                      ? AppColors.success
                                      : AppColors.error,
                                  _totalGanancia >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Resumen por vendedor (admin) ──
                          if (_esAdmin && _resumenVendedores.isNotEmpty) ...[
                            const Text(
                              'VENTAS POR VENDEDOR',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: List.generate(
                                    _resumenVendedores.length, (i) {
                                  final v = _resumenVendedores[i];
                                  final total =
                                      double.tryParse(v['total'].toString()) ??
                                          0;
                                  final ganancia = double.tryParse(
                                          (v['ganancia'] ?? 0).toString()) ??
                                      0;

                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  AppColors.primaryBg,
                                              child: Text(
                                                '${i + 1}',
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    v['vendedor'] ?? '',
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${v['cantidad']} facturas',
                                                    style: const TextStyle(
                                                      color: AppColors.textHint,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  FormatoNumero
                                                      .monedaConSimbolo(total),
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  'G: ${FormatoNumero.monedaConSimbolo(ganancia)}',
                                                  style: TextStyle(
                                                    color: ganancia >= 0
                                                        ? AppColors.success
                                                        : AppColors.error,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (i < _resumenVendedores.length - 1)
                                        const Divider(
                                            height: 1, color: AppColors.border),
                                    ],
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Detalle de facturas ───────────
                          const Text(
                            'FACTURAS',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_facturas.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Center(
                                child: Text(
                                  'Sin ventas en este período',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            )
                          else
                            ...List.generate(_facturas.length, (i) {
                              final f = _facturas[i];
                              final total = double.tryParse(
                                      f['factura_total'].toString()) ??
                                  0;
                              final ganancia = double.tryParse(
                                      (f['ganancia'] ?? 0).toString()) ??
                                  0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ListTile(
                                  dense: true,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetalleFacturaScreen(
                                          facturaIde: int.tryParse(
                                                  f['factura_ide']
                                                      .toString()) ??
                                              0,
                                        ),
                                      ),
                                    );
                                  },
                                  title: Text(
                                    f['factura_num'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _esAdmin
                                            ? '${f['clien_nombre1']} · ${f['usua_nombre']} ${f['usua_apelli']}'
                                            : f['clien_nombre1'] ?? '',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _labelEstado(f['factura_estado']),
                                        style: TextStyle(
                                          color:
                                              _colorEstado(f['factura_estado']),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        FormatoNumero.monedaConSimbolo(total),
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'G: ${FormatoNumero.monedaConSimbolo(ganancia)}',
                                        style: TextStyle(
                                          color: ganancia >= 0
                                              ? AppColors.success
                                              : AppColors.error,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                          const SizedBox(height: 90),
                        ],
                      ),
          ),
        ],
      ),

      // ── Botón PDF ─────────────────────────────────────────
      floatingActionButton: _facturas.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _generandoPdf ? null : _generarPdf,
              backgroundColor: AppColors.primary,
              icon: _generandoPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: Text(
                _generandoPdf ? 'Generando...' : 'Generar PDF',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _campoFecha(String label, DateTime fecha, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: AppColors.textHint, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 10)),
                  Text(
                    _formatFecha(fecha),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaResumen(
      String label, String valor, Color color, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style:
                      const TextStyle(color: AppColors.textHint, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
