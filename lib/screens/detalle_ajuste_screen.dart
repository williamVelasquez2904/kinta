import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/ajuste_service.dart';
import '../services/auditoria_service.dart';
import '../theme/app_theme.dart';

class DetalleAjusteScreen extends StatefulWidget {
  final UserModel user;
  final int ajusteIde;

  const DetalleAjusteScreen({
    super.key,
    required this.user,
    required this.ajusteIde,
  });

  @override
  State<DetalleAjusteScreen> createState() => _DetalleAjusteScreenState();
}

class _DetalleAjusteScreenState extends State<DetalleAjusteScreen> {
  final _service = AjusteService();
  bool _isLoading = true;
  bool _accionando = false;
  Map _ajuste = {};
  List _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.detalle(
        usuaIde: widget.user.usuaIde,
        ajusteIde: widget.ajusteIde,
      );
      if (result['success'] == true) {
        setState(() {
          _ajuste = result['ajuste'];
          _items = result['items'];
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _aplicar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aplicar ajuste'),
        content: const Text(
          '¿Confirmas aplicar este ajuste?\n\n'
          'Se descontarán las unidades del inventario. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aplicar Ajuste'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _accionando = true);
    final result = await _service.aplicar(
      usuaIde: widget.user.usuaIde,
      ajusteIde: widget.ajusteIde,
    );
    setState(() => _accionando = false);

    if (result['success'] == true) {
      await AuditoriaService().aplicarAjuste(
        widget.user,
        widget.ajusteIde,
        _ajuste['ajuste_num'],
        _ajuste['ajuste_razon'],
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );
      if (result['success'] == true) _cargar();
    }
  }

  Future<void> _anular() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular ajuste'),
        content: const Text('¿Estás seguro de anular este ajuste?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _accionando = true);
    final result = await _service.anular(
      usuaIde: widget.user.usuaIde,
      ajusteIde: widget.ajusteIde,
    );
    setState(() => _accionando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.error,
        ),
      );
      if (result['success'] == true) _cargar();
    }
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
    final estado =
        int.tryParse(_ajuste['ajuste_estado']?.toString() ?? '0') ?? 0;
    final razon = _ajuste['ajuste_razon']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_ajuste['ajuste_num'] ?? 'Ajuste'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Estado y razón ────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgEstado(estado),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _iconRazon(razon),
                          color: _colorEstado(estado),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                razon,
                                style: TextStyle(
                                  color: _colorEstado(estado),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _labelEstado(estado),
                                style: TextStyle(
                                    color: _colorEstado(estado), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _ajuste['ajuste_num'] ?? '',
                          style: TextStyle(
                            color: _colorEstado(estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Descripción del motivo ────────────────
                  const Text('MOTIVO',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      )),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _ajuste['ajuste_descripcion'] ?? '',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Info ─────────────────────────────────
                  const Text('INFORMACIÓN',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      )),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _fila('Fecha', _formatFecha(_ajuste['ajuste_fecha'])),
                        _fila('Registrado por',
                            '${_ajuste['usua_nombre'] ?? ''} ${_ajuste['usua_apelli'] ?? ''}'),
                        _fila('Fecha registro',
                            _formatFecha(_ajuste['ajuste_fecha_registro'])),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Productos ─────────────────────────────
                  const Text('PRODUCTOS DADOS DE BAJA',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      )),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: List.generate(_items.length, (i) {
                        final item = _items[i];
                        final cant = double.tryParse(
                                item['detaj_cantidad'].toString()) ??
                            0;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.errorBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.remove_circle_outline,
                                        color: AppColors.error,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item['detaj_descripcion'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '-${cant.toStringAsFixed(0)} uds',
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < _items.length - 1)
                              const Divider(height: 1, color: AppColors.border),
                          ],
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Acciones ──────────────────────────────
                  if (estado == 0) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _accionando ? null : _aplicar,
                        icon: _accionando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.remove_circle_outline),
                        label: const Text(
                          'Aplicar — Descontar del Inventario',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _accionando ? null : _anular,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Anular Ajuste'),
                      ),
                    ),
                  ],

                  if (estado == 1)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: AppColors.error, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ajuste aplicado. Inventario descontado.',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (estado == 2)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cancel_outlined,
                              color: AppColors.textHint, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Ajuste anulado. Sin efecto en inventario.',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _fila(String label, String valor) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                Flexible(
                  child: Text(
                    valor,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 16),
        ],
      );
}
