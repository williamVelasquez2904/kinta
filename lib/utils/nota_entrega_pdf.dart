import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class NotaEntregaPdf {
  // ── Formato carta ───────────────────────────────────────
  static Future<pw.Document> generarCarta({
    required Map empresa,
    required Map factura,
    required List items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Encabezado empresa ──────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        empresa['empresa_nombre'] ?? '',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('RIF: ${empresa['empresa_rif'] ?? ''}',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(empresa['empresa_direccion'] ?? '',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Tel: ${empresa['empresa_telefono'] ?? ''}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'NOTA DE ENTREGA',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          factura['factura_num'] ?? '',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),

              // ── Datos cliente y fecha ───────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CLIENTE',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          )),
                      pw.Text(
                        factura['clien_nombre1'] ?? '',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FECHA',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          )),
                      pw.Text(
                        _formatFecha(factura['factura_fecha']),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 6),

              pw.Row(
                children: [
                  pw.Text('Condición: ',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    (int.tryParse(factura['factura_condicion'].toString()) ??
                                0) ==
                            1
                        ? 'Crédito (${factura['factura_dias_credito']} días)'
                        : 'Contado',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── Tabla de productos ──────────────────────
              pw.Table(
                border:
                    pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Encabezado tabla
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _celdaHeader('Descripción'),
                      _celdaHeader('Cant.'),
                      _celdaHeader('Precio'),
                      _celdaHeader('Subtotal'),
                    ],
                  ),
                  // Filas items
                  ...items.map((item) => pw.TableRow(
                        children: [
                          _celda(item['detfac_descripcion'] ?? ''),
                          _celda(
                            (double.tryParse(
                                        item['detfac_cantidad'].toString()) ??
                                    0)
                                .toStringAsFixed(0),
                            align: pw.Alignment.center,
                          ),
                          _celda(
                            _moneda(item['detfac_precio']),
                            align: pw.Alignment.centerRight,
                          ),
                          _celda(
                            _moneda(item['detfac_subtotal']),
                            align: pw.Alignment.centerRight,
                          ),
                        ],
                      )),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── Totales ──────────────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _filaTotal('Subtotal', factura['factura_subtotal']),
                      _filaTotal('Descuento', factura['factura_descuento'],
                          esPorcentaje: true),
                      _filaTotal('Flete', factura['factura_flete']),
                      _filaTotal('Impuesto', factura['factura_impuesto']),
                      pw.Divider(thickness: 1),
                      _filaTotal('TOTAL', factura['factura_total'],
                          negrita: true, grande: true),
                      if ((double.tryParse(factura['factura_abono_inicial']
                                  .toString()) ??
                              0) >
                          0) ...[
                        _filaTotal(
                            'Abono inicial', factura['factura_abono_inicial']),
                        _filaTotal('Saldo pendiente', factura['factura_saldo'],
                            negrita: true),
                      ],
                    ],
                  ),
                ),
              ),

              pw.Spacer(),

              // ── Firmas ───────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                          width: 180,
                          decoration: const pw.BoxDecoration(
                              border:
                                  pw.Border(top: pw.BorderSide(width: 0.5)))),
                      pw.SizedBox(height: 4),
                      pw.Text('Entregado por',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                          width: 180,
                          decoration: const pw.BoxDecoration(
                              border:
                                  pw.Border(top: pw.BorderSide(width: 0.5)))),
                      pw.SizedBox(height: 4),
                      pw.Text('Recibido por',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── Pie de página ────────────────────────────
              if ((empresa['empresa_pie'] ?? '').toString().isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    empresa['empresa_pie'],
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // ── Formato comanda 55mm ────────────────────────────────
  static Future<pw.Document> generarComanda({
    required Map empresa,
    required Map factura,
    required List items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          55 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Encabezado
              pw.Text(
                empresa['empresa_nombre'] ?? '',
                style:
                    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'RIF: ${empresa['empresa_rif'] ?? ''}',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                  width: double.infinity, child: pw.Divider(thickness: 0.5)),

              pw.Text(
                'NOTA DE ENTREGA',
                style:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                factura['factura_num'] ?? '',
                style:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),

              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Cliente: ${factura['clien_nombre1'] ?? ''}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Fecha: ${_formatFecha(factura['factura_fecha'])}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),

              pw.SizedBox(height: 4),
              pw.Container(
                  width: double.infinity, child: pw.Divider(thickness: 0.5)),

              // Items
              ...items.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item['detfac_descripcion'] ?? '',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${(double.tryParse(item['detfac_cantidad'].toString()) ?? 0).toStringAsFixed(0)} x ${_moneda(item['detfac_precio'])}',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                            pw.Text(
                              _moneda(item['detfac_subtotal']),
                              style: pw.TextStyle(
                                  fontSize: 7, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),

              pw.Container(
                  width: double.infinity, child: pw.Divider(thickness: 0.5)),

              // Totales compactos
              _filaComanda('Subtotal', factura['factura_subtotal']),
              _filaComanda('Descuento', factura['factura_descuento'],
                  esPorcentaje: true),
              _filaComanda('Flete', factura['factura_flete']),
              pw.Container(
                  width: double.infinity, child: pw.Divider(thickness: 0.5)),
              _filaComanda('TOTAL', factura['factura_total'], negrita: true),

              pw.SizedBox(height: 6),
              pw.Text(
                '¡Gracias por su compra!',
                style:
                    pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
              ),
              pw.SizedBox(height: 4),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // ── Helpers ──────────────────────────────────────────────

  static pw.Widget _celdaHeader(String texto) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          texto,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      );

  static pw.Widget _celda(
    String texto, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Align(
          alignment: align,
          child: pw.Text(texto, style: const pw.TextStyle(fontSize: 9)),
        ),
      );

  static pw.Widget _filaTotal(
    String label,
    dynamic valor, {
    bool esPorcentaje = false,
    bool negrita = false,
    bool grande = false,
  }) {
    final num = double.tryParse(valor.toString()) ?? 0;
    final texto = esPorcentaje ? '${num.toStringAsFixed(2)}%' : _moneda(valor);

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: grande ? 11 : 9,
              fontWeight:
                  grande || negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            texto,
            style: pw.TextStyle(
              fontSize: grande ? 12 : 9,
              fontWeight:
                  grande || negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _filaComanda(
    String label,
    dynamic valor, {
    bool esPorcentaje = false,
    bool negrita = false,
  }) {
    final num = double.tryParse(valor.toString()) ?? 0;
    final texto = esPorcentaje ? '${num.toStringAsFixed(2)}%' : _moneda(valor);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          texto,
          style: pw.TextStyle(
            fontSize: negrita ? 9 : 7,
            fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static String _moneda(dynamic valor) {
    final num = double.tryParse(valor.toString()) ?? 0;
    return '\$${num.toStringAsFixed(2)}';
  }

  static String _formatFecha(dynamic fecha) {
    if (fecha == null) return '-';
    final str = fecha.toString();
    if (str.length < 10) return str;
    try {
      final d = DateTime.parse(str);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return str.substring(0, 10);
    }
  }
}
