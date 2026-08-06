import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/cxc_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';

class EstadoCuentaScreen extends StatefulWidget {
  final UserModel user;
  final int clienIde;
  final String clienNombre;

  const EstadoCuentaScreen({
    super.key,
    required this.user,
    required this.clienIde,
    required this.clienNombre,
  });

  @override
  State<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends State<EstadoCuentaScreen>
    with SingleTickerProviderStateMixin {
  final _service = CxcService();
  late TabController _tabCtrl;

  bool _isLoading = true;
  Map _cliente = {};
  List _facturas = [];
  List _pagos = [];
  double _totalSaldo = 0;
  double _totalPagado = 0;

  final List<Map<String, String>> _formasPago = [
    {'valor': 'EFECTIVO', 'label': 'Efectivo'},
    {'valor': 'TRANSFERENCIA', 'label': 'Transferencia'},
    {'valor': 'ZELLE', 'label': 'Zelle'},
    {'valor': 'CHEQUE', 'label': 'Cheque'},
    {'valor': 'OTRO', 'label': 'Otro'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    final result = await _service.estadoCuenta(
      usuaIde: widget.user.usuaIde,
      clienIde: widget.clienIde,
    );
    if (result['success'] == true) {
      setState(() {
        _cliente = result['cliente'] ?? {};
        _facturas = result['facturas'] ?? [];
        _pagos = result['pagos'] ?? [];
        _totalSaldo = double.tryParse(result['total_saldo'].toString()) ?? 0;
        _totalPagado = double.tryParse(result['total_pagado'].toString()) ?? 0;
      });
    }
    setState(() => _isLoading = false);
  }

  String _fechaDisplay(dynamic f) {
    if (f == null) return '-';
    final s = f.toString();
    if (s.length < 10) return s;
    return '${s.substring(8, 10)}/${s.substring(5, 7)}/${s.substring(0, 4)}';
  }

  Future<void> _mostrarDialogoPago(Map factura) async {
    final saldo = double.tryParse(factura['factura_saldo'].toString()) ?? 0;
    final montoCtrl = TextEditingController(text: saldo.toStringAsFixed(2));
    final refCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    String forma = 'EFECTIVO';
    DateTime fecha = DateTime.now();

    String fechaSql(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(factura['factura_num'] ?? '',
                  style:
                      const TextStyle(color: AppColors.primary, fontSize: 14)),
              Text(
                'Saldo: ${FormatoNumero.monedaConSimbolo(saldo)}',
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monto
                TextField(
                  controller: montoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto a pagar *',
                    prefixIcon: Icon(Icons.payments_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 10),

                // Forma de pago
                DropdownButtonFormField<String>(
                  value: forma,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Forma de pago',
                    prefixIcon: Icon(Icons.credit_card_outlined, size: 18),
                  ),
                  items: _formasPago
                      .map((f) => DropdownMenuItem<String>(
                            value: f['valor'],
                            child: Text(f['label']!,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setDlg(() => forma = v ?? 'EFECTIVO'),
                ),
                const SizedBox(height: 10),

                // Referencia
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Referencia (opcional)',
                    prefixIcon: Icon(Icons.tag, size: 18),
                  ),
                ),
                const SizedBox(height: 10),

                // Fecha
                GestureDetector(
                  onTap: () async {
                    final f = await showDatePicker(
                      context: ctx,
                      initialDate: fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (f != null) {
                      setDlg(() => fecha = f);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.textHint, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Fecha: ${fechaSql(fecha)}',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Observaciones
                TextField(
                  controller: obsCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    prefixIcon: Icon(Icons.comment_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Registrar pago'),
              onPressed: () async {
                final monto =
                    double.tryParse(montoCtrl.text.replaceAll(',', '.')) ?? 0;
                if (monto <= 0) return;
                Navigator.pop(ctx);

                final result = await _service.registrarPago(
                  usuaIde: widget.user.usuaIde,
                  facturaIde:
                      int.tryParse(factura['factura_ide'].toString()) ?? 0,
                  clienIde: widget.clienIde,
                  monto: monto,
                  forma: forma,
                  referencia: refCtrl.text.trim(),
                  observa: obsCtrl.text.trim(),
                  fecha: fechaSql(fecha),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? ''),
                      backgroundColor: result['success'] == true
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  );
                  if (result['success'] == true) _cargar();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clienNombre),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Facturas pendientes'),
            Tab(text: 'Historial pagos'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // ── Banner saldo total ─────────────────
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppColors.errorBg,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Saldo pendiente',
                                style: TextStyle(
                                    color: AppColors.error, fontSize: 11)),
                            Text(
                              FormatoNumero.monedaConSimbolo(_totalSaldo),
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total pagado',
                                style: TextStyle(
                                    color: AppColors.success, fontSize: 11)),
                            Text(
                              FormatoNumero.monedaConSimbolo(_totalPagado),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tabs ───────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      // ── Tab 1: Facturas ──────────────
                      _facturas.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: AppColors.success, size: 52),
                                  SizedBox(height: 12),
                                  Text(
                                    'Sin facturas pendientes',
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _facturas.length,
                              itemBuilder: (_, i) {
                                final f = _facturas[i];
                                final saldo = double.tryParse(
                                        f['factura_saldo'].toString()) ??
                                    0;
                                final total = double.tryParse(
                                        f['factura_total'].toString()) ??
                                    0;
                                final dias = int.tryParse(
                                        f['dias_transcurridos'].toString()) ??
                                    0;
                                final vencida = dias >
                                    (int.tryParse(f['factura_dias_credito']
                                            .toString()) ??
                                        30);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: vencida
                                          ? AppColors.error.withAlpha(100)
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              f['factura_num'] ?? '',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Spacer(),
                                            if (vencida)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.errorBg,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Text(
                                                  'VENCIDA',
                                                  style: TextStyle(
                                                      color: AppColors.error,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today,
                                                size: 12,
                                                color: AppColors.textHint),
                                            const SizedBox(width: 4),
                                            Text(
                                              _fechaDisplay(f['factura_fecha']),
                                              style: const TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 11),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '$dias días',
                                              style: TextStyle(
                                                  color: vencida
                                                      ? AppColors.error
                                                      : AppColors.textHint,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Total factura',
                                                    style: TextStyle(
                                                        color:
                                                            AppColors.textHint,
                                                        fontSize: 10)),
                                                Text(
                                                  FormatoNumero
                                                      .monedaConSimbolo(total),
                                                  style: const TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text('Saldo pendiente',
                                                    style: TextStyle(
                                                        color:
                                                            AppColors.textHint,
                                                        fontSize: 10)),
                                                Text(
                                                  FormatoNumero
                                                      .monedaConSimbolo(saldo),
                                                  style: const TextStyle(
                                                      color: AppColors.error,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _mostrarDialogoPago(f),
                                            icon: const Icon(
                                                Icons.payments_outlined,
                                                size: 16),
                                            label: const Text('Registrar pago'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      // ── Tab 2: Historial pagos ───────
                      _pagos.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      color: AppColors.textHint, size: 52),
                                  SizedBox(height: 12),
                                  Text(
                                    'Sin pagos registrados',
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _pagos.length,
                              itemBuilder: (_, i) {
                                final p = _pagos[i];
                                final monto = double.tryParse(
                                        p['pago_monto'].toString()) ??
                                    0;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.success.withAlpha(25),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: AppColors.success,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p['factura_num'] ?? '-',
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                '${p['pago_forma'] ?? ''} · ${p['pago_referencia'] ?? ''}',
                                                style: const TextStyle(
                                                    color: AppColors.textHint,
                                                    fontSize: 10),
                                              ),
                                              Text(
                                                _fechaDisplay(p['pago_fecha']),
                                                style: const TextStyle(
                                                    color: AppColors.textHint,
                                                    fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          FormatoNumero.monedaConSimbolo(monto),
                                          style: const TextStyle(
                                            color: AppColors.success,
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
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
