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
                    pw.Text('RIF: ${empresa['empresa_rif'] ?? ''}',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'REPORTE DE NOTAS DE VENTA',
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
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 4),
            pw.Text(
              esAdmin
                  ? 'Reporte general — Generado por: $nombreUsuario'
                  : 'Vendedor: $nombreUsuario',
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 12),
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
          // ── Resumen general ──────────────────────────────
          pw.Row(
            children: [
              _tarjetaResumen('Total Vendido', _moneda(totalGeneral)),
              pw.SizedBox(width: 10),
              _tarjetaResumen('Facturas', '$totalFacturas'),
            ],
          ),

          pw.SizedBox(height: 16),

          pw.Row(
            children: [
              _tarjetaResumen('Costo Total', _moneda(totalCosto)),
              pw.SizedBox(width: 10),
              _tarjetaResumen('Ganancia', _moneda(totalGanancia)),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── Resumen por vendedor (solo admin) ────────────
          if (esAdmin && resumenVendedores.isNotEmpty) ...[
            pw.Text(
              'VENTAS POR VENDEDOR',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _celdaHeader('Vendedor'),
                    _celdaHeader('Facturas'),
                    _celdaHeader('Total'),
                  ],
                ),
                ...resumenVendedores.map((v) => pw.TableRow(
                      children: [
                        _celda(v['vendedor'] ?? ''),
                        _celda('${v['cantidad']}', align: pw.Alignment.center),
                        _celda(_moneda(v['total']),
                            align: pw.Alignment.centerRight),
                      ],
                    )),
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
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.3),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(2.5),
              if (esAdmin) 3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _celdaHeader('Factura'),
                  _celdaHeader('Fecha'),
                  _celdaHeader('Cliente'),
                  if (esAdmin) _celdaHeader('Vendedor'),
                  _celdaHeader('Estado'),
                  _celdaHeader('Total'),
                ],
              ),
              ...facturas.map((f) => pw.TableRow(
                    children: [
                      _celda(f['factura_num'] ?? ''),
                      _celda(_formatFecha(f['factura_fecha'])),
                      _celda(f['clien_nombre1'] ?? ''),
                      if (esAdmin)
                        _celda(
                            '${f['usua_nombre'] ?? ''} ${f['usua_apelli'] ?? ''}'),
                      _celda(_labelEstado(f['factura_estado']),
                          align: pw.Alignment.center),
                      _celda(_moneda(f['factura_total']),
                          align: pw.Alignment.centerRight),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _tarjetaResumen(String label, String valor) {
    return pw.Expanded(
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
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(valor,
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _celdaHeader(String texto) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(texto,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _celda(
    String texto, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Align(
          alignment: align,
          child: pw.Text(texto, style: const pw.TextStyle(fontSize: 8)),
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
    return str.substring(8, 10) +
        '/' +
        str.substring(5, 7) +
        '/' +
        str.substring(0, 4);
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
