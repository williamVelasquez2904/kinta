// ════════════════════════════════════════════════════════════
// mis_ventas_screen.dart
// ════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import 'detalle_factura_screen.dart';
import 'nota_entrega_screen.dart';

class MisVentasScreen extends StatefulWidget {
  final UserModel user;
  const MisVentasScreen({super.key, required this.user});

  @override
  State<MisVentasScreen> createState() => _MisVentasScreenState();
}

class _MisVentasScreenState extends State<MisVentasScreen> {
  final _ventaService = VentaService();

  bool _isLoading = true;
  String _errorMsg = '';
  List _facturas = [];
  double _totalGeneral = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarFacturas();
  }

  Future<void> _cargarFacturas() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    final result = await _ventaService.listarFacturas(widget.user.usuaIde);

    if (result['success'] == true) {
      setState(() {
        _facturas = result['facturas'];
        _totalGeneral =
            double.tryParse(result['total_general'].toString()) ?? 0;
      });
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error desconocido');
    }

    setState(() => _isLoading = false);
  }

  List get _facturasFiltradas {
    if (_searchQuery.isEmpty) return _facturas;
    return _facturas.where((f) {
      final nombre = (f['clien_nombre1'] ?? '').toString().toLowerCase();
      final num = (f['factura_num'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nombre.contains(query) || num.contains(query);
    }).toList();
  }

  String _formatFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '-';
    try {
      final d = DateTime.parse(fecha);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return fecha.length >= 10 ? fecha.substring(0, 10) : fecha;
    }
  }

  String _labelEstado(dynamic estado) {
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

  Color _colorEstado(dynamic estado) {
    switch (int.tryParse(estado.toString())) {
      case 0:
        return AppColors.warning;
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  Color _bgEstado(dynamic estado) {
    switch (int.tryParse(estado.toString())) {
      case 0:
        return AppColors.warningBg;
      case 1:
        return AppColors.successBg;
      case 2:
        return AppColors.errorBg;
      default:
        return AppColors.surfaceAlt;
    }
  }

  String _labelCondicion(dynamic condicion) {
    return int.tryParse(condicion.toString()) == 1 ? 'Crédito' : 'Contado';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarFacturas,
      color: AppColors.primary,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _errorMsg,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarFacturas,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── Resumen ────────────────────────────
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Vendido',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_facturasFiltradas.length} facturas',
                                style: const TextStyle(
                                    color: AppColors.textHint, fontSize: 11),
                              ),
                            ],
                          ),
                          Text(
                            FormatoNumero.monedaConSimbolo(_totalGeneral),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Buscador ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Buscar factura o cliente...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Contador ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_facturasFiltradas.length} facturas',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Toca para ver detalle',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ── Lista facturas ─────────────────────
                    Expanded(
                      child: _facturasFiltradas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.receipt_long_outlined,
                                      color: AppColors.textHint, size: 52),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Sin resultados para "$_searchQuery"'
                                        : 'No tienes ventas registradas',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _facturasFiltradas.length,
                              itemBuilder: (context, index) {
                                final f = _facturasFiltradas[index];
                                final total = double.tryParse(
                                        f['factura_total'].toString()) ??
                                    0;
                                final saldo = double.tryParse(
                                        f['factura_saldo'].toString()) ??
                                    0;
                                final facturaIde =
                                    int.tryParse(f['factura_ide'].toString()) ??
                                        0;
                                final facturaNum =
                                    f['factura_num']?.toString() ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DetalleFacturaScreen(
                                            facturaIde: facturaIde,
                                          ),
                                        ),
                                      );
                                    },
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    title: Text(
                                      facturaNum.isNotEmpty ? facturaNum : '-',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f['clien_nombre1'] ?? '',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              _formatFecha(f['factura_fecha']),
                                              style: const TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 11),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _labelCondicion(
                                                  f['factura_condicion']),
                                              style: const TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              FormatoNumero.monedaConSimbolo(
                                                  total),
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _bgEstado(
                                                    f['factura_estado']),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _labelEstado(
                                                    f['factura_estado']),
                                                style: TextStyle(
                                                  color: _colorEstado(
                                                      f['factura_estado']),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (saldo > 0) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Saldo: ${FormatoNumero.monedaConSimbolo(saldo)}',
                                                style: const TextStyle(
                                                  color: AppColors.error,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.print_outlined,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                          tooltip: 'Imprimir',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    NotaEntregaScreen(
                                                  facturaIde: facturaIde,
                                                  facturaNum: facturaNum,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
