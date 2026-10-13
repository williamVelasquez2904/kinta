import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/monitor_service.dart';
import '../theme/app_theme.dart';

class MonitorScreen extends StatefulWidget {
  final UserModel user;
  const MonitorScreen({super.key, required this.user});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen>
    with SingleTickerProviderStateMixin {
  final _service = MonitorService();
  late TabController _tabCtrl;

  // Resumen
  Map _resumen = {};
  bool _loadResumen = true;

  // Lista
  List _registros = [];
  List<String> _clientes = [];
  bool _loadLista = true;
  String _errorMsg = '';

  // Filtros lista
  String _clienteF = '';
  String _accionF = '';
  String _moduloF = '';
  String _resultadoF = '';
  DateTime _fechaDesde = DateTime.now().subtract(const Duration(days: 1));
  DateTime _fechaHasta = DateTime.now();
  final _searchCtrl = TextEditingController();

  final List<String> _acciones = [
    '',
    'LOGIN',
    'LOGOUT',
    'CREAR',
    'EDITAR',
    'ELIMINAR',
    'EXPORTAR',
    'CONFIRMAR',
    'APLICAR',
  ];
  final List<String> _modulos = [
    '',
    'SESION',
    'VENTA',
    'PRODUCTO',
    'COMPRA',
    'AJUSTE',
    'CLIENTE',
    'REPORTE',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _cargarResumen();
    _cargarLista();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fechaSql(DateTime d) => '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _fechaDisplay(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _cargarResumen() async {
    setState(() => _loadResumen = true);
    final result = await _service.resumen();
    if (result['success'] == true && mounted) {
      setState(() => _resumen = result);
    }
    setState(() => _loadResumen = false);
  }

  Future<void> _cargarLista() async {
    setState(() {
      _loadLista = true;
      _errorMsg = '';
    });
    final result = await _service.listar(
      clienteId: _clienteF,
      accionF: _accionF,
      moduloF: _moduloF,
      resultadoF: _resultadoF,
      busqueda: _searchCtrl.text.trim(),
      fechaDesde: _fechaSql(_fechaDesde),
      fechaHasta: _fechaSql(_fechaHasta),
    );
    if (result['success'] == true && mounted) {
      setState(() {
        _registros = result['registros'] ?? [];
        _clientes = List<String>.from(result['clientes'] ?? []);
      });
    } else if (mounted) {
      setState(() => _errorMsg = result['message'] ?? 'Error');
    }
    setState(() => _loadLista = false);
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final f = await showDatePicker(
      context: context,
      initialDate: esDesde ? _fechaDesde : _fechaHasta,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (f != null && mounted) {
      setState(() {
        if (esDesde)
          _fechaDesde = f;
        else
          _fechaHasta = f;
      });
      _cargarLista();
    }
  }

  Color _colorAccion(String accion) {
    switch (accion) {
      case 'LOGIN':
        return AppColors.success;
      case 'LOGOUT':
        return AppColors.textHint;
      case 'LOGIN_FALLIDO':
        return AppColors.error;
      case 'CREAR':
        return AppColors.primary;
      case 'EDITAR':
        return AppColors.info;
      case 'ELIMINAR':
        return AppColors.error;
      case 'EXPORTAR':
        return AppColors.purple;
      case 'CONFIRMAR':
        return AppColors.success;
      case 'APLICAR':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _iconAccion(String accion) {
    switch (accion) {
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'CREAR':
        return Icons.add_circle_outline;
      case 'EDITAR':
        return Icons.edit_outlined;
      case 'ELIMINAR':
        return Icons.delete_outline;
      case 'EXPORTAR':
        return Icons.picture_as_pdf;
      case 'CONFIRMAR':
        return Icons.check_circle_outline;
      case 'APLICAR':
        return Icons.tune;
      default:
        return Icons.info_outline;
    }
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '-';
    final str = fecha.toString();
    if (str.length < 16) return str;
    return '${str.substring(8, 10)}/'
        '${str.substring(5, 7)}/'
        '${str.substring(0, 4)}'
        ' ${str.substring(11, 16)}';
  }

  Future<void> _eliminarRegistro(int index) async {
    final registro = _registros[index];
    final ide = _obtenerId(registro);

    if (ide == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar el registro a borrar.'),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar evento'),
        content: const Text('¿Deseas eliminar este registro del monitor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final result = await _service.eliminar(ide: ide);
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _registros.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado del monitor')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'No se pudo eliminar el evento.'),
        ),
      );
    }
  }

  Future<void> _limpiarMonitor() async {
    if (_registros.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar monitor'),
        content: const Text(
            '¿Deseas eliminar todos los eventos del monitor para depurar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final result = await _service.limpiar();
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _registros.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monitor depurado')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'No se pudo limpiar el monitor.'),
        ),
      );
    }
  }

  int? _obtenerId(Map<String, dynamic> registro) {
    const claves = ['ide', 'id', 'mon_ide', 'mon_id'];
    for (final clave in claves) {
      final valor = registro[clave];
      if (valor == null) continue;
      final id = int.tryParse(valor.toString());
      if (id != null) return id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Solo tius 1 puede ver el monitor
    if (widget.user.tius != 1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Monitor Kinta')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: AppColors.error, size: 52),
              SizedBox(height: 12),
              Text(
                'Acceso restringido al\nAdministrador del Sistema',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.monitor_heart,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Monitor Kinta'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Borrar todo',
            onPressed: _registros.isEmpty ? null : _limpiarMonitor,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarResumen();
              _cargarLista();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(
                icon: Icon(Icons.dashboard_outlined, size: 18),
                text: 'Resumen'),
            Tab(icon: Icon(Icons.list_alt_outlined, size: 18), text: 'Eventos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildResumen(),
          _buildEventos(),
        ],
      ),
    );
  }

  // ── Tab 1: Resumen ────────────────────────────────────
  Widget _buildResumen() {
    if (_loadResumen) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final hoy = _resumen['hoy'] ?? 0;
    final logins = _resumen['logins_hoy'] ?? 0;
    final errores = _resumen['errores_hoy'] ?? 0;
    final clientes = _resumen['clientes_activos'] ?? 0;
    final total = _resumen['total'] ?? 0;
    final porCliente = _resumen['por_cliente'] as List? ?? [];
    final porAccion = _resumen['por_accion'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _cargarResumen,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tarjetas KPI ────────────────────────────
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _kpi('Eventos hoy', '$hoy', Icons.today, AppColors.primary),
                _kpi('Logins hoy', '$logins', Icons.login, AppColors.success),
                _kpi('Errores hoy', '$errores', Icons.error_outline,
                    AppColors.error),
                _kpi('Clientes activos', '$clientes', Icons.business_outlined,
                    AppColors.info),
              ],
            ),

            const SizedBox(height: 8),

            // Total histórico
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Text('Total histórico de eventos',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  const Spacer(),
                  Text('$total',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Actividad por cliente ───────────────────
            _seccion('ACTIVIDAD POR CLIENTE'),
            const SizedBox(height: 8),

            if (porCliente.isEmpty)
              _vacio('Sin actividad registrada')
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: List.generate(porCliente.length, (i) {
                    final c = porCliente[i];
                    final totalC = int.tryParse(c['total'].toString()) ?? 0;
                    final loginsC = int.tryParse(c['logins'].toString()) ?? 0;
                    final ult = c['ultima_actividad']?.toString() ?? '';

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Badge cliente
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c['mon_cliente_id']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Última: ${_formatFecha(ult)}',
                                      style: const TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 10),
                                    ),
                                    Text(
                                      '$loginsC logins',
                                      style: const TextStyle(
                                          color: AppColors.success,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$totalC eventos',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i < porCliente.length - 1)
                          const Divider(height: 1, color: AppColors.border),
                      ],
                    );
                  }),
                ),
              ),

            const SizedBox(height: 20),

            // ── Acciones de hoy ─────────────────────────
            _seccion('ACCIONES DE HOY'),
            const SizedBox(height: 8),

            if (porAccion.isEmpty)
              _vacio('Sin acciones hoy')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: porAccion.map((a) {
                  final acc = a['mon_accion']?.toString() ?? '';
                  final count = a['total']?.toString() ?? '0';
                  final color = _colorAccion(acc);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconAccion(acc), color: color, size: 14),
                        const SizedBox(width: 6),
                        Text(acc,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(count,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Eventos ────────────────────────────────────
  Widget _buildEventos() {
    return Column(
      children: [
        // ── Filtros ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Column(
            children: [
              // Buscador
              TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _cargarLista(),
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar usuario, cliente...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            _cargarLista();
                          },
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 8),

              // Fechas
              Row(
                children: [
                  Expanded(
                      child: _campoFecha(
                          'Desde', _fechaDesde, () => _seleccionarFecha(true))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _campoFecha('Hasta', _fechaHasta,
                          () => _seleccionarFecha(false))),
                ],
              ),

              const SizedBox(height: 8),

              // Fila de selects
              Row(
                children: [
                  Expanded(
                    child: _dropFiltro(
                      valor: _clienteF,
                      hint: 'Cliente',
                      items: ['', ..._clientes],
                      labels: {
                        '': 'Todos',
                        for (var c in _clientes) c: c,
                      },
                      onChanged: (v) {
                        setState(() => _clienteF = v ?? '');
                        _cargarLista();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dropFiltro(
                      valor: _accionF,
                      hint: 'Acción',
                      items: _acciones,
                      labels: {
                        '': 'Todas',
                        'LOGIN': 'Login',
                        'LOGOUT': 'Logout',
                        'CREAR': 'Crear',
                        'EDITAR': 'Editar',
                        'ELIMINAR': 'Eliminar',
                        'EXPORTAR': 'Exportar',
                        'CONFIRMAR': 'Confirmar',
                        'APLICAR': 'Aplicar',
                      },
                      onChanged: (v) {
                        setState(() => _accionF = v ?? '');
                        _cargarLista();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dropFiltro(
                      valor: _resultadoF,
                      hint: 'Resultado',
                      items: ['', 'OK', 'ERROR'],
                      labels: {
                        '': 'Todos',
                        'OK': 'OK',
                        'ERROR': 'Error',
                      },
                      onChanged: (v) {
                        setState(() => _resultadoF = v ?? '');
                        _cargarLista();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Contador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text(
                '${_registros.length} eventos',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),

        // ── Lista de eventos ────────────────────────────
        Expanded(
          child: _loadLista
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMsg.isNotEmpty
                  ? Center(
                      child: Text(_errorMsg,
                          style: const TextStyle(color: AppColors.error)))
                  : _registros.isEmpty
                      ? _vacio('Sin eventos en el período')
                      : RefreshIndicator(
                          onRefresh: _cargarLista,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _registros.length,
                            itemBuilder: (_, i) => _buildEvento(i),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildEvento(int i) {
    final r = _registros[i];
    final acc = r['mon_accion']?.toString() ?? '';
    final esErr = r['mon_resultado'] == 'ERROR';
    final cliente = r['mon_cliente_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: esErr ? AppColors.errorBg : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: esErr ? AppColors.error.withAlpha(80) : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono acción
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _colorAccion(acc).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconAccion(acc), color: _colorAccion(acc), size: 18),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila: acción + cliente
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _colorAccion(acc).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(acc,
                            style: TextStyle(
                                color: _colorAccion(acc),
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      // Badge cliente
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(cliente,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (esErr) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 14),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Usuario
                  Text(
                    '${r['mon_usua_nombre'] ?? '-'}'
                    ' (@${r['mon_usua_login'] ?? '-'})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),

                  // Descripción
                  Text(
                    r['mon_descripcion']?.toString() ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  // Meta: fecha + IP + dispositivo
                  Wrap(
                    spacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time,
                              color: AppColors.textHint, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            _formatFecha(r['mon_fecha']),
                            style: const TextStyle(
                                color: AppColors.textHint, fontSize: 10),
                          ),
                        ],
                      ),
                      if ((r['mon_ip'] ?? '').isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lan_outlined,
                                color: AppColors.textHint, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              r['mon_ip'].toString(),
                              style: const TextStyle(
                                  color: AppColors.textHint, fontSize: 10),
                            ),
                          ],
                        ),
                      if ((r['mon_dispositivo'] ?? '').isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_iphone,
                                color: AppColors.textHint, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              r['mon_dispositivo'].toString(),
                              style: const TextStyle(
                                  color: AppColors.textHint, fontSize: 10),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Error msg
                  if (esErr && (r['mon_error_msg'] ?? '').isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r['mon_error_msg'].toString(),
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _eliminarRegistro(i),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Borrar evento',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets auxiliares ─────────────────────────────────

  Widget _kpi(String label, String valor, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const Spacer(),
                Text(
                  valor,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      );

  Widget _seccion(String t) => Text(t,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ));

  Widget _vacio(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.inbox_outlined,
                  color: AppColors.textHint, size: 48),
              const SizedBox(height: 12),
              Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );

  Widget _campoFecha(String label, DateTime fecha, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: AppColors.textHint, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 9)),
                    Text(_fechaDisplay(fecha),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _dropFiltro({
    required String valor,
    required String hint,
    required List<String> items,
    required Map<String, String> labels,
    required void Function(String?) onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButton<String>(
          value: valor,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          dropdownColor: AppColors.surface,
          hint: Text(hint,
              style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
          items: items
              .map((v) => DropdownMenuItem(
                    value: v,
                    child:
                        Text(labels[v] ?? v, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      );
}
