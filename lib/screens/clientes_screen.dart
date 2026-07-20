import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/cliente_service.dart';
import '../theme/app_theme.dart';
import 'form_cliente_screen.dart';
import 'detalle_cliente_screen.dart';

class ClientesScreen extends StatefulWidget {
  final UserModel user;
  const ClientesScreen({super.key, required this.user});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _service = ClienteService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String _errorMsg = '';
  List _clientes = [];
  String _tipcli = '';

  final List<Map<String, String>> _filtrosTipo = [
    {'valor': '', 'label': 'Todos'},
    {'valor': 'V', 'label': 'Venezolano'},
    {'valor': 'E', 'label': 'Extranjero'},
    {'valor': 'J', 'label': 'Jurídico'},
    {'valor': 'G', 'label': 'Gubernamental'},
  ];

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
    try {
      final result = await _service.listar(
        usuaIde: widget.user.usuaIde,
        busqueda: busqueda,
        tipcli: _tipcli,
      );
      /*
      final result = await _service.listar(
        busqueda: busqueda,
        tipcli: _tipcli,
      );*/
      if (result['success'] == true) {
        setState(() => _clientes = result['clientes'] ?? []);
      } else {
        setState(() => _errorMsg = result['message'] ?? 'Error');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _confirmarEliminar(Map c) async {
    final nombre = '${c['clien_nombre1']} ${c['clien_apelli1'] ?? ''}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('¿Eliminar a "$nombre"?'),
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

    if (ok == true) {
      final result = await _service.eliminar(
        usuaIde: widget.user.usuaIde,
        clienIde: int.tryParse(c['clien_ide'].toString()) ?? 0,
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

  String _labelTipo(String tipo) {
    switch (tipo) {
      case 'V':
        return 'V';
      case 'E':
        return 'E';
      case 'J':
        return 'J';
      case 'G':
        return 'G';
      default:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargar(_searchCtrl.text),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final creado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => FormClienteScreen(user: widget.user),
            ),
          );
          if (creado == true) _cargar(_searchCtrl.text);
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Buscador ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _cargar,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, cédula, correo...',
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

          // ── Filtros por tipo ─────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filtrosTipo.map((f) {
                final sel = _tipcli == f['valor'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _tipcli = f['valor']!);
                      _cargar(_searchCtrl.text);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryBg : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          color:
                              sel ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
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

          // Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_clientes.length} clientes',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // ── Lista ────────────────────────────────────────
          Expanded(
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
                            Text(_errorMsg,
                                style: const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _cargar,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _clientes.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    color: AppColors.textHint, size: 52),
                                SizedBox(height: 12),
                                Text(
                                  'No se encontraron clientes',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _clientes.length,
                            itemBuilder: (_, i) {
                              final c = _clientes[i];
                              final clienIdeInt =
                                  int.tryParse(c['clien_ide'].toString()) ?? 0;
                              final tipo = c['clien_tipcli']?.toString() ?? 'V';
                              final nombre = '${c['clien_nombre1'] ?? ''} '
                                  '${c['clien_apelli1'] ?? ''}';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Stack(
                                  children: [
                                    // ── Área principal ────
                                    Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () async {
                                          if (clienIdeInt == 0) return;
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DetalleClienteScreen(
                                                user: widget.user,
                                                clienIde: clienIdeInt,
                                              ),
                                            ),
                                          );
                                          _cargar(_searchCtrl.text);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              // Avatar tipo
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: _colorTipo(tipo)
                                                      .withAlpha(30),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    _labelTipo(tipo),
                                                    style: TextStyle(
                                                      color: _colorTipo(tipo),
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                        color: AppColors
                                                            .textPrimary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '$tipo-${c['clien_numiden'] ?? '-'}',
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors.textHint,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    if ((c['clien_telmovi'] ??
                                                            '')
                                                        .isNotEmpty)
                                                      Text(
                                                        c['clien_telmovi']
                                                            .toString(),
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),

                                              // Espacio botones
                                              const SizedBox(width: 72),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // ── Botones ───────────
                                    Positioned(
                                      top: 0,
                                      bottom: 0,
                                      right: 0,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Editar
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () async {
                                                if (clienIdeInt == 0) return;
                                                final editado =
                                                    await Navigator.push<bool>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        FormClienteScreen(
                                                      user: widget.user,
                                                      clienIde: clienIdeInt,
                                                    ),
                                                  ),
                                                );
                                                if (editado == true) {
                                                  _cargar(_searchCtrl.text);
                                                }
                                              },
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                    Icons.edit_outlined,
                                                    color: AppColors.info,
                                                    size: 20),
                                              ),
                                            ),
                                          ),

                                          // Eliminar
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () =>
                                                  _confirmarEliminar(c),
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                    Icons.delete_outline,
                                                    color: AppColors.error,
                                                    size: 20),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
