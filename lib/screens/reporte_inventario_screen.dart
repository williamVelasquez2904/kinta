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
  String _filtroStock = 'todos';

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
    try {
      final listas = await _productoService.cargarListas();
      if (listas['success'] == true && mounted) {
        setState(() => _departamentos = listas['departamentos'] ?? []);
      }
    } catch (e) {
      debugPrint('Error cargando departamentos: $e');
    }
  }

  Future<void> _buscar() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
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
        setState(() => _errorMsg = result['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error de conexión: $e');
    }

    setState(() => _isLoading = false);
  }

  String get _nombreFiltroStock {
    switch (_filtroStock) {
      case 'bajo':
        return 'Stock bajo / cero';
      case 'disponible':
        return 'Stock disponible (> 0)';
      default:
        return 'Todos los productos';
    }
  }

  String get _nombreDepartamento {
    if (_departamentoIde == null) return 'Todos los departamentos';
    try {
      final dep = _departamentos.firstWhere(
        (d) => int.tryParse(d['depart_ide'].toString()) == _departamentoIde,
      );
      return dep['depart_descrip']?.toString() ?? '-';
    } catch (_) {
      return 'Todos los departamentos';
    }
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
        filtroAplicado: '$_nombreDepartamento  |  $_nombreFiltroStock',
        valorTotal: _valorTotal,
        totalProductos: _totalProductos,
        productos: _productos,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: 'Inventario_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
    if (!widget.user.esAdministrador) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reporte de Inventario')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: AppColors.error, size: 52),
              SizedBox(height: 12),
              Text(
                'No tienes permisos para este reporte',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _buscar,
          ),
        ],
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
                  'FILTROS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // Dropdown departamento
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
                      child: Text(
                        'Todos los departamentos',
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 13),
                      ),
                    ),
                    ..._departamentos.map<DropdownMenuItem<int>>(
                        (d) => DropdownMenuItem<int>(
                              value: int.tryParse(d['depart_ide'].toString()),
                              child: Text(
                                d['depart_descrip']?.toString() ?? '',
                                style: const TextStyle(
                                    color: AppColors.textPrimary, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                  ],
                  onChanged: (v) => setState(() => _departamentoIde = v),
                ),

                const SizedBox(height: 14),

                // Chips filtro stock
                const Text(
                  'Condición de stock',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chipFiltro('todos', 'Todos', Icons.all_inclusive),
                    _chipFiltro(
                        'disponible', 'Stock > 0', Icons.check_circle_outline),
                    _chipFiltro('bajo', 'Stock bajo/cero',
                        Icons.warning_amber_outlined),
                  ],
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _buscar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: const Text('Aplicar Filtros'),
                  ),
                ),
              ],
            ),
          ),

          // ── Lista ────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMsg.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 48),
                            const SizedBox(height: 12),
                            Text(_errorMsg,
                                style: const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _buscar,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Tarjetas resumen
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

                          const SizedBox(height: 12),

                          // Filtro activo
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.filter_list,
                                    color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$_nombreDepartamento  ·  $_nombreFiltroStock',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (_productos.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined,
                                        color: AppColors.textHint, size: 48),
                                    SizedBox(height: 10),
                                    Text(
                                      'Sin productos para estos filtros',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
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
                              final precio1 = double.tryParse(
                                      p['produc_precio1'].toString()) ??
                                  0;
                              final costo = double.tryParse(
                                      p['produc_costo'].toString()) ??
                                  0;
                              final sinStock = existencia <= 0;
                              final bajoStock =
                                  existencia > 0 && existencia <= stockMin;

                              Color cardColor = AppColors.surface;
                              Color stockColor = AppColors.success;

                              if (sinStock) {
                                cardColor = AppColors.errorBg;
                                stockColor = AppColors.error;
                              } else if (bajoStock) {
                                cardColor = AppColors.warningBg;
                                stockColor = AppColors.warning;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    // Info producto
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
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Cód: ${p['produc_codigo'] ?? '-'}',
                                            style: const TextStyle(
                                                color: AppColors.textHint,
                                                fontSize: 10),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.category_outlined,
                                                  color: AppColors.textHint,
                                                  size: 11),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  p['depart_descrip']
                                                          ?.toString() ??
                                                      '-',
                                                  style: const TextStyle(
                                                      color: AppColors.textHint,
                                                      fontSize: 10),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    // Precios y stock
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        // Existencia
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: stockColor.withAlpha(30),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            FormatoNumero.decimal(existencia),
                                            style: TextStyle(
                                              color: stockColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        // Precio 1
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('P1: ',
                                                style: TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 10,
                                                )),
                                            Text(
                                              FormatoNumero.monedaConSimbolo(
                                                  precio1),
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Costo
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Costo: ',
                                                style: TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 10,
                                                )),
                                            Text(
                                              FormatoNumero.monedaConSimbolo(
                                                  costo),
                                              style: const TextStyle(
                                                color: AppColors.warning,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Estado stock
                                        if (sinStock)
                                          const Text(
                                            'Sin stock',
                                            style: TextStyle(
                                              color: AppColors.error,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        else if (bajoStock)
                                          const Text(
                                            'Stock bajo',
                                            style: TextStyle(
                                              color: AppColors.warning,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
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

      // ── FAB — Generar PDF ─────────────────────────────────
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

  Widget _chipFiltro(String valor, String label, IconData icono) {
    final sel = _filtroStock == valor;
    return GestureDetector(
      onTap: () => setState(() => _filtroStock = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryBg : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono,
                size: 14, color: sel ? AppColors.primary : AppColors.textHint),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: sel ? AppColors.primary : AppColors.textSecondary,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
