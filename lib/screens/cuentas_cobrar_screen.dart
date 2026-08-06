import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/cxc_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import 'estado_cuenta_screen.dart';

class CuentasCobrarScreen extends StatefulWidget {
  final UserModel user;
  const CuentasCobrarScreen({super.key, required this.user});

  @override
  State<CuentasCobrarScreen> createState() => _CuentasCobrarScreenState();
}

class _CuentasCobrarScreenState extends State<CuentasCobrarScreen> {
  final _service = CxcService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List _clientes = [];
  double _totalDeuda = 0;
  String _errorMsg = '';

  List get _filtrados {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _clientes;
    return _clientes.where((c) {
      final nombre =
          '${c['clien_nombre1']} ${c['clien_apelli1']}'.toLowerCase();
      final cedula = c['clien_numiden']?.toString() ?? '';
      return nombre.contains(q) || cedula.contains(q);
    }).toList();
  }

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
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    final result = await _service.resumen(widget.user.usuaIde);
    if (result['success'] == true) {
      setState(() {
        _clientes = result['clientes'] ?? [];
        _totalDeuda = double.tryParse(result['total_deuda'].toString()) ?? 0;
      });
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error');
    }
    setState(() => _isLoading = false);
  }

  Color _colorSaldo(double saldo) {
    if (saldo > 1000000) return AppColors.error;
    if (saldo > 100000) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas por Cobrar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner total ─────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.errorBg,
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: AppColors.error, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total por cobrar',
                      style: TextStyle(color: AppColors.error, fontSize: 11),
                    ),
                    Text(
                      FormatoNumero.monedaConSimbolo(_totalDeuda),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${_clientes.length} clientes',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ),
          ),

          // ── Buscador ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar cliente o cédula...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // ── Lista ────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMsg.isNotEmpty
                    ? Center(
                        child: Text(_errorMsg,
                            style: const TextStyle(color: AppColors.error)))
                    : _filtrados.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: AppColors.success, size: 52),
                                SizedBox(height: 12),
                                Text(
                                  'Sin cuentas pendientes',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtrados.length,
                            itemBuilder: (_, i) {
                              final c = _filtrados[i];
                              final saldo = double.tryParse(
                                      c['saldo_pendiente'].toString()) ??
                                  0;
                              final facturas = int.tryParse(
                                      c['total_facturas'].toString()) ??
                                  0;
                              final nombre = '${c['clien_nombre1'] ?? ''} '
                                  '${c['clien_apelli1'] ?? ''}';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _colorSaldo(saldo).withAlpha(80),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final clienIde = int.tryParse(
                                              c['clien_ide'].toString()) ??
                                          0;
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EstadoCuentaScreen(
                                            user: widget.user,
                                            clienIde: clienIde,
                                            clienNombre: nombre.trim(),
                                          ),
                                        ),
                                      );
                                      _cargar();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: _colorSaldo(saldo)
                                                  .withAlpha(30),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                c['clien_tipcli']?.toString() ??
                                                    'V',
                                                style: TextStyle(
                                                  color: _colorSaldo(saldo),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          // Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nombre.trim(),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${c['clien_tipcli']}-${c['clien_numiden'] ?? '-'}',
                                                  style: const TextStyle(
                                                      color: AppColors.textHint,
                                                      fontSize: 11),
                                                ),
                                                Text(
                                                  '$facturas factura(s) pendiente(s)',
                                                  style: TextStyle(
                                                      color: _colorSaldo(saldo),
                                                      fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Saldo
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                FormatoNumero.monedaConSimbolo(
                                                    saldo),
                                                style: TextStyle(
                                                  color: _colorSaldo(saldo),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const Text(
                                                'pendiente',
                                                style: TextStyle(
                                                    color: AppColors.textHint,
                                                    fontSize: 10),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                color: AppColors.textHint,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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
}
