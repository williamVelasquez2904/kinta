import 'package:flutter/material.dart';
import '../services/venta_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import '../utils/imagen_producto.dart';
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

  // ── Diálogo para confirmar cantidad ─────────────────────
  Future<void> _seleccionarCantidad(BuildContext context, Map p) async {
    final existencia = double.tryParse(p['produc_existen'].toString()) ?? 0;
    final cantidadCtrl = TextEditingController(text: '1');

    final cantidad = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            // Miniatura en el diálogo
            _ImagenProducto(url: p['produc_foto']?.toString() ?? '', size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                p['produc_descrip'] ?? '',
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock disponible: ${existencia % 1 == 0 ? existencia.toStringAsFixed(0) : existencia.toStringAsFixed(2)}',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cantidadCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixIcon: Icon(Icons.numbers),
                helperText: 'Puedes ingresar decimales (ej: 1.5)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final v =
                  double.tryParse(cantidadCtrl.text.replaceAll(',', '.')) ?? 1;
              if (v <= 0) return;
              if (v > existencia) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Máximo disponible: $existencia'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(context, v);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (cantidad != null && mounted) {
      final item = CarritoItem.fromJson(p);
      item.cantidad = cantidad;
      Navigator.pop(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
      ),
      body: Column(
        children: [
          // ── Buscador ──────────────────────────────────
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

          // ── Lista ─────────────────────────────────────
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
                            child: Text(
                              'No se encontraron productos',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
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
                              final fotoUrl =
                                  p['produc_foto']?.toString() ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sinStock
                                        ? AppColors.error.withAlpha(60)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Opacity(
                                  opacity: sinStock ? 0.5 : 1,
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: sinStock
                                          ? null
                                          : () =>
                                              _seleccionarCantidad(context, p),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // ── Imagen ───
                                            _ImagenProducto(
                                                url: fotoUrl, size: 58),

                                            const SizedBox(width: 12),

                                            // ── Info ─────
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p['produc_descrip'] ?? '',
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Cód: ${p['produc_codigo'] ?? '-'}',
                                                    style: const TextStyle(
                                                        color:
                                                            AppColors.textHint,
                                                        fontSize: 10),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        FormatoNumero
                                                            .monedaConSimbolo(
                                                                precio1),
                                                        style: const TextStyle(
                                                          color:
                                                              AppColors.primary,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'USD ${precioUsd.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                            color: AppColors
                                                                .textHint,
                                                            fontSize: 10),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // ── Stock ────
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  sinStock
                                                      ? 'Sin stock'
                                                      : 'Stock',
                                                  style: TextStyle(
                                                    color: sinStock
                                                        ? AppColors.error
                                                        : AppColors.success,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  existencia % 1 == 0
                                                      ? existencia
                                                          .toStringAsFixed(0)
                                                      : existencia
                                                          .toStringAsFixed(2),
                                                  style: TextStyle(
                                                    color: sinStock
                                                        ? AppColors.error
                                                        : AppColors.textPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (!sinStock)
                                                  const Icon(
                                                    Icons.add_circle_outline,
                                                    color: AppColors.primary,
                                                    size: 18,
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
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

// ── Widget imagen de producto ──────────────────────────────
class _ImagenProducto extends StatelessWidget {
  final String url;
  final double size;
  const _ImagenProducto({
    required this.url,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ImagenProducto.widget(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: _placeholder(size),
          errorWidget: _placeholder(size),
        ),
      );
    }
    return _placeholder(size);
  }

  Widget _placeholder(double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textHint,
          size: 22,
        ),
      );
}
