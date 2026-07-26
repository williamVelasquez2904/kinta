import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import '../utils/reporte_producto_pdf.dart';

class ReporteProductoScreen extends StatefulWidget {
  final UserModel user;
  const ReporteProductoScreen({super.key, required this.user});

  @override
  State<ReporteProductoScreen> createState() => _ReporteProductoScreenState();
}

class _ReporteProductoScreenState extends State<ReporteProductoScreen> {
  final _ventaService = VentaService();
  final _searchCtrl = TextEditingController();

  DateTime _fechaDesde = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaHasta = DateTime.now();

  bool _isLoading = false;
  bool _generandoPdf = false;
  bool _buscado = false;

  List _productos = [];
  List _ventas = [];
  List _resumen = [];
  bool _esAdmin = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fechaSql(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fechaDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
    if (fecha != null && mounted) {
      setState(() {
        if (esDesde) {
          _fechaDesde = fecha;
        } else {
          _fechaHasta = fecha;
        }
      });
    }
  }

  Future<void> _buscar() async {
    if (_searchCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un nombre o código de producto'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _buscado = false;
    });

    try {
      final result = await _ventaService.reporteProducto(
        usuaIde: widget.user.usuaIde,
        busqueda: _searchCtrl.text.trim(),
        fechaDesde: _fechaSql(_fechaDesde),
        fechaHasta: _fechaSql(_fechaHasta),
      );

      if (result['success'] == true) {
        setState(() {
          _productos = result['productos'] ?? [];
          _ventas = result['ventas'] ?? [];
          _resumen = result['resumen'] ?? [];
          _esAdmin = result['es_admin'] ?? false;
          _buscado = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _generarPdf() async {
    setState(() => _generandoPdf = true);

    try {
      final resultEmpresa = await _ventaService.obtenerEmpresa();
      final empresa =
          resultEmpresa['success'] == true ? resultEmpresa['empresa'] : {};

      final pdf = await ReporteProductoPdf.generar(
        empresa: empresa,
        nombreUsuario: widget.user.nombreCompleto,
        busqueda: _searchCtrl.text.trim(),
        fechaDesde: _fechaDisplay(_fechaDesde),
        fechaHasta: _fechaDisplay(_fechaHasta),
        esAdmin: _esAdmin,
        resumen: _resumen,
        ventas: _ventas,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'Reporte_Producto_${_fechaSql(_fechaDesde)}.pdf',
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
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /*title: const Text('Ventas por Producto'),*/
        title: const Text('Notas por Producto'),
      ),
      body: Column(
        children: [
          // ── Panel de filtros ─────────────────────────────
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
                const Text(
                  'BÚSQUEDA',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                // Campo de búsqueda
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  onSubmitted: (_) => _buscar(),
                  decoration: InputDecoration(
                    hintText: 'Nombre o código del producto...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _buscado = false;
                                _productos = [];
                                _ventas = [];
                                _resumen = [];
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 12),

                // Rango de fechas
                Row(
                  children: [
                    Expanded(
                      child: _campoFecha(
                          'Desde', _fechaDesde, () => _seleccionarFecha(true)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _campoFecha(
                          'Hasta', _fechaHasta, () => _seleccionarFecha(false)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _buscar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.bar_chart, size: 18),
                    label: const Text('Ver Reporte'),
                  ),
                ),
              ],
            ),
          ),

          // ── Resultados ───────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : !_buscado
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inventory_2_outlined,
                                color: AppColors.textHint, size: 52),
                            SizedBox(height: 12),
                            Text(
                              'Ingresa un producto y el rango\nde fechas para ver el reporte',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : _ventas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long_outlined,
                                    color: AppColors.textHint, size: 52),
                                const SizedBox(height: 12),
                                Text(
                                  'Sin Notas de "${_searchCtrl.text}"\nentre ${_fechaDisplay(_fechaDesde)} y ${_fechaDisplay(_fechaHasta)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              // ── Resumen por producto ──────
                              const Text(
                                'RESUMEN',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),

                              ..._resumen.map((r) {
                                final unidades = double.tryParse(
                                        r['total_unid'].toString()) ??
                                    0;
                                final monto = double.tryParse(
                                        r['total_monto'].toString()) ??
                                    0;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            AppColors.primary.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r['descripcion'] ?? '',
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${r['total_ventas']} facturas',
                                              style: const TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${unidades.toStringAsFixed(0)} uds',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          Text(
                                            FormatoNumero.monedaConSimbolo(
                                                monto),
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: 16),

                              // ── Detalle ventas ────────────
                              const Text(
                                'DETALLE DE NOTAS',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),

                              ..._ventas.map((v) {
                                final cantidad = double.tryParse(
                                        v['detfac_cantidad'].toString()) ??
                                    0;
                                final precio = double.tryParse(
                                        v['detfac_precio'].toString()) ??
                                    0;
                                final subtotal = double.tryParse(
                                        v['detfac_subtotal'].toString()) ??
                                    0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              v['factura_num'] ?? '',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              _fechaDisplay2(
                                                  v['factura_fecha']),
                                              style: const TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          v['clien_nombre1'] ?? '',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (_esAdmin) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Vendedor: ${v['usua_nombre'] ?? ''} ${v['usua_apelli'] ?? ''}',
                                            style: const TextStyle(
                                                color: AppColors.textHint,
                                                fontSize: 11),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _chip(
                                              '${cantidad.toStringAsFixed(0)} uds',
                                              AppColors.info,
                                            ),
                                            const SizedBox(width: 6),
                                            _chip(
                                              '× ${FormatoNumero.monedaConSimbolo(precio)}',
                                              AppColors.textSecondary,
                                            ),
                                            const Spacer(),
                                            Text(
                                              FormatoNumero.monedaConSimbolo(
                                                  subtotal),
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
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

      // ── FAB PDF ──────────────────────────────────────────
      floatingActionButton: _buscado && _ventas.isNotEmpty
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

  // ── Widgets auxiliares ───────────────────────────────────

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
                    _fechaDisplay(fecha),
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

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      );

  String _fechaDisplay2(dynamic fecha) {
    if (fecha == null) return '-';
    final str = fecha.toString();
    if (str.length < 10) return str;
    return '${str.substring(8, 10)}/${str.substring(5, 7)}/${str.substring(0, 4)}';
  }
}
