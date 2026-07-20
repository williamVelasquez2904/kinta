import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReporteProductoPdf {
  static Future<pw.Document> generar({
    required Map empresa,
    required String nombreUsuario,
    required String busqueda,
    required String fechaDesde,
    required String fechaHasta,
    required bool esAdmin,
    required List resumen,
    required List ventas,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      empresa['empresa_nombre'] ?? '',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'RIF: ${empresa['empresa_rif'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'REPORTE POR PRODUCTO',
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '$fechaDesde al $fechaHasta',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1),
            pw.Text(
              'Producto: $busqueda  —  Generado por: $nombreUsuario',
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          // ── Resumen por producto ─────────────────────────
          if (resumen.isNotEmpty) ...[
            pw.Text(
              'RESUMEN',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.5),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _celdaH('Producto'),
                    _celdaH('Unidades'),
                    _celdaH('Ventas'),
                    _celdaH('Monto Total'),
                  ],
                ),
                ...resumen.map((r) => pw.TableRow(
                      children: [
                        _celda(r['descripcion'] ?? ''),
                        _celda(
                          (double.tryParse(r['total_unid'].toString()) ?? 0)
                              .toStringAsFixed(0),
                          align: pw.Alignment.center,
                        ),
                        _celda(
                          '${r['total_ventas']}',
                          align: pw.Alignment.center,
                        ),
                        _celda(
                          _moneda(r['total_monto']),
                          align: pw.Alignment.centerRight,
                          negrita: true,
                        ),
                      ],
                    )),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // ── Detalle de ventas ────────────────────────────
          pw.Text(
            'DETALLE DE VENTAS',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),

          if (ventas.isEmpty)
            pw.Text(
              'Sin ventas en el período seleccionado.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(0.8),
                5: const pw.FlexColumnWidth(1),
                6: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _celdaH('Factura'),
                    _celdaH('Fecha'),
                    _celdaH('Cliente'),
                    if (esAdmin) _celdaH('Vendedor'),
                    _celdaH('Cant.'),
                    _celdaH('Precio'),
                    _celdaH('Subtotal'),
                  ],
                ),
                ...ventas.map((v) => pw.TableRow(
                      children: [
                        _celda(v['factura_num'] ?? ''),
                        _celda(_formatFecha(v['factura_fecha'])),
                        _celda(v['clien_nombre1'] ?? ''),
                        if (esAdmin)
                          _celda(
                            '${v['usua_nombre'] ?? ''} ${v['usua_apelli'] ?? ''}',
                          ),
                        _celda(
                          (double.tryParse(v['detfac_cantidad'].toString()) ??
                                  0)
                              .toStringAsFixed(0),
                          align: pw.Alignment.center,
                        ),
                        _celda(
                          _moneda(v['detfac_precio']),
                          align: pw.Alignment.centerRight,
                        ),
                        _celda(
                          _moneda(v['detfac_subtotal']),
                          align: pw.Alignment.centerRight,
                          negrita: true,
                        ),
                      ],
                    )),
              ],
            ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _celdaH(String texto) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(texto,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _celda(
    String texto, {
    pw.Alignment align = pw.Alignment.centerLeft,
    bool negrita = false,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Align(
          alignment: align,
          child: pw.Text(
            texto,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      );

  static String _moneda(dynamic valor) {
    final num = double.tryParse(valor.toString()) ?? 0;
    return '\$${num.toStringAsFixed(2)}';
  }

  static String _formatFecha(dynamic fecha) {
    if (fecha == null) return '-';
    final str = fecha.toString();
    if (str.length < 10) return str;
    return '${str.substring(8, 10)}/${str.substring(5, 7)}/${str.substring(0, 4)}';
  }
}
