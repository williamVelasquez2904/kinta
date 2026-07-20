import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import 'ventas_cliente_screen.dart';
import '../utils/app_config.dart';

class MisClientesScreen extends StatefulWidget {
  final UserModel user;
  const MisClientesScreen({super.key, required this.user});

  @override
  State<MisClientesScreen> createState() => _MisClientesScreenState();
}

class _MisClientesScreenState extends State<MisClientesScreen> {
  bool _isLoading = true;
  String _errorMsg = '';
  List _clientes = [];
  double _totalGeneral = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.api('api_mis_clientes.php')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'usua_numiden': widget.user.numiden}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _clientes = data['clientes'];
            _totalGeneral =
                double.tryParse(data['total_general'].toString()) ?? 0;
          });
        } else {
          setState(() => _errorMsg = data['message']);
        }
      } else {
        setState(() => _errorMsg = 'Error del servidor ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error de conexión: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List get _clientesFiltrados {
    if (_searchQuery.isEmpty) return _clientes;
    return _clientes.where((c) {
      final nombre = (c['clien_nombre1'] ?? '').toString().toLowerCase();
      return nombre.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarClientes,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Total general ──────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Saldo Deudor',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_clientesFiltrados.length} clientes',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  FormatoNumero.monedaConSimbolo(_totalGeneral),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Buscador ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Encabezado lista ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_clientesFiltrados.length} clientes',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Toca para ver ventas',
                  style: TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Lista clientes ─────────────────────────────
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
                                color: AppColors.error, size: 52),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _errorMsg,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _cargarClientes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _clientesFiltrados.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    color: AppColors.textHint, size: 52),
                                SizedBox(height: 12),
                                Text(
                                  'No se encontraron clientes',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _clientesFiltrados.length,
                            itemBuilder: (context, index) {
                              final c = _clientesFiltrados[index];
                              final saldo = double.tryParse(
                                      c['total_saldo'].toString()) ??
                                  0;
                              final nombre =
                                  c['clien_nombre1']?.toString() ?? '?';
                              final inicial = nombre.isNotEmpty
                                  ? nombre[0].toUpperCase()
                                  : '?';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.misClientesBg,
                                    child: Text(
                                      inicial,
                                      style: const TextStyle(
                                        color: AppColors.misClientes,
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
                                    'ID: ${c['clien_ide']}',
                                    style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 11),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        FormatoNumero.monedaConSimbolo(saldo),
                                        style: TextStyle(
                                          color: saldo > 0
                                              ? AppColors.error
                                              : AppColors.success,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textHint,
                                        size: 20,
                                      ),
                                    ],
                                  ),

                                  // ── Navegar a Ventas del cliente ──
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VentasClienteScreen(
                                          user: widget.user,
                                          clienteIde: c['clien_ide'],
                                          clienteNombre: nombre,
                                          saldoCliente: saldo,
                                        ),
                                      ),
                                    );
                                    // Refrescar al volver
                                    _cargarClientes();
                                  },
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
