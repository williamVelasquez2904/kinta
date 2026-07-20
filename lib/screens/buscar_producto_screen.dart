import 'package:flutter/material.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import '../models/carrito_item.dart';

class BuscarProductoScreen extends StatefulWidget {
  const BuscarProductoScreen({super.key});

  @override
  State<BuscarProductoScreen> createState() => _BuscarProductoScreenState();
}

class _BuscarProductoScreenState extends State<BuscarProductoScreen> {
  final _ventaService = VentaService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String _errorMsg = '';
  List _productos = [];

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

    final result = await _ventaService.buscarProductos(texto);

    if (result['success'] == true) {
      setState(() => _productos = result['productos']);
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Error desconocido');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
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
                hintText: 'Buscar por nombre o código...',
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
                    : _productos.isEmpty
                        ? const Center(
                            child: Text('No se encontraron productos',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _productos.length,
                            itemBuilder: (context, index) {
                              final p = _productos[index];
                              final existencia = double.tryParse(
                                      p['produc_existen'].toString()) ??
                                  0;
                              final precio1 = double.tryParse(
                                      p['produc_precio1'].toString()) ??
                                  0;
                              final precioUsd = double.tryParse(
                                      p['produc_preciodolar'].toString()) ??
                                  0;
                              final sinStock = existencia <= 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sinStock
                                        ? AppColors.error.withOpacity(0.3)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Opacity(
                                  opacity: sinStock ? 0.5 : 1,
                                  child: ListTile(
                                    title: Text(
                                      p['produc_descrip'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Código: ${p['produc_codigo'] ?? '-'}',
                                          style: const TextStyle(
                                              color: AppColors.textHint,
                                              fontSize: 11),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              FormatoNumero.monedaConSimbolo(
                                                  precio1),
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'USD ${precioUsd.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  color: AppColors.textHint,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          sinStock ? 'Sin stock' : 'Stock',
                                          style: TextStyle(
                                            color: sinStock
                                                ? AppColors.error
                                                : AppColors.success,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          existencia.toStringAsFixed(0),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: sinStock
                                        ? null
                                        : () => Navigator.pop(
                                            context, CarritoItem.fromJson(p)),
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
