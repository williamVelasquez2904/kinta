import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../services/producto_service.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import '../utils/inventario_pdf.dart';

class ReporteInventarioScreen extends StatefulWidget {
  final UserModel user;
  const ReporteInventarioScreen({super.key, required this.user});

  @override
  State<ReporteInventarioScreen> createState() =>
      _ReporteInventarioScreenState();
}

class _ReporteInventarioScreenState extends State<ReporteInventarioScreen> {
  final _productoService = ProductoService();
  final _ventaService = VentaService();

  bool _isLoading = true;
  bool _generandoPdf = false;
  String _errorMsg = '';

  List _departamentos = [];
  int? _departamentoIde;
  String _filtroStock = 'todos'; // todos, bajo, disponible

  List _productos = [];
  int _totalProductos = 0;
  double _valorTotal = 0;

  @override
  void initState() {
    super.initState();
    _cargarDepartamentos();
    _buscar();
  }

  Future<void> _cargarDepartamentos() async {
    final listas = await _productoService.cargarListas();
    if (listas['success'] == true) {
      setState(() => _departamentos = listas['departamentos'] ?? []);
    }
  }

  Future<void> _buscar() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    final result = await _productoService.listarParaReporte(
      usuaIde: widget.user.usuaIde,
      usuaTius: widget.user.tius,
      departamentoIde: _departamentoIde ?? 0,
      filtroStock: _filtroStock,
    );

    if (result['success'] == true) {
      setState(() {
        _productos = result['productos'] ?? [];
        _totalProductos = result['total'] ?? 0;
        _valorTotal =
            double.tryParse(result['valor_total_inventario'].toString()) ?? 0;
      });
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error');
    }

    setState(() => _isLoading = false);
  }

  String get _nombreFiltroStock {
    switch (_filtroStock) {
      case 'bajo':
        return 'Stock bajo / cero';
      case 'disponible':
        return 'Con stock disponible';
      default:
        return 'Todos los productos';
    }
  }

  String get _nombreDepartamento {
    if (_departamentoIde == null) return 'Todos los departamentos';
    final dep = _departamentos.firstWhere(
      (d) => int.tryParse(d['depart_ide'].toString()) == _departamentoIde,
      orElse: () => null,
    );
    return dep != null
        ? dep['depart_descrip'] ?? ''
        : 'Todos los departamentos';
  }

  Future<void> _generarPdf() async {
    setState(() => _generandoPdf = true);

    try {
      final resultEmpresa = await _ventaService.obtenerEmpresa();
      final empresa =
          resultEmpresa['success'] == true ? resultEmpresa['empresa'] : {};

      final pdf = await InventarioPdf.generar(
        empresa: empresa,
        nombreUsuario: widget.user.nombreCompleto,
        filtroAplicado: '$_nombreDepartamento — $_nombreFiltroStock',
        valorTotal: _valorTotal,
        totalProductos: _totalProductos,
        productos: _productos,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'Reporte_Inventario.pdf',
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

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'DEBUG ReporteInventarioScreen user.tius=${widget.user.tius} accesoInventario=${widget.user.accesoInventario} descripcion=${widget.user.tipoUsuarioDescripcion}');
    // Protección: acceso a reporte de inventario
    if (!widget.user.accesoInventario) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reporte de Inventario')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No tienes permisos para acceder a este reporte',
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              Text(
                'tius=${widget.user.tius} accesoInventario=${widget.user.accesoInventario}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Reporte de Inventario'),
            const SizedBox(height: 2),
            Text(
              widget.user.tipoUsuarioDescripcion,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _buscar,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros ───────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FILTROS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                // Departamento
                DropdownButtonFormField<int>(
                  value: _departamentoIde,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Departamento',
                    prefixIcon: Icon(Icons.category_outlined, size: 18),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Todos los departamentos',
                          style: TextStyle(fontSize: 13)),
                    ),
                    ..._departamentos.map<DropdownMenuItem<int>>(
                        (d) => DropdownMenuItem<int>(
                              value: int.tryParse(d['depart_ide'].toString()),
                              child: Text(
                                d['depart_descrip']?.toString() ?? '',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                  ],
                  onChanged: (v) => setState(() => _departamentoIde = v),
                ),

                const SizedBox(height: 12),

                // Filtro de stock
                const Text(
                  'Stock',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chipFiltro('todos', 'Todos'),
                    _chipFiltro('disponible', 'Stock > 0'),
                    _chipFiltro('bajo', 'Bajo / Cero'),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _buscar,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Aplicar Filtros'),
                  ),
                ),
              ],
            ),
          ),

          // ── Contenido ───────────────────────────────────
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
                          // Resumen
                          Row(
                            children: [
                              Expanded(
                                child: _tarjetaResumen(
                                  'Productos',
                                  '$_totalProductos',
                                  AppColors.info,
                                  Icons.inventory_2_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _tarjetaResumen(
                                  'Valor (costo)',
                                  FormatoNumero.monedaConSimbolo(_valorTotal),
                                  AppColors.primary,
                                  Icons.attach_money,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (_productos.isEmpty)
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
                                  'Sin productos para estos filtros',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            )
                          else
                            ...List.generate(_productos.length, (i) {
                              final p = _productos[i];
                              final existencia = double.tryParse(
                                      p['produc_existen'].toString()) ??
                                  0;
                              final stockMin = double.tryParse(
                                      p['produc_stock'].toString()) ??
                                  0;
                              final bajoStock = existencia <= stockMin;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bajoStock
                                      ? AppColors.errorBg
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['produc_descrip'] ?? '',
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '${p['produc_codigo'] ?? '-'} · ${p['depart_descrip'] ?? '-'}',
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
                                          existencia.toStringAsFixed(0),
                                          style: TextStyle(
                                            color: bajoStock
                                                ? AppColors.error
                                                : AppColors.success,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          FormatoNumero.monedaConSimbolo(
                                            double.tryParse(p['produc_precio1']
                                                    .toString()) ??
                                                0,
                                          ),
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),

                          const SizedBox(height: 90),
                        ],
                      ),
          ),
        ],
      ),

      // ── Botón PDF ────────────────────────────────────────
      floatingActionButton: _productos.isNotEmpty
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

  Widget _chipFiltro(String valor, String label) {
    final seleccionado = _filtroStock == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtroStock = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.primaryBg : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: seleccionado ? AppColors.primary : AppColors.textSecondary,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
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
              Text(label,
                  style:
                      const TextStyle(color: AppColors.textHint, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
