import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/usuario_service.dart';
import '../theme/app_theme.dart';

class UsuariosScreen extends StatefulWidget {
  final UserModel user;
  const UsuariosScreen({super.key, required this.user});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _service = UsuarioService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List _usuarios = [];
  List _tipos = [];
  List<int> _tiposPermitidos = [];
  String _errorMsg = '';

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

  Future<void> _cargar([String busqueda = '']) async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    final result = await _service.listar(
      usuaIde: widget.user.usuaIde,
      busqueda: busqueda,
    );
    if (result['success'] == true) {
      setState(() {
        _usuarios = result['usuarios'] ?? [];
        _tipos = result['tipos'] ?? [];
        _tiposPermitidos =
            List<int>.from(result['tipos_permitidos_crear'] ?? []);
      });
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error');
    }
    setState(() => _isLoading = false);
  }

  String _labelTius(int tius) {
    switch (tius) {
      case 1:
        return 'Admin Sistema';
      case 2:
        return 'Asistente';
      case 3:
        return 'Admin Tienda';
      case 4:
        return 'Vendedor';
      case 5:
        return 'Vendedor Detal';
      default:
        return 'Desconocido';
    }
  }

  Color _colorTius(int tius) {
    switch (tius) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.info;
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.primary;
      case 5:
        return AppColors.success;
      default:
        return AppColors.textHint;
    }
  }

  // ── Abrir formulario crear/editar ─────────────────────
  Future<void> _abrirFormulario({Map? usuario}) async {
    final esEdicion = usuario != null;
    final tiusTarget =
        esEdicion ? int.tryParse(usuario['usua_tius'].toString()) ?? 0 : 0;

    // Si es edición y el target es nivel 1
    // y el solicitante es nivel 3 → bloquear
    if (esEdicion && tiusTarget == 1 && widget.user.tius == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes editar al Administrador del Sistema'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final editado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _FormUsuario(
          user: widget.user,
          service: _service,
          usuario: usuario,
          tiposPermitidos: _tiposPermitidos,
          tipos: _tipos,
        ),
      ),
    );
    if (editado == true) _cargar(_searchCtrl.text);
  }

  Future<void> _cambiarEstado(Map u) async {
    final ide = int.tryParse(u['usua_ide'].toString()) ?? 0;
    final estadoActual = int.tryParse(u['usua_estado'].toString()) ?? 0;
    final nuevoEstado = estadoActual == 1 ? 0 : 1;
    final accion = nuevoEstado == 1 ? 'activar' : 'desactivar';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${accion[0].toUpperCase()}'
            '${accion.substring(1)} usuario'),
        content: Text('¿${accion[0].toUpperCase()}'
            '${accion.substring(1)} a '
            '"${u['usua_nombre']} ${u['usua_apelli']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  nuevoEstado == 1 ? AppColors.success : AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(accion[0].toUpperCase() + accion.substring(1)),
          ),
        ],
      ),
    );

    if (ok == true) {
      final result = await _service.cambiarEstado(
        usuaIde: widget.user.usuaIde,
        targetIde: ide,
        nuevoEstado: nuevoEstado,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? ''),
            backgroundColor:
                result['success'] == true ? AppColors.success : AppColors.error,
          ),
        );
        if (result['success'] == true) {
          _cargar(_searchCtrl.text);
        }
      }
    }
  }

  Future<void> _cambiarClave(Map u) async {
    final ide = int.tryParse(u['usua_ide'].toString()) ?? 0;
    final claveCtrl = TextEditingController();
    bool visible = false;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cambiar clave: '
                  '${u['usua_nombre']}',
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: claveCtrl,
            autofocus: true,
            obscureText: !visible,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Nueva clave *',
              helperText: 'Mínimo 4 caracteres',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              suffixIcon: IconButton(
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
                    size: 18),
                onPressed: () => setDlg(() => visible = !visible),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final clave = claveCtrl.text.trim();
                if (clave.length < 4) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Mínimo 4 caracteres'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final result = await _service.cambiarClave(
                  usuaIde: widget.user.usuaIde,
                  targetIde: ide,
                  nuevaClave: clave,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message'] ?? ''),
                    backgroundColor: result['success'] == true
                        ? AppColors.success
                        : AppColors.error,
                  ));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    claveCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargar(_searchCtrl.text),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Buscador ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _cargar,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, login, correo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _cargar();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Text(
                  '${_usuarios.length} usuarios',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // ── Lista ─────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMsg.isNotEmpty
                    ? Center(
                        child: Text(_errorMsg,
                            style: const TextStyle(color: AppColors.error)))
                    : _usuarios.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    color: AppColors.textHint, size: 52),
                                SizedBox(height: 12),
                                Text('Sin usuarios',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _usuarios.length,
                            itemBuilder: (_, i) {
                              final u = _usuarios[i];
                              final tius =
                                  int.tryParse(u['usua_tius'].toString()) ?? 0;
                              final activo =
                                  int.tryParse(u['usua_estado'].toString()) ==
                                      1;
                              final esMismo =
                                  int.tryParse(u['usua_ide'].toString()) ==
                                      widget.user.usuaIde;
                              final esAdmin1 = tius == 1;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: activo
                                      ? AppColors.surface
                                      : AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: activo
                                        ? _colorTius(tius).withAlpha(60)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Avatar nivel
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _colorTius(tius)
                                              .withAlpha(activo ? 30 : 15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$tius',
                                            style: TextStyle(
                                              color: _colorTius(tius),
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
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${u['usua_nombre'] ?? ''} ${u['usua_apelli'] ?? ''}',
                                                    style: TextStyle(
                                                      color: activo
                                                          ? AppColors
                                                              .textPrimary
                                                          : AppColors.textHint,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (esMismo)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppColors.primaryBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Text('Tú',
                                                        style: TextStyle(
                                                            color: AppColors
                                                                .primary,
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                              ],
                                            ),
                                            Text(
                                              '@${u['usua_login'] ?? '-'}',
                                              style: TextStyle(
                                                color: activo
                                                    ? AppColors.textHint
                                                    : AppColors.border,
                                                fontSize: 11,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: _colorTius(tius)
                                                        .withAlpha(20),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    _labelTius(tius),
                                                    style: TextStyle(
                                                        color: _colorTius(tius),
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: activo
                                                        ? AppColors.successBg
                                                        : AppColors.errorBg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    activo
                                                        ? 'Activo'
                                                        : 'Inactivo',
                                                    style: TextStyle(
                                                        color: activo
                                                            ? AppColors.success
                                                            : AppColors.error,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Menú acciones
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            color: AppColors.textHint),
                                        color: AppColors.surface,
                                        onSelected: (v) {
                                          if (v == 'editar') {
                                            _abrirFormulario(usuario: u);
                                          } else if (v == 'clave') {
                                            _cambiarClave(u);
                                          } else if (v == 'estado') {
                                            _cambiarEstado(u);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'editar',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined,
                                                    color: AppColors.info,
                                                    size: 18),
                                                SizedBox(width: 8),
                                                Text('Editar',
                                                    style: TextStyle(
                                                        color: AppColors
                                                            .textPrimary)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'clave',
                                            child: Row(
                                              children: [
                                                Icon(Icons.lock_reset,
                                                    color: AppColors.warning,
                                                    size: 18),
                                                SizedBox(width: 8),
                                                Text('Cambiar clave',
                                                    style: TextStyle(
                                                        color: AppColors
                                                            .textPrimary)),
                                              ],
                                            ),
                                          ),
                                          if (!esMismo &&
                                              !(esAdmin1 &&
                                                  widget.user.tius == 3))
                                            PopupMenuItem(
                                              value: 'estado',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    activo
                                                        ? Icons
                                                            .person_off_outlined
                                                        : Icons.person_outlined,
                                                    color: activo
                                                        ? AppColors.error
                                                        : AppColors.success,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    activo
                                                        ? 'Desactivar'
                                                        : 'Activar',
                                                    style: TextStyle(
                                                        color: activo
                                                            ? AppColors.error
                                                            : AppColors
                                                                .success),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
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

// ── Formulario crear/editar usuario ───────────────────────
class _FormUsuario extends StatefulWidget {
  final UserModel user;
  final UsuarioService service;
  final Map? usuario;
  final List<int> tiposPermitidos;
  final List tipos;

  const _FormUsuario({
    required this.user,
    required this.service,
    required this.tiposPermitidos,
    required this.tipos,
    this.usuario,
  });

  @override
  State<_FormUsuario> createState() => _FormUsuarioState();
}

class _FormUsuarioState extends State<_FormUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _nomidenCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apelliCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _direcciCtrl = TextEditingController();

  bool _verClave = false;
  bool _isLoading = false;
  int _tiusSelec = 0;
  String _tipo = 'V';
  DateTime _fecnaci = DateTime(2000, 1, 1);

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();

    // Tipo por defecto: el primero permitido
    if (widget.tiposPermitidos.isNotEmpty) {
      _tiusSelec = widget.tiposPermitidos.first;
    }

    if (_esEdicion) {
      final u = widget.usuario!;
      _loginCtrl.text = u['usua_login']?.toString() ?? '';
      _nomidenCtrl.text = u['usua_numiden']?.toString() ?? '';
      _nombreCtrl.text = u['usua_nombre']?.toString() ?? '';
      _apelliCtrl.text = u['usua_apelli']?.toString() ?? '';
      _telCtrl.text = u['usua_telmovi']?.toString() ?? '';
      _correoCtrl.text = u['usua_correo']?.toString() ?? '';
      _direcciCtrl.text = u['usua_direcci']?.toString() ?? '';
      _tipo = u['usua_tipo']?.toString() ?? 'V';
      _tiusSelec = int.tryParse(u['usua_tius'].toString()) ?? 0;

      final fn = u['usua_fecnaci']?.toString() ?? '';
      if (fn.length >= 10) {
        _fecnaci = DateTime.tryParse(fn) ?? DateTime(2000, 1, 1);
      }
    }
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _claveCtrl.dispose();
    _nomidenCtrl.dispose();
    _nombreCtrl.dispose();
    _apelliCtrl.dispose();
    _telCtrl.dispose();
    _correoCtrl.dispose();
    _direcciCtrl.dispose();
    super.dispose();
  }

  String _fechaSql(DateTime d) => '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _fechaDisplay(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _seleccionarFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecnaci,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (f != null && mounted) {
      setState(() => _fecnaci = f);
    }
  }

  String _labelTius(int t) {
    switch (t) {
      case 2:
        return 'Asistente';
      case 3:
        return 'Admin Tienda';
      case 4:
        return 'Vendedor';
      case 5:
        return 'Vendedor Detal';
      default:
        return 'Nivel $t';
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tiusSelec == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el tipo de usuario'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final datos = {
      'usua_tius': _tiusSelec,
      'usua_tipo': _tipo,
      'usua_numiden': _nomidenCtrl.text.trim(),
      'usua_nombre': _nombreCtrl.text.trim(),
      'usua_apelli': _apelliCtrl.text.trim(),
      'usua_fecnaci': _fechaSql(_fecnaci),
      'usua_direcci': _direcciCtrl.text.trim(),
      'usua_telmovi': _telCtrl.text.trim(),
      'usua_correo': _correoCtrl.text.trim(),
      'usua_visible': 1,
      'usua_tienda': 1,
    };

    if (!_esEdicion) {
      datos['usua_login'] = _loginCtrl.text.trim();
      datos['usua_clave'] = _claveCtrl.text;
    }

    Map<String, dynamic> result;
    if (_esEdicion) {
      final targetIde =
          int.tryParse(widget.usuario!['usua_ide'].toString()) ?? 0;
      result = await widget.service.editar(
        usuaIde: widget.user.usuaIde,
        targetIde: targetIde,
        datos: datos,
      );
    } else {
      result = await widget.service.crear(
        usuaIde: widget.user.usuaIde,
        datos: datos,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'OK'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Usuario' : 'Nuevo Usuario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tipo de usuario ──────────────────────
              _seccion('TIPO DE USUARIO'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.tiposPermitidos.map((t) {
                  final sel = _tiusSelec == t;
                  return GestureDetector(
                    onTap: () => setState(() => _tiusSelec = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryBg : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.border,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$t',
                            style: TextStyle(
                              color:
                                  sel ? AppColors.primary : AppColors.textHint,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _labelTius(t),
                            style: TextStyle(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Acceso ───────────────────────────────
              if (!_esEdicion) ...[
                _seccion('ACCESO'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _loginCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Login *',
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                    helperText: 'Máximo 10 caracteres, sin espacios',
                  ),
                  maxLength: 10,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El login es requerido';
                    }
                    if (v.contains(' ')) {
                      return 'Sin espacios';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _claveCtrl,
                  obscureText: !_verClave,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Clave *',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    helperText: 'Mínimo 4 caracteres',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _verClave ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _verClave = !_verClave),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'La clave es requerida';
                    }
                    if (v.length < 4) {
                      return 'Mínimo 4 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // ── Identificación ───────────────────────
              _seccion('IDENTIFICACIÓN'),
              const SizedBox(height: 8),
              const Text('Tipo',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['V', 'E', 'J', 'G'].map((t) {
                  final sel = _tipo == t;
                  return GestureDetector(
                    onTap: () => setState(() => _tipo = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryBg : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(t,
                          style: TextStyle(
                            color: sel ? AppColors.primary : AppColors.textHint,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nomidenCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Cédula / RIF',
                  prefixIcon: Icon(Icons.badge_outlined, size: 18),
                ),
              ),

              const SizedBox(height: 20),

              // ── Nombre ───────────────────────────────
              _seccion('NOMBRE'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        prefixIcon: Icon(Icons.person_outline, size: 18),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _apelliCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        prefixIcon: Icon(Icons.person_outline, size: 18),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Fecha nacimiento ─────────────────────
              _seccion('FECHA DE NACIMIENTO'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _seleccionarFecha,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined,
                          color: AppColors.textHint, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _fechaDisplay(_fecnaci),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar,
                          color: AppColors.textHint, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Contacto ─────────────────────────────
              _seccion('CONTACTO'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _direcciCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                ),
              ),

              const SizedBox(height: 28),

              // ── Botón guardar ────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _guardar,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading
                        ? 'Guardando...'
                        : _esEdicion
                            ? 'Actualizar Usuario'
                            : 'Crear Usuario',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(String t) => Text(t,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ));
}
