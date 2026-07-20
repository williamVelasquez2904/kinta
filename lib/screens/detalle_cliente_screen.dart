import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/cliente_service.dart';
import '../theme/app_theme.dart';
import 'form_cliente_screen.dart';

class DetalleClienteScreen extends StatefulWidget {
  final UserModel user;
  final int clienIde;

  const DetalleClienteScreen({
    super.key,
    required this.user,
    required this.clienIde,
  });

  @override
  State<DetalleClienteScreen> createState() => _DetalleClienteScreenState();
}

class _DetalleClienteScreenState extends State<DetalleClienteScreen> {
  final _service = ClienteService();
  bool _isLoading = true;
  Map _cliente = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      // ── Corrección: pasar usuaIde ────────────────────
      final result = await _service.detalle(
        widget.clienIde,
        usuaIde: widget.user.usuaIde,
      );
      debugPrint('detalle_cliente resultado: $result');
      if (result['success'] == true) {
        setState(() => _cliente = result['cliente']);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al cargar cliente'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error en _cargar: $e');
    }
    setState(() => _isLoading = false);
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '-';
    final str = fecha.toString();
    if (str.length < 10) return str;
    return '${str.substring(8, 10)}/'
        '${str.substring(5, 7)}/'
        '${str.substring(0, 4)}';
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'V':
        return AppColors.primary;
      case 'E':
        return AppColors.info;
      case 'J':
        return AppColors.warning;
      case 'G':
        return AppColors.success;
      default:
        return AppColors.textHint;
    }
  }

  String _labelTipoCompleto(String tipo) {
    switch (tipo) {
      case 'V':
        return 'Venezolano';
      case 'E':
        return 'Extranjero';
      case 'J':
        return 'Jurídico';
      case 'G':
        return 'Gubernamental';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipo = _cliente['clien_tipcli']?.toString() ?? 'V';
    final nombre = '${_cliente['clien_nombre1'] ?? ''} '
            '${_cliente['clien_nombre2'] ?? ''} '
            '${_cliente['clien_apelli1'] ?? ''} '
            '${_cliente['clien_apelli2'] ?? ''}'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    final numiden = _cliente['clien_numiden']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Detalle Cliente' : nombre),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () async {
                final editado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormClienteScreen(
                      user: widget.user,
                      clienIde: widget.clienIde,
                    ),
                  ),
                );
                if (editado == true) _cargar();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _cargar,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Banner principal ──────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _colorTipo(tipo).withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _colorTipo(tipo).withAlpha(60)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _colorTipo(tipo).withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              tipo,
                              style: TextStyle(
                                color: _colorTipo(tipo),
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre.isEmpty ? '-' : nombre,
                                style: TextStyle(
                                  color: _colorTipo(tipo),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$tipo-$numiden',
                                style: TextStyle(
                                    color: _colorTipo(tipo), fontSize: 12),
                              ),
                              Text(
                                _labelTipoCompleto(tipo),
                                style: TextStyle(
                                    color: _colorTipo(tipo).withAlpha(180),
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),

                        // Badge contribuyente especial
                        if ((_cliente['clien_contriespec']?.toString() ??
                                '0') ==
                            '1')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.warning),
                            ),
                            child: const Text(
                              'C. Especial',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Contacto ──────────────────────────
                  _seccion('CONTACTO'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(
                      Icons.phone_outlined,
                      'Celular',
                      _cliente['clien_telmovi']?.toString() ?? '-',
                    ),
                    _fila(
                      Icons.phone_outlined,
                      'Celular 2',
                      _cliente['clien_telmovi2']?.toString() ?? '-',
                    ),
                    _fila(
                      Icons.email_outlined,
                      'Correo',
                      _cliente['clien_correo']?.toString() ?? '-',
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Dirección ─────────────────────────
                  _seccion('DIRECCIÓN'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(
                      Icons.location_on_outlined,
                      'Dirección',
                      _cliente['clien_direcci']?.toString() ?? '-',
                    ),
                    _fila(
                      Icons.location_city_outlined,
                      'Ciudad',
                      _cliente['clien_ciudad']?.toString() ?? '-',
                    ),
                    _fila(
                      Icons.flag_outlined,
                      'País',
                      _cliente['clien_pais']?.toString() ?? '-',
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Datos adicionales ─────────────────
                  _seccion('DATOS ADICIONALES'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(
                      Icons.cake_outlined,
                      'Fecha nac.',
                      _formatFecha(_cliente['clien_fecnaci']),
                    ),
                    _fila(
                      Icons.qr_code,
                      'Código interno',
                      _cliente['clien_codigo']?.toString() ?? '-',
                    ),
                    _fila(
                      Icons.local_shipping_outlined,
                      'Empresa envío',
                      _cliente['clien_empresa_envio']?.toString() ?? '-',
                    ),
                    _fila(
                      Icons.store_outlined,
                      'Código oficina',
                      _cliente['clien_codigo_oficina']?.toString() ?? '-',
                    ),
                    _fila(
                      Icons.storefront_outlined,
                      'Nombre oficina',
                      _cliente['clien_nombre_oficina']?.toString() ?? '-',
                    ),
                    _fila(
                      Icons.person_pin_outlined,
                      'Vendedor ID',
                      _cliente['clien_vendedor']?.toString() ?? '-',
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Fiscal ────────────────────────────
                  _seccion('DATOS FISCALES'),
                  const SizedBox(height: 8),
                  _bloque([
                    _filaSwitch(
                      Icons.receipt_long_outlined,
                      'Contribuyente Especial',
                      (_cliente['clien_contriespec']?.toString() ?? '0') == '1',
                    ),
                  ]),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ── Widgets auxiliares ─────────────────────────────────

  Widget _seccion(String t) => Text(t,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ));

  Widget _bloque(List<Widget> hijos) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: hijos),
      );

  Widget _fila(IconData icono, String label, String valor) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(icono, color: AppColors.textHint, size: 17),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    valor.isEmpty ? '-' : valor,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 40),
        ],
      );

  Widget _filaSwitch(IconData icono, String label, bool activo) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(icono, color: AppColors.textHint, size: 17),
            const SizedBox(width: 10),
            Text(
              label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: activo
                    ? AppColors.success.withAlpha(30)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    activo ? Icons.check_circle : Icons.cancel_outlined,
                    color: activo ? AppColors.success : AppColors.textHint,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activo ? 'Sí' : 'No',
                    style: TextStyle(
                      color: activo ? AppColors.success : AppColors.textHint,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
