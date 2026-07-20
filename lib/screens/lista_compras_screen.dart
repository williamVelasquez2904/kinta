import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/compra_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import 'detalle_compra_screen.dart';

class ListaComprasScreen extends StatefulWidget {
  final UserModel user;
  const ListaComprasScreen({super.key, required this.user});

  @override
  State<ListaComprasScreen> createState() => _ListaComprasScreenState();
}

class _ListaComprasScreenState extends State<ListaComprasScreen> {
  final _service = CompraService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List _compras = [];
  double _totalGeneral = 0;
  int _filtroEstado = -1; // -1=todos, 0=pendiente, 1=recibida, 2=anulada

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.listarCompras(
        usuaIde: widget.user.usuaIde,
        estado: _filtroEstado,
        busqueda: _searchCtrl.text,
      );
      if (result['success'] == true) {
        setState(() {
          _compras = result['compras'] ?? [];
          _totalGeneral =
              double.tryParse(result['total_general'].toString()) ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  String _labelEstado(dynamic estado) {
    switch (int.tryParse(estado.toString())) {
      case 0:
        return 'Pendiente';
      case 1:
        return 'Recibida';
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

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '-';
    final str = fecha.toString();
    if (str.length < 10) return str;
    return '${str.substring(8, 10)}/${str.substring(5, 7)}/${str.substring(0, 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColors.primary,
      child: Column(
        children: [
          // ── Resumen ────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    const Text('Total Compras',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    Text('${_compras.length} registros',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 11)),
                  ],
                ),
                Text(
                  FormatoNumero.monedaConSimbolo(_totalGeneral),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Buscador ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _cargar(),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar por N° compra o proveedor...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Chips filtro estado ─────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chipEstado(-1, 'Todos'),
                const SizedBox(width: 8),
                _chipEstado(0, 'Pendientes'),
                const SizedBox(width: 8),
                _chipEstado(1, 'Recibidas'),
                const SizedBox(width: 8),
                _chipEstado(2, 'Anuladas'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Lista ────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _compras.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                color: AppColors.textHint, size: 52),
                            SizedBox(height: 12),
                            Text('Sin compras registradas',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _compras.length,
                        itemBuilder: (ctx, i) {
                          final c = _compras[i];
                          final total =
                              double.tryParse(c['compra_total'].toString()) ??
                                  0;
                          final compraIdeInt =
                              int.tryParse(c['compra_ide'].toString()) ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetalleCompraScreen(
                                      user: widget.user,
                                      compraIde: compraIdeInt,
                                    ),
                                  ),
                                );
                                _cargar();
                              },
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _bgEstado(c['compra_estado']),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: _colorEstado(c['compra_estado']),
                                  size: 22,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    c['compra_num'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _bgEstado(c['compra_estado']),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _labelEstado(c['compra_estado']),
                                      style: TextStyle(
                                        color: _colorEstado(c['compra_estado']),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['prove_nombre'] ?? '-',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatFecha(c['compra_fecha']),
                                    style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                FormatoNumero.monedaConSimbolo(total),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
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

  Widget _chipEstado(int valor, String label) {
    final sel = _filtroEstado == valor;
    return GestureDetector(
      onTap: () {
        setState(() => _filtroEstado = valor);
        _cargar();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryBg : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? AppColors.primary : AppColors.textSecondary,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
