import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';

class GraficaProductosScreen extends StatefulWidget {
  final UserModel user;
  const GraficaProductosScreen({super.key, required this.user});

  @override
  State<GraficaProductosScreen> createState() => _GraficaProductosScreenState();
}

class _GraficaProductosScreenState extends State<GraficaProductosScreen> {
  final _ventaService = VentaService();

  DateTime _fechaDesde = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaHasta = DateTime.now();

  int? _departamentoIde;
  List _departamentos = [];
  List _productos = [];
  double _maxUnidades = 0;

  bool _isLoading = false;
  bool _buscado = false;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _cargar();
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

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _buscado = false;
    });

    try {
      final result = await _ventaService.graficaProductos(
        usuaIde: widget.user.usuaIde,
        fechaDesde: _fechaSql(_fechaDesde),
        fechaHasta: _fechaSql(_fechaHasta),
        departamento: _departamentoIde ?? 0,
      );

      if (result['success'] == true) {
        setState(() {
          _productos = result['productos'] ?? [];
          _maxUnidades =
              double.tryParse(result['max_unidades'].toString()) ?? 0;
          _departamentos = result['departamentos'] ?? [];
          _buscado = true;
          _touchedIndex = -1;
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

  Color _colorBarra(int index, bool tocado) {
    final colores = [
      AppColors.primary,
      AppColors.info,
      AppColors.purple,
      AppColors.success,
      AppColors.warning,
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
    ];
    final color = colores[index % colores.length];
    return tocado ? color : color.withAlpha(191);
  }

  String _nombreCorto(String nombre) {
    if (nombre.length <= 22) return nombre;
    return '${nombre.substring(0, 20)}…';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.user.esAdministrador) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gráfica de Productos')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: AppColors.error, size: 52),
              SizedBox(height: 12),
              Text(
                'Solo administradores pueden ver esta gráfica',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos más Vendidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Panel filtros ──────────────────────────────
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
                const SizedBox(height: 10),

                // Fechas
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

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _cargar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.bar_chart, size: 18),
                    label: const Text('Generar Gráfica'),
                  ),
                ),
              ],
            ),
          ),

          // ── Contenido ──────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : !_buscado || _productos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bar_chart,
                                color: AppColors.textHint, size: 64),
                            const SizedBox(height: 12),
                            Text(
                              _buscado
                                  ? 'Sin ventas en este período'
                                  : 'Selecciona el período y\npresiona Generar Gráfica',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // Título
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TOP 20 — Unidades vendidas',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_fechaDisplay(_fechaDesde)} al ${_fechaDisplay(_fechaHasta)}',
                                      style: const TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_productos.length} productos',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Gráfica ─────────────────────
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                // Detalle del tocado
                                if (_touchedIndex >= 0 &&
                                    _touchedIndex < _productos.length) ...[
                                  _tarjetaDetalle(
                                    _productos[_touchedIndex],
                                    _touchedIndex,
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Gráfica barras horizontales
                                SizedBox(
                                  height: (_productos.length * 36.0)
                                      .clamp(200.0, 800.0),
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.start,
                                      maxY: _maxUnidades * 1.15,
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchCallback: (event, response) {
                                          setState(() {
                                            if (response != null &&
                                                response.spot != null &&
                                                event
                                                    .isInterestedForInteractions) {
                                              _touchedIndex = response
                                                  .spot!.touchedBarGroupIndex;
                                            } else {
                                              _touchedIndex = -1;
                                            }
                                          });
                                        },
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipColor: (group) => AppColors
                                              .textPrimary
                                              .withAlpha(230),
                                          getTooltipItem: (group, groupIndex,
                                              rod, rodIndex) {
                                            final p = _productos[groupIndex];
                                            return BarTooltipItem(
                                              '${p['produc_descrip']}\n'
                                              '${rod.toY.toStringAsFixed(0)} uds',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 32,
                                            getTitlesWidget: (value, meta) {
                                              final v = value.toInt();
                                              if (_maxUnidades > 10 &&
                                                  v % 2 != 0) {
                                                return const SizedBox();
                                              }
                                              return Text(
                                                v.toString(),
                                                style: const TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 9,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 130,
                                            getTitlesWidget: (value, meta) {
                                              final idx = value.toInt();
                                              if (idx < 0 ||
                                                  idx >= _productos.length) {
                                                return const SizedBox();
                                              }
                                              final nombre = _nombreCorto(
                                                _productos[idx]
                                                            ['produc_descrip']
                                                        ?.toString() ??
                                                    '',
                                              );
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 6),
                                                child: Text(
                                                  nombre,
                                                  style: TextStyle(
                                                    color: _touchedIndex == idx
                                                        ? AppColors.primary
                                                        : AppColors
                                                            .textSecondary,
                                                    fontSize: 9,
                                                    fontWeight:
                                                        _touchedIndex == idx
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      gridData: FlGridData(
                                        show: true,
                                        drawHorizontalLine: false,
                                        drawVerticalLine: true,
                                        getDrawingVerticalLine: (value) =>
                                            const FlLine(
                                          color: AppColors.border,
                                          strokeWidth: 0.5,
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: const Border(
                                          bottom: BorderSide(
                                              color: AppColors.border,
                                              width: 1),
                                          left: BorderSide(
                                              color: AppColors.border,
                                              width: 1),
                                        ),
                                      ),
                                      barGroups:
                                          List.generate(_productos.length, (i) {
                                        final unidades = double.tryParse(
                                                _productos[i]['total_unidades']
                                                    .toString()) ??
                                            0;
                                        final tocado = _touchedIndex == i;
                                        return BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY: unidades,
                                              color: _colorBarra(i, tocado),
                                              width: tocado ? 20 : 16,
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                right: Radius.circular(4),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Ranking ──────────────────────
                          const Text(
                            'RANKING COMPLETO',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: List.generate(_productos.length, (i) {
                                final p = _productos[i];
                                final unidades = double.tryParse(
                                        p['total_unidades'].toString()) ??
                                    0;
                                final monto = double.tryParse(
                                        p['total_monto'].toString()) ??
                                    0;
                                final porcentaje = _maxUnidades > 0
                                    ? (unidades / _maxUnidades).clamp(0.0, 1.0)
                                    : 0.0;

                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () => setState(() =>
                                          _touchedIndex =
                                              _touchedIndex == i ? -1 : i),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // Posición
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: i < 3
                                                    ? _colorBarra(i, true)
                                                    : AppColors.surfaceAlt,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${i + 1}',
                                                  style: TextStyle(
                                                    color: i < 3
                                                        ? Colors.white
                                                        : AppColors
                                                            .textSecondary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            // Nombre + barra
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p['produc_descrip']
                                                            ?.toString() ??
                                                        '',
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${p['depart_descrip'] ?? '-'}  ·  ${p['total_facturas']} facturas',
                                                    style: const TextStyle(
                                                      color: AppColors.textHint,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    child:
                                                        LinearProgressIndicator(
                                                      value: porcentaje,
                                                      minHeight: 5,
                                                      backgroundColor:
                                                          AppColors.border,
                                                      color:
                                                          _colorBarra(i, true),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            // Unidades + monto
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${unidades.toStringAsFixed(0)} uds',
                                                  style: TextStyle(
                                                    color: _colorBarra(i, true),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  FormatoNumero
                                                      .monedaConSimbolo(monto),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (i < _productos.length - 1)
                                      const Divider(
                                          height: 1, color: AppColors.border),
                                  ],
                                );
                              }),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaDetalle(Map p, int index) {
    final unidades = double.tryParse(p['total_unidades'].toString()) ?? 0;
    final monto = double.tryParse(p['total_monto'].toString()) ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _colorBarra(index, true).withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _colorBarra(index, true).withAlpha(100)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _colorBarra(index, true),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['produc_descrip']?.toString() ?? '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  p['depart_descrip']?.toString() ?? '-',
                  style:
                      const TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${unidades.toStringAsFixed(0)} uds',
                style: TextStyle(
                  color: _colorBarra(index, true),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                FormatoNumero.monedaConSimbolo(monto),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                color: AppColors.textHint, size: 15),
            const SizedBox(width: 6),
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
                      fontSize: 12,
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
}
