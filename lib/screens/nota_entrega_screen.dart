import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import '../utils/nota_entrega_pdf.dart';

class NotaEntregaScreen extends StatefulWidget {
  final int facturaIde;
  final String facturaNum;

  const NotaEntregaScreen({
    super.key,
    required this.facturaIde,
    required this.facturaNum,
  });

  @override
  State<NotaEntregaScreen> createState() => _NotaEntregaScreenState();
}

class _NotaEntregaScreenState extends State<NotaEntregaScreen> {
  final _ventaService = VentaService();

  bool _isLoading = true;
  String _errorMsg = '';
  Map _factura = {};
  List _items = [];
  Map _empresa = {};

  bool _generandoCarta = false;
  bool _generandoComanda = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    final resultFactura = await _ventaService.detalleFactura(widget.facturaIde);
    final resultEmpresa = await _ventaService.obtenerEmpresa();

    if (resultFactura['success'] == true) {
      setState(() {
        _factura = resultFactura['factura'];
        _items = resultFactura['items'];
      });
    } else {
      setState(() => _errorMsg = resultFactura['message'] ?? 'Error');
    }

    if (resultEmpresa['success'] == true) {
      setState(() => _empresa = resultEmpresa['empresa']);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _imprimirCarta() async {
    setState(() => _generandoCarta = true);
    try {
      final pdf = await NotaEntregaPdf.generarCarta(
        empresa: _empresa,
        factura: _factura,
        items: _items,
      );
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'Nota_${widget.facturaNum}.pdf',
      );
    } catch (e) {
      _mostrarError('Error al generar PDF: $e');
    } finally {
      setState(() => _generandoCarta = false);
    }
  }

  Future<void> _imprimirComanda() async {
    setState(() => _generandoComanda = true);
    try {
      final pdf = await NotaEntregaPdf.generarComanda(
        empresa: _empresa,
        factura: _factura,
        items: _items,
      );
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'Comanda_${widget.facturaNum}.pdf',
      );
    } catch (e) {
      _mostrarError('Error al generar PDF: $e');
    } finally {
      setState(() => _generandoComanda = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nota de Entrega'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMsg.isNotEmpty
              ? Center(
                  child: Text(_errorMsg,
                      style: const TextStyle(color: AppColors.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ── Confirmación ────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.success, size: 56),
                            const SizedBox(height: 12),
                            const Text(
                              '¡Venta registrada!',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.facturaNum,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Resumen ──────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _filaResumen(
                                'Cliente', _factura['clien_nombre1'] ?? ''),
                            _filaResumen(
                                'Total',
                                FormatoNumero.monedaConSimbolo(double.tryParse(
                                        _factura['factura_total'].toString()) ??
                                    0),
                                color: AppColors.primary,
                                negrita: true),
                            _filaResumen(
                              'Productos',
                              '${_items.length} items',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'SELECCIONA EL FORMATO DE IMPRESIÓN',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Opción Carta ─────────────────────
                      _opcionImpresion(
                        icono: Icons.description_outlined,
                        titulo: 'Nota de Entrega',
                        subtitulo: 'Formato carta (8.5" x 11")',
                        loading: _generandoCarta,
                        onTap: _imprimirCarta,
                      ),

                      const SizedBox(height: 12),

                      // ── Opción Comanda ───────────────────
                      _opcionImpresion(
                        icono: Icons.receipt_long,
                        titulo: 'Comanda',
                        subtitulo: 'Formato ticket 55mm',
                        loading: _generandoComanda,
                        onTap: _imprimirComanda,
                      ),

                      const SizedBox(height: 24),

                      TextButton(
                        onPressed: () => Navigator.popUntil(
                            context, (route) => route.isFirst),
                        child: const Text('Finalizar'),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _filaResumen(
    String label,
    String valor, {
    Color color = AppColors.textPrimary,
    bool negrita = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _opcionImpresion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2)),
                    )
                  : Icon(icono, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(subtitulo,
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.print_outlined,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
