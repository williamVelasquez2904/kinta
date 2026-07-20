import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReporteVentasPdf {
  static Future<pw.Document> generar({
    required Map empresa,
    required String fechaDesde,
    required String fechaHasta,
    required String nombreUsuario,
    required bool esAdmin,
    required double totalGeneral,
    required double totalCosto,
    required double totalGanancia,
    required int totalFacturas,
    required List resumenVendedores,
    required List facturas,
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
                      'REPORTE DE VENTAS',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '$fechaDesde al $fechaHasta',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 4),
            pw.Text(
              esAdmin
                  ? 'Reporte general — Generado por: $nombreUsuario'
                  : 'Vendedor: $nombreUsuario',
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
          // ── Fila 1: Total vendido + Facturas ─────────────
          pw.Row(
            children: [
              _tarjetaResumen('Total Vendido', _moneda(totalGeneral)),
              pw.SizedBox(width: 8),
              _tarjetaResumen('Facturas', '$totalFacturas'),
            ],
          ),

          pw.SizedBox(height: 8),

          // ── Fila 2: Costo + Ganancia ──────────────────────
          pw.Row(
            children: [
              _tarjetaResumen(
                'Costo Total',
                _moneda(totalCosto),
                color: PdfColors.orange800,
              ),
              pw.SizedBox(width: 8),
              _tarjetaResumen(
                'Ganancia',
                _moneda(totalGanancia),
                color:
                    totalGanancia >= 0 ? PdfColors.green700 : PdfColors.red700,
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── Resumen por vendedor (admin) ──────────────────
          if (esAdmin && resumenVendedores.isNotEmpty) ...[
            pw.Text(
              'VENTAS POR VENDEDOR',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(0.8),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _celdaHeader('Vendedor'),
                    _celdaHeader('Fact.'),
                    _celdaHeader('Vendido'),
                    _celdaHeader('Costo'),
                    _celdaHeader('Ganancia'),
                  ],
                ),
                ...resumenVendedores.map((v) {
                  final ganancia =
                      double.tryParse((v['ganancia'] ?? 0).toString()) ?? 0;
                  return pw.TableRow(
                    children: [
                      _celda(v['vendedor'] ?? ''),
                      _celda('${v['cantidad']}', align: pw.Alignment.center),
                      _celda(_moneda(v['total']),
                          align: pw.Alignment.centerRight),
                      _celda(_moneda(v['costo'] ?? 0),
                          align: pw.Alignment.centerRight),
                      _celda(
                        _moneda(ganancia),
                        align: pw.Alignment.centerRight,
                        color: ganancia >= 0
                            ? PdfColors.green700
                            : PdfColors.red700,
                        negrita: true,
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // ── Detalle de facturas ───────────────────────────
          pw.Text(
            'DETALLE DE FACTURAS',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),

          if (facturas.isEmpty)
            pw.Text(
              'Sin ventas en el período seleccionado.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: esAdmin
                  ? {
                      0: const pw.FlexColumnWidth(1.2),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(2.2),
                      3: const pw.FlexColumnWidth(1.8),
                      4: const pw.FlexColumnWidth(0.8),
                      5: const pw.FlexColumnWidth(1.2),
                      6: const pw.FlexColumnWidth(1.2),
                      7: const pw.FlexColumnWidth(1.2),
                    }
                  : {
                      0: const pw.FlexColumnWidth(1.2),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(3),
                      3: const pw.FlexColumnWidth(0.8),
                      4: const pw.FlexColumnWidth(1.2),
                      5: const pw.FlexColumnWidth(1.2),
                      6: const pw.FlexColumnWidth(1.2),
                    },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _celdaHeader('Factura'),
                    _celdaHeader('Fecha'),
                    _celdaHeader('Cliente'),
                    if (esAdmin) _celdaHeader('Vendedor'),
                    _celdaHeader('Est.'),
                    _celdaHeader('Total'),
                    _celdaHeader('Costo'),
                    _celdaHeader('Ganancia'),
                  ],
                ),
                ...facturas.map((f) {
                  final total =
                      double.tryParse(f['factura_total'].toString()) ?? 0;
                  final costo =
                      double.tryParse((f['costo_total'] ?? 0).toString()) ?? 0;
                  final ganancia =
                      double.tryParse((f['ganancia'] ?? 0).toString()) ?? 0;

                  return pw.TableRow(
                    children: [
                      _celda(f['factura_num'] ?? ''),
                      _celda(_formatFecha(f['factura_fecha'])),
                      _celda(f['clien_nombre1'] ?? ''),
                      if (esAdmin)
                        _celda(
                          '${f['usua_nombre'] ?? ''} ${f['usua_apelli'] ?? ''}',
                        ),
                      _celda(
                        _labelEstado(f['factura_estado']),
                        align: pw.Alignment.center,
                      ),
                      _celda(_moneda(total), align: pw.Alignment.centerRight),
                      _celda(_moneda(costo),
                          align: pw.Alignment.centerRight,
                          color: PdfColors.orange800),
                      _celda(
                        _moneda(ganancia),
                        align: pw.Alignment.centerRight,
                        color: ganancia >= 0
                            ? PdfColors.green700
                            : PdfColors.red700,
                        negrita: true,
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );

    return pdf;
  }

  // ── Helpers ──────────────────────────────────────────────

  static pw.Widget _tarjetaResumen(
    String label,
    String valor, {
    PdfColor color = PdfColors.black,
  }) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(
                valor,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );

  static pw.Widget _celdaHeader(String texto) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(texto,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _celda(
    String texto, {
    pw.Alignment align = pw.Alignment.centerLeft,
    PdfColor color = PdfColors.black,
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
              color: color,
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

  static String _labelEstado(dynamic estado) {
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
}
