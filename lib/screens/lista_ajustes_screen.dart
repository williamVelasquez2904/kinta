import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/ajuste_service.dart';
import '../theme/app_theme.dart';
import 'detalle_ajuste_screen.dart';

class ListaAjustesScreen extends StatefulWidget {
  final UserModel user;
  const ListaAjustesScreen({super.key, required this.user});

  @override
  State<ListaAjustesScreen> createState() => _ListaAjustesScreenState();
}

class _ListaAjustesScreenState extends State<ListaAjustesScreen> {
  final _service = AjusteService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List _ajustes = [];
  int _filtroEstado = -1;

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
      final result = await _service.listar(
        usuaIde: widget.user.usuaIde,
        estado: _filtroEstado,
        busqueda: _searchCtrl.text,
      );
      if (result['success'] == true) {
        setState(() => _ajustes = result['ajustes'] ?? []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  String _labelEstado(dynamic e) {
    switch (int.tryParse(e.toString())) {
      case 0:
        return 'Borrador';
      case 1:
        return 'Aplicado';
      case 2:
        return 'Anulado';
      default:
        return 'N/D';
    }
  }

  Color _colorEstado(dynamic e) {
    switch (int.tryParse(e.toString())) {
      case 0:
        return AppColors.warning;
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.textHint;
      default:
        return AppColors.textHint;
    }
  }

  Color _bgEstado(dynamic e) {
    switch (int.tryParse(e.toString())) {
      case 0:
        return AppColors.warningBg;
      case 1:
        return AppColors.errorBg;
      case 2:
        return AppColors.surfaceAlt;
      default:
        return AppColors.surfaceAlt;
    }
  }

  IconData _iconRazon(String razon) {
    switch (razon) {
      case 'DETERIORO':
        return Icons.broken_image_outlined;
      case 'VENCIMIENTO':
        return Icons.event_busy_outlined;
      case 'DONACION':
        return Icons.volunteer_activism;
      case 'ROBO':
        return Icons.security_outlined;
      default:
        return Icons.help_outline;
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
          // Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _cargar(),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar ajuste...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Chips filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _chip(-1, 'Todos'),
                const SizedBox(width: 8),
                _chip(0, 'Borrador'),
                const SizedBox(width: 8),
                _chip(1, 'Aplicados'),
                const SizedBox(width: 8),
                _chip(2, 'Anulados'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${_ajustes.length} ajustes',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _ajustes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_circle_outline,
                                color: AppColors.textHint, size: 52),
                            SizedBox(height: 12),
                            Text('Sin ajustes registrados',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _ajustes.length,
                        itemBuilder: (_, i) {
                          final a = _ajustes[i];
                          final ajusteIdeInt =
                              int.tryParse(a['ajuste_ide'].toString()) ?? 0;
                          final razon = a['ajuste_razon']?.toString() ?? '';
                          final unidades = double.tryParse(
                                  a['total_unidades']?.toString() ?? '0') ??
                              0;

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
                                    builder: (_) => DetalleAjusteScreen(
                                      user: widget.user,
                                      ajusteIde: ajusteIdeInt,
                                    ),
                                  ),
                                );
                                _cargar();
                              },
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _bgEstado(a['ajuste_estado']),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _iconRazon(razon),
                                  color: _colorEstado(a['ajuste_estado']),
                                  size: 22,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    a['ajuste_num'] ?? '',
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
                                      color: _bgEstado(a['ajuste_estado']),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _labelEstado(a['ajuste_estado']),
                                      style: TextStyle(
                                        color: _colorEstado(a['ajuste_estado']),
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
                                    razon,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    a['ajuste_descripcion'] ?? '',
                                    style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatFecha(a['ajuste_fecha']),
                                    style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${a['total_items'] ?? 0} prods',
                                    style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 10),
                                  ),
                                  Text(
                                    '-${unidades.toStringAsFixed(0)} uds',
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
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

  Widget _chip(int valor, String label) {
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
