import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';

class SeleccionarClienteScreen extends StatefulWidget {
  final UserModel user;
  const SeleccionarClienteScreen({super.key, required this.user});

  @override
  State<SeleccionarClienteScreen> createState() =>
      _SeleccionarClienteScreenState();
}

class _SeleccionarClienteScreenState extends State<SeleccionarClienteScreen> {
  final _ventaService = VentaService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String _errorMsg = '';
  List _clientes = [];

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

  Future<void> _buscar([String texto = '']) async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    final result = await _ventaService.buscarClientes(
      usuaIde: widget.user.usuaIde,
      busqueda: texto,
    );

    if (result['success'] == true) {
      setState(() => _clientes = result['clientes']);
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error desconocido');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Cliente'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _buscar();
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                _buscar(v);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMsg.isNotEmpty
                    ? Center(
                        child: Text(_errorMsg,
                            style: const TextStyle(color: AppColors.error)))
                    : _clientes.isEmpty
                        ? const Center(
                            child: Text('No se encontraron clientes',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _clientes.length,
                            itemBuilder: (context, index) {
                              final c = _clientes[index];
                              final nombre =
                                  c['clien_nombre1']?.toString() ?? '?';
                              final inicial = nombre.isNotEmpty
                                  ? nombre[0].toUpperCase()
                                  : '?';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryBg,
                                    child: Text(
                                      inicial,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    nombre,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'C.I/RIF: ${c['clien_numiden'] ?? '-'}',
                                    style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 11),
                                  ),
                                  trailing: const Icon(Icons.chevron_right,
                                      color: AppColors.textHint),
                                  onTap: () => Navigator.pop(context, c),
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
