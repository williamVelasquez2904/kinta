import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'formato_numero.dart';

class InventarioPdf {
  static Future<pw.Document> generar({
    required Map empresa,
    required String nombreUsuario,
    required String filtroAplicado,
    required double valorTotal,
    required int totalProductos,
    required List productos,
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
                    if ((empresa['empresa_telefono'] ?? '').isNotEmpty)
                      pw.Text(
                        'Tel: ${empresa['empresa_telefono']}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'REPORTE DE INVENTARIO',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _formatFechaHoy(),
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
              'Filtro: $filtroAplicado',
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
            ),
            pw.Text(
              'Generado por: $nombreUsuario',
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
          // ── Resumen general ──────────────────────────────
          pw.Row(
            children: [
              _tarjeta(
                'Total Productos',
                '$totalProductos',
                PdfColors.teal700,
              ),
              pw.SizedBox(width: 10),
              _tarjeta(
                'Valor Inventario (costo)',
                _moneda(valorTotal),
                PdfColors.indigo700,
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── Tabla productos ──────────────────────────────
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(3.0),
              2: const pw.FlexColumnWidth(1.4),
              3: const pw.FlexColumnWidth(1.4),
              4: const pw.FlexColumnWidth(0.9),
              5: const pw.FlexColumnWidth(1.2),
              6: const pw.FlexColumnWidth(1.2),
            },
            children: [
              // Encabezado
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _celdaHeader('Código'),
                  _celdaHeader('Descripción'),
                  _celdaHeader('Departamento'),
                  _celdaHeader('Marca'),
                  _celdaHeader('Exist.'),
                  _celdaHeader('Costo'),
                  _celdaHeader('Precio 1'),
                ],
              ),

              // Filas
              ...productos.map((p) {
                final existencia =
                    double.tryParse(p['produc_existen'].toString()) ?? 0;
                final stockMin =
                    double.tryParse(p['produc_stock'].toString()) ?? 0;
                final costo =
                    double.tryParse(p['produc_costo'].toString()) ?? 0;
                final precio1 =
                    double.tryParse(p['produc_precio1'].toString()) ?? 0;
                final bajoStock = existencia <= stockMin;
                final sinStock = existencia <= 0;

                PdfColor bgColor = PdfColors.white;
                if (sinStock) {
                  bgColor = PdfColors.red50;
                } else if (bajoStock) {
                  bgColor = PdfColors.orange50;
                }

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bgColor),
                  children: [
                    _celda(p['produc_codigo']?.toString() ?? '-'),
                    _celda(p['produc_descrip']?.toString() ?? '-'),
                    _celda(p['depart_descrip']?.toString() ?? '-'),
                    _celda(p['marca_descrip']?.toString() ?? '-'),
                    _celda(
                      FormatoNumero.decimal(existencia),
                      align: pw.Alignment.center,
                      color: sinStock
                          ? PdfColors.red700
                          : bajoStock
                              ? PdfColors.orange700
                              : PdfColors.black,
                      negrita: bajoStock || sinStock,
                    ),
                    // Costo
                    _celda(
                      _moneda(costo),
                      align: pw.Alignment.centerRight,
                      color: PdfColors.orange800,
                    ),
                    // Precio 1
                    _celda(
                      _moneda(precio1),
                      align: pw.Alignment.centerRight,
                      color: PdfColors.teal700,
                      negrita: true,
                    ),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 12),

          // ── Leyenda ──────────────────────────────────────
          pw.Row(
            children: [
              _leyenda(PdfColors.red50, PdfColors.red700,
                  'Sin stock (existencia = 0)'),
              pw.SizedBox(width: 12),
              _leyenda(PdfColors.orange50, PdfColors.orange700,
                  'Stock bajo (por debajo del mínimo)'),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── Resumen por departamento ──────────────────────
          if (_tieneDepartamentos(productos)) ...[
            pw.Text(
              'RESUMEN POR DEPARTAMENTO',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _celdaHeader('Departamento'),
                    _celdaHeader('Productos'),
                    _celdaHeader('Valor Costo'),
                    _celdaHeader('Valor P1'),
                  ],
                ),
                ..._resumenPorDepartamento(productos).map((dep) => pw.TableRow(
                      children: [
                        _celda(dep['nombre']),
                        _celda('${dep['cantidad']}',
                            align: pw.Alignment.center),
                        _celda(_moneda(dep['valor_costo']),
                            align: pw.Alignment.centerRight,
                            color: PdfColors.orange800),
                        _celda(_moneda(dep['valor_precio1']),
                            align: pw.Alignment.centerRight,
                            color: PdfColors.teal700,
                            negrita: true),
                      ],
                    )),
              ],
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  // ── Helpers privados ─────────────────────────────────────

  static pw.Widget _tarjeta(String label, String valor, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  valor,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  static pw.Widget _celdaHeader(String texto) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          texto,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
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

  static pw.Widget _leyenda(PdfColor bg, PdfColor textColor, String label) =>
      pw.Row(
        children: [
          pw.Container(
            width: 12,
            height: 12,
            decoration: pw.BoxDecoration(
              color: bg,
              border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7, color: textColor),
          ),
        ],
      );

  static bool _tieneDepartamentos(List productos) {
    return productos.any((p) =>
        p['depart_descrip'] != null &&
        p['depart_descrip'].toString().isNotEmpty);
  }

  static List<Map<String, dynamic>> _resumenPorDepartamento(List productos) {
    final Map<String, Map<String, dynamic>> resumen = {};

    for (var p in productos) {
      final dep = p['depart_descrip']?.toString() ?? 'Sin departamento';
      final existen = double.tryParse(p['produc_existen'].toString()) ?? 0;
      final costo = double.tryParse(p['produc_costo'].toString()) ?? 0;
      final precio1 = double.tryParse(p['produc_precio1'].toString()) ?? 0;

      if (!resumen.containsKey(dep)) {
        resumen[dep] = {
          'nombre': dep,
          'cantidad': 0,
          'valor_costo': 0.0,
          'valor_precio1': 0.0,
        };
      }
      resumen[dep]!['cantidad'] = (resumen[dep]!['cantidad'] as int) + 1;
      resumen[dep]!['valor_costo'] =
          (resumen[dep]!['valor_costo'] as double) + (existen * costo);
      resumen[dep]!['valor_precio1'] =
          (resumen[dep]!['valor_precio1'] as double) + (existen * precio1);
    }

    final lista = resumen.values.toList();
    lista.sort((a, b) =>
        (b['valor_precio1'] as double).compareTo(a['valor_precio1'] as double));
    return lista;
  }

  static String _moneda(dynamic valor) {
    final num = double.tryParse(valor.toString()) ?? 0;
    return '\$${FormatoNumero.moneda(num)}';
  }

  static String _formatFechaHoy() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
