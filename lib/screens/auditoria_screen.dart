import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auditoria_service.dart';
import '../theme/app_theme.dart';

class AuditoriaScreen extends StatefulWidget {
  final UserModel user;
  const AuditoriaScreen({super.key, required this.user});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final _service = AuditoriaService();
  final _searchCtrl = TextEditingController();

  DateTime _fechaDesde = DateTime.now().subtract(const Duration(days: 7));
  DateTime _fechaHasta = DateTime.now();

  String _modulo = '';
  String _resultado = '';
  bool _isLoading = false;
  List _registros = [];
  int _total = 0;

  final List<Map<String, String>> _modulos = [
    {'valor': '', 'label': 'Todos'},
    {'valor': 'SESION', 'label': 'Sesión'},
    {'valor': 'VENTA', 'label': 'Ventas'},
    {'valor': 'COMPRA', 'label': 'Compras'},
    {'valor': 'PRODUCTO', 'label': 'Productos'},
    {'valor': 'AJUSTE', 'label': 'Ajustes'},
    {'valor': 'CLIENTE', 'label': 'Clientes'},
    {'valor': 'REPORTE', 'label': 'Reportes'},
  ];

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fechaSql(DateTime d) => '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _fechaDisplay(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _seleccionarFecha(bool esDesde) async {
    final fecha = await showDatePicker(
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
    if (fecha != null && mounted) {
      setState(() {
        if (esDesde)
          _fechaDesde = fecha;
        else
          _fechaHasta = fecha;
      });
    }
  }

  Future<void> _buscar() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.listar(
        usuaIde: widget.user.usuaIde,
        modulo: _modulo,
        fechaDesde: _fechaSql(_fechaDesde),
        fechaHasta: _fechaSql(_fechaHasta),
        busqueda: _searchCtrl.text.trim(),
        resultado: _resultado,
      );
      if (result['success'] == true) {
        setState(() {
          _registros = result['registros'] ?? [];
          _total = result['total'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  // ── Opciones de eliminación ──────────────────────────
  Future<void> _mostrarOpcionesEliminar() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ELIMINAR REGISTROS',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            _opcionEliminar(
              icono: Icons.date_range,
              label: 'Por rango de fechas',
              subtitulo: 'Elimina registros entre dos fechas',
              color: AppColors.info,
              onTap: () async {
                Navigator.pop(context);
                await _eliminarPorFechas();
              },
            ),
            const SizedBox(height: 8),
            _opcionEliminar(
              icono: Icons.category_outlined,
              label: 'Por módulo',
              subtitulo: 'Elimina todos los registros de un módulo',
              color: AppColors.warning,
              onTap: () async {
                Navigator.pop(context);
                await _eliminarPorModulo();
              },
            ),
            const SizedBox(height: 8),
            _opcionEliminar(
              icono: Icons.error_outline,
              label: 'Solo errores',
              subtitulo: 'Limpia todos los registros con resultado ERROR',
              color: AppColors.error,
              onTap: () async {
                Navigator.pop(context);
                await _confirmarEliminar(
                  criterio: 'errores',
                  mensaje: '¿Eliminar todos los registros de error?',
                );
              },
            ),
            const SizedBox(height: 8),
            _opcionEliminar(
              icono: Icons.delete_forever_outlined,
              label: 'Limpiar todo el historial',
              subtitulo: 'Elimina TODOS los registros de auditoría',
              color: AppColors.error,
              onTap: () async {
                Navigator.pop(context);
                await _confirmarEliminar(
                  criterio: 'todo',
                  mensaje: '¿Eliminar TODO el historial de auditoría?\n'
                      'Esta acción no se puede deshacer.',
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _opcionEliminar({
    required IconData icono,
    required String label,
    required String subtitulo,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: color.withAlpha(60)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icono, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          )),
                      Text(subtitulo,
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color, size: 18),
              ],
            ),
          ),
        ),
      );

  Future<void> _eliminarPorFechas() async {
    DateTime desde = DateTime.now().subtract(const Duration(days: 30));
    DateTime hasta = DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Eliminar por fechas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final f = await showDatePicker(
                    context: ctx,
                    initialDate: desde,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (f != null) setDlg(() => desde = f);
                },
                child: _campoFechaDialog('Desde', _fechaDisplay(desde)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final f = await showDatePicker(
                    context: ctx,
                    initialDate: hasta,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (f != null) setDlg(() => hasta = f);
                },
                child: _campoFechaDialog('Hasta', _fechaDisplay(hasta)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await _service.eliminar(
                  usuaIde: widget.user.usuaIde,
                  criterio: 'fechas',
                  fechaDesde: _fechaSql(desde),
                  fechaHasta: _fechaSql(hasta),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message'] ?? ''),
                    backgroundColor: result['success'] == true
                        ? AppColors.success
                        : AppColors.error,
                  ));
                  if (result['success'] == true) _buscar();
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarPorModulo() async {
    String moduloSel = 'SESION';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Eliminar por módulo'),
          content: DropdownButtonFormField<String>(
            value: moduloSel,
            dropdownColor: AppColors.surface,
            items: _modulos
                .where((m) => m['valor']!.isNotEmpty)
                .map((m) => DropdownMenuItem<String>(
                      value: m['valor'],
                      child: Text(m['label']!,
                          style: const TextStyle(color: AppColors.textPrimary)),
                    ))
                .toList(),
            onChanged: (v) => setDlg(() => moduloSel = v ?? 'SESION'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await _service.eliminar(
                  usuaIde: widget.user.usuaIde,
                  criterio: 'modulo',
                  modulo: moduloSel,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message'] ?? ''),
                    backgroundColor: result['success'] == true
                        ? AppColors.success
                        : AppColors.error,
                  ));
                  if (result['success'] == true) _buscar();
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar({
    required String criterio,
    required String mensaje,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final result = await _service.eliminar(
        usuaIde: widget.user.usuaIde,
        criterio: criterio,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.error,
        ));
        if (result['success'] == true) _buscar();
      }
    }
  }

  // ── Colores e íconos ─────────────────────────────────
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
      case 'CONFIRMAR':
        return AppColors.success;
      case 'APLICAR':
        return AppColors.warning;
      case 'EXPORTAR':
        return AppColors.purple;
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
      case 'LOGIN_FALLIDO':
        return Icons.no_accounts;
      case 'CREAR':
        return Icons.add_circle_outline;
      case 'EDITAR':
        return Icons.edit_outlined;
      case 'ELIMINAR':
        return Icons.delete_outline;
      case 'CONFIRMAR':
        return Icons.check_circle_outline;
      case 'APLICAR':
        return Icons.remove_circle_outline;
      case 'EXPORTAR':
        return Icons.picture_as_pdf;
      default:
        return Icons.info_outline;
    }
  }

  String _formatFechaHora(dynamic fecha) {
    if (fecha == null) return '-';
    final str = fecha.toString();
    if (str.length < 16) return str;
    return '${str.substring(8, 10)}/'
        '${str.substring(5, 7)}/'
        '${str.substring(0, 4)}'
        ' ${str.substring(11, 16)}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.tius != 1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auditoría')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: AppColors.error, size: 52),
              SizedBox(height: 12),
              Text(
                'Solo el Administrador del Sistema\n'
                'puede ver la auditoría',
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
        title: Text('Auditoría ($_total)'),
        actions: [
          // ── BOTÓN ELIMINAR ────────────────────────────
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Limpiar registros',
            onPressed: _mostrarOpcionesEliminar,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _buscar,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros ───────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
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

                // Buscador
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Buscar usuario, acción, descripción...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _buscar(),
                ),
                const SizedBox(height: 10),

                // Chips módulo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _modulos.map((m) {
                      final sel = _modulo == m['valor'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _modulo = m['valor']!);
                            _buscar();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primaryBg
                                  : AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    sel ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Text(
                              m['label']!,
                              style: TextStyle(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight:
                                    sel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Chips resultado
                Row(
                  children: [
                    _chipResultado('', 'Todos'),
                    const SizedBox(width: 8),
                    _chipResultado('OK', 'OK', color: AppColors.success),
                    const SizedBox(width: 8),
                    _chipResultado('ERROR', 'Errores', color: AppColors.error),
                  ],
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _buscar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.search, size: 16),
                    label: const Text('Buscar'),
                  ),
                ),
              ],
            ),
          ),

          // ── Lista ─────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _registros.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history,
                                color: AppColors.textHint, size: 52),
                            SizedBox(height: 12),
                            Text('Sin registros',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _registros.length,
                        itemBuilder: (_, i) {
                          final r = _registros[i];
                          final acc = r['audit_accion']?.toString() ?? '';
                          final esError = r['audit_resultado'] == 'ERROR';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: esError
                                  ? AppColors.errorBg
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: esError
                                    ? AppColors.error.withAlpha(80)
                                    : AppColors.border,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ícono acción
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _colorAccion(acc).withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _iconAccion(acc),
                                      color: _colorAccion(acc),
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Badge acción + módulo
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _colorAccion(acc)
                                                    .withAlpha(30),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                acc,
                                                style: TextStyle(
                                                  color: _colorAccion(acc),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              r['audit_modulo']?.toString() ??
                                                  '',
                                              style: const TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 10),
                                            ),
                                            if (esError) ...[
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.error_outline,
                                                color: AppColors.error,
                                                size: 14,
                                              ),
                                            ],
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        // Usuario
                                        Text(
                                          '${r['audit_usua_nombre'] ?? '-'} '
                                          '(@${r['audit_usua_login'] ?? '-'})',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),

                                        // Descripción
                                        Text(
                                          r['audit_descripcion']?.toString() ??
                                              '',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 4),

                                        // Fecha + dispositivo
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time,
                                                color: AppColors.textHint,
                                                size: 11),
                                            const SizedBox(width: 3),
                                            Text(
                                              _formatFechaHora(
                                                  r['audit_fecha']),
                                              style: const TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 10),
                                            ),
                                            const SizedBox(width: 10),
                                            const Icon(Icons.phone_iphone,
                                                color: AppColors.textHint,
                                                size: 11),
                                            const SizedBox(width: 3),
                                            Text(
                                              r['audit_dispositivo']
                                                      ?.toString() ??
                                                  '-',
                                              style: const TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 10),
                                            ),
                                          ],
                                        ),

                                        // Mensaje de error
                                        if (esError &&
                                            (r['audit_error_msg'] ?? '')
                                                .isNotEmpty)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.error.withAlpha(20),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              r['audit_error_msg'].toString(),
                                              style: const TextStyle(
                                                color: AppColors.error,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                      ],
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

  // ── Widgets auxiliares ─────────────────────────────────

  Widget _campoFecha(
    String label,
    DateTime fecha,
    VoidCallback onTap,
  ) =>
      GestureDetector(
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

  Widget _campoFechaDialog(String label, String valor) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: AppColors.textHint, size: 16),
            const SizedBox(width: 8),
            Text(
              '$label: $valor',
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _chipResultado(String valor, String label,
      {Color color = AppColors.textSecondary}) {
    final sel = _resultado == valor;
    return GestureDetector(
      onTap: () {
        setState(() => _resultado = valor);
        _buscar();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? color.withAlpha(30) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? color : AppColors.textSecondary,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
