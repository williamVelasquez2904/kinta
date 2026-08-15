// -----------------------------------------------------------------------
// carga_masiva_productos_screen.dart
// -----------------------------------------------------------------------
// Carga masiva de productos desde un archivo Excel (.xlsx), pensada para
// la versión web de Kinta.
//
// Columnas esperadas en la primera fila del Excel (encabezados, no
// sensibles a mayúsculas/acentos):
//   - codigo / código / cod
//   - descripcion / descripción / desc
//   - existencia / stock            (opcional, default 0)
//   - precio1 / precio               (opcional, default 0)
//
// Flujo:
//   1) Seleccionar archivo .xlsx
//   2) Parsear en el cliente (paquete `excel`)
//   3) Verificar contra el backend cuáles códigos ya existen
//   4) Elegir qué hacer con los que ya existen (actualizar u omitir)
//   5) Vista previa con conteo de nuevos / existentes / inválidos
//   6) Confirmar e importar
//
// Dependencias nuevas a agregar en pubspec.yaml:
//   excel: ^4.0.6
//   file_picker: ^8.1.2
// -----------------------------------------------------------------------

import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/carga_masiva_productos_service.dart';
import '../theme/app_theme.dart';

class _FilaProducto {
  final int fila;
  String codigo;
  String descripcion;
  double existencia;
  double costo;
  double precio1;
  double precioDolar;
  String departamento;

  bool esValida;
  String? motivoError;

  bool existeEnBd = false;
  double? existenciaActual;
  double? costoActual;
  double? precio1Actual;
  double? precioDolarActual;
  String? departamentoActual;

  _FilaProducto({
    required this.fila,
    required this.codigo,
    required this.descripcion,
    required this.existencia,
    required this.costo,
    required this.precio1,
    required this.precioDolar,
    required this.departamento,
    required this.esValida,
    this.motivoError,
  });
}

class CargaMasivaProductosScreen extends StatefulWidget {
  final UserModel user;
  const CargaMasivaProductosScreen({super.key, required this.user});

  @override
  State<CargaMasivaProductosScreen> createState() =>
      _CargaMasivaProductosScreenState();
}

class _CargaMasivaProductosScreenState
    extends State<CargaMasivaProductosScreen> {
  final _service = CargaMasivaProductosService();

  String? _nombreArchivo;
  List<_FilaProducto> _filas = [];
  bool _cargando = false;
  bool _importando = false;
  String? _errorGeneral;

  // 'actualizar' u 'omitir' — decidido UNA vez, antes de importar.
  String _accionExistente = 'actualizar';

  bool get _hayDatos => _filas.isNotEmpty;

  int get _totalValidas => _filas.where((f) => f.esValida).length;
  int get _totalNuevos =>
      _filas.where((f) => f.esValida && !f.existeEnBd).length;
  int get _totalExistentes =>
      _filas.where((f) => f.esValida && f.existeEnBd).length;
  int get _totalInvalidas => _filas.where((f) => !f.esValida).length;

  // ── Selección y parseo del archivo ────────────────────────────────
  Future<void> _seleccionarArchivo() async {
    setState(() {
      _errorGeneral = null;
    });

    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true, // necesario en web para obtener los bytes
    );

    if (resultado == null || resultado.files.isEmpty) return;

    final archivo = resultado.files.first;
    final bytes = archivo.bytes;

    if (bytes == null) {
      setState(
          () => _errorGeneral = 'No se pudo leer el archivo seleccionado.');
      return;
    }

    setState(() {
      _cargando = true;
      _nombreArchivo = archivo.name;
      _filas = [];
    });

    try {
      final filas = _parsearExcel(bytes);
      setState(() => _filas = filas);
      await _verificarExistentes();
    } catch (e) {
      setState(() => _errorGeneral = 'Error leyendo el Excel: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  List<_FilaProducto> _parsearExcel(Uint8List bytes) {
    final excel = xls.Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw 'El archivo no tiene hojas.';
    }

    final hoja = excel.tables[excel.tables.keys.first]!;
    if (hoja.maxRows < 2) {
      throw 'El archivo no tiene filas de datos (solo encabezado o vacío).';
    }

    // Detectar índice de columnas por nombre de encabezado (fila 0)
    final encabezados = hoja.rows.first
        .map((c) => _normalizar(c?.value?.toString() ?? ''))
        .toList();

    int indiceColumna(List<String> alias) {
      for (final a in alias) {
        final idx = encabezados.indexOf(a);
        if (idx != -1) return idx;
      }
      return -1;
    }

    final idxCodigo =
        indiceColumna(['codigo', 'código', 'cod', 'produc_codigo']);
    final idxDescripcion =
        indiceColumna(['descripcion', 'descripción', 'desc', 'produc_descrip']);
    final idxExistencia =
        indiceColumna(['existencia', 'stock', 'existen', 'produc_existen']);
    final idxCosto = indiceColumna(['costo', 'cost', 'produc_costo']);
    final idxPrecio1 =
        indiceColumna(['precio1', 'precio', 'precio_1', 'produc_precio1']);
    final idxPrecioDolar = indiceColumna([
      'preciodolar',
      'precio_dolar',
      'precio usd',
      'precio_usd',
      'dolar',
      'produc_preciodolar'
    ]);
    final idxDepartamento = indiceColumna(
        ['departamento', 'depart', 'dept', 'produc_departamento']);

    if (idxCodigo == -1 || idxDescripcion == -1) {
      throw 'No se encontraron las columnas "codigo" y "descripcion" en la primera fila del Excel.';
    }

    final filas = <_FilaProducto>[];

    for (int i = 1; i < hoja.maxRows; i++) {
      final fila = hoja.rows[i];
      String celda(int idx) {
        if (idx == -1 || idx >= fila.length) return '';
        return fila[idx]?.value?.toString().trim() ?? '';
      }

      final codigo = celda(idxCodigo);
      final descripcion = celda(idxDescripcion);
      final existenciaTxt = celda(idxExistencia);
      final costoTxt = celda(idxCosto);
      final precio1Txt = celda(idxPrecio1);
      final precioDolarTxt = celda(idxPrecioDolar);
      final departamento = celda(idxDepartamento);

      // Saltar filas completamente vacías (frecuente al final del Excel)
      if (codigo.isEmpty && descripcion.isEmpty) continue;

      final existencia = double.tryParse(existenciaTxt.replaceAll(',', '.'));
      final costo = double.tryParse(costoTxt.replaceAll(',', '.'));
      final precio1 = double.tryParse(precio1Txt.replaceAll(',', '.'));
      final precioDolar = double.tryParse(precioDolarTxt.replaceAll(',', '.'));

      String? error;
      if (codigo.isEmpty) {
        error = 'Falta el código';
      } else if (descripcion.isEmpty) {
        error = 'Falta la descripción';
      }

      filas.add(_FilaProducto(
        fila: i + 1,
        codigo: codigo,
        descripcion: descripcion,
        existencia: existencia ?? 0,
        costo: costo ?? 0,
        precio1: precio1 ?? 0,
        precioDolar: precioDolar ?? 0,
        departamento: departamento,
        esValida: error == null,
        motivoError: error,
      ));
    }

    // Marcar duplicados dentro del mismo archivo
    final vistos = <String, int>{};
    for (final f in filas) {
      if (!f.esValida) continue;
      final clave = f.codigo.toLowerCase();
      if (vistos.containsKey(clave)) {
        f.esValida = false;
        f.motivoError =
            'Código duplicado en el archivo (fila ${vistos[clave]})';
      } else {
        vistos[clave] = f.fila;
      }
    }

    return filas;
  }

  String _normalizar(String s) {
    var r = s.trim().toLowerCase();
    const conAcento = 'áéíóúñ';
    const sinAcento = 'aeioun';
    for (int i = 0; i < conAcento.length; i++) {
      r = r.replaceAll(conAcento[i], sinAcento[i]);
    }
    return r;
  }

  // ── Verificar contra backend cuáles códigos ya existen ────────────
  Future<void> _verificarExistentes() async {
    final codigos =
        _filas.where((f) => f.esValida).map((f) => f.codigo).toList();
    if (codigos.isEmpty) return;

    final resp = await _service.verificarCodigos(codigos);
    if (resp['success'] != true) {
      setState(() => _errorGeneral = resp['message']?.toString() ??
          'No se pudo verificar códigos existentes.');
      return;
    }

    final existentes = Map<String, dynamic>.from(resp['existentes'] ?? {});
    setState(() {
      for (final f in _filas) {
        if (existentes.containsKey(f.codigo)) {
          final d = Map<String, dynamic>.from(existentes[f.codigo]);
          f.existeEnBd = true;
          f.existenciaActual = (d['produc_existen'] as num?)?.toDouble();
          f.costoActual = (d['produc_costo'] as num?)?.toDouble();
          f.precio1Actual = (d['produc_precio1'] as num?)?.toDouble();
          f.precioDolarActual = (d['produc_preciodolar'] as num?)?.toDouble();
          f.departamentoActual = d['produc_departamento']?.toString() ??
              d['depart_descrip']?.toString();
        }
      }
    });
  }

  // ── Importar ───────────────────────────────────────────────────────
  Future<void> _confirmarImportacion() async {
    final aImportar = _filas.where((f) {
      if (!f.esValida) return false;
      if (f.existeEnBd && _accionExistente == 'omitir') return false;
      return true;
    }).toList();

    if (aImportar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay filas válidas para importar.')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar importación'),
        content: Text(
          'Se procesarán ${aImportar.length} productos.\n\n'
          'Nuevos: $_totalNuevos\n'
          'Existentes (${_accionExistente == 'actualizar' ? 'se actualizarán' : 'se omitirán'}): $_totalExistentes\n'
          'Filas inválidas (se ignoran): $_totalInvalidas',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Importar')),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _importando = true);

    final productos = aImportar
        .map((f) => {
              'produc_codigo': f.codigo,
              'produc_descrip': f.descripcion,
              'produc_existen': f.existencia,
              'produc_costo': f.costo,
              'produc_precio1': f.precio1,
              'produc_preciodolar': f.precioDolar,
              'produc_departamento': f.departamento,
            })
        .toList();

    final resp = await _service.importar(
      productos: productos,
      accionExistente: _accionExistente,
    );

    setState(() => _importando = false);

    if (!mounted) return;

    if (resp['success'] == true) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Importación completada'),
          content: Text(
            'Creados: ${resp['creados']}\n'
            'Actualizados: ${resp['actualizados']}\n'
            'Omitidos: ${resp['omitidos']}\n'
            'Errores: ${(resp['errores'] as List?)?.length ?? 0}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      setState(() {
        _filas = [];
        _nombreArchivo = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp['message']?.toString() ?? 'Error al importar.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── UI ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Carga Masiva de Productos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelSeleccionArchivo(),
            if (_errorGeneral != null) ...[
              const SizedBox(height: 12),
              _mensajeError(_errorGeneral!),
            ],
            if (_hayDatos) ...[
              const SizedBox(height: 16),
              _panelAccionExistentes(),
              const SizedBox(height: 12),
              _panelResumen(),
              const SizedBox(height: 12),
              Expanded(child: _tablaPreview()),
              const SizedBox(height: 12),
              _botonImportar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _panelSeleccionArchivo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Archivo Excel (.xlsx)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  _nombreArchivo ?? 'Ningún archivo seleccionado',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Columnas esperadas: codigo, descripcion, existencia, costo, precio1, preciodolar y departamento',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _cargando ? null : _seleccionarArchivo,
            icon: _cargando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file, size: 18),
            label: Text(_cargando ? 'Cargando...' : 'Seleccionar'),
          ),
        ],
      ),
    );
  }

  Widget _mensajeError(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(msg, style: const TextStyle(color: AppColors.error)),
    );
  }

  Widget _panelAccionExistentes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('Si el código ya existe: ',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Actualizar'),
            selected: _accionExistente == 'actualizar',
            onSelected: (_) => setState(() => _accionExistente = 'actualizar'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Omitir'),
            selected: _accionExistente == 'omitir',
            onSelected: (_) => setState(() => _accionExistente = 'omitir'),
          ),
        ],
      ),
    );
  }

  Widget _panelResumen() {
    Widget chip(String label, int valor, Color color, Color colorBg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$label: $valor',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w500, fontSize: 12)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Nuevos', _totalNuevos, AppColors.success, AppColors.successBg),
        chip('Existentes', _totalExistentes, AppColors.info, AppColors.infoBg),
        chip('Inválidas', _totalInvalidas, AppColors.error, AppColors.errorBg),
        chip('Total válidas', _totalValidas, AppColors.primary,
            AppColors.primaryBg),
      ],
    );
  }

  Widget _tablaPreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Fila')),
            DataColumn(label: Text('Código')),
            DataColumn(label: Text('Descripción')),
            DataColumn(label: Text('Existencia')),
            DataColumn(label: Text('Costo')),
            DataColumn(label: Text('Precio1')),
            DataColumn(label: Text('Precio USD')),
            DataColumn(label: Text('Departamento')),
            DataColumn(label: Text('Estado')),
          ],
          rows: _filas.map((f) {
            Color colorEstado;
            String textoEstado;
            if (!f.esValida) {
              colorEstado = AppColors.error;
              textoEstado = f.motivoError ?? 'Inválida';
            } else if (f.existeEnBd) {
              colorEstado = AppColors.info;
              textoEstado = _accionExistente == 'actualizar'
                  ? 'Existente · se actualiza'
                  : 'Existente · se omite';
            } else {
              colorEstado = AppColors.success;
              textoEstado = 'Nuevo';
            }

            return DataRow(cells: [
              DataCell(Text('${f.fila}')),
              DataCell(Text(f.codigo)),
              DataCell(Text(f.descripcion)),
              DataCell(Text(f.existencia.toStringAsFixed(2))),
              DataCell(Text(f.costo.toStringAsFixed(2))),
              DataCell(Text(f.precio1.toStringAsFixed(2))),
              DataCell(Text(f.precioDolar.toStringAsFixed(2))),
              DataCell(Text(f.departamento.isEmpty ? '-' : f.departamento)),
              DataCell(Text(textoEstado,
                  style: TextStyle(color: colorEstado, fontSize: 12))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _botonImportar() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed:
            (_importando || _totalValidas == 0) ? null : _confirmarImportacion,
        icon: _importando
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.cloud_upload_outlined),
        label: Text(_importando ? 'Importando...' : 'Importar productos'),
      ),
    );
  }
}
