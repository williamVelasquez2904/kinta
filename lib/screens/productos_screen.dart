import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/producto_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import '../utils/imagen_producto.dart';
import 'detalle_producto_screen.dart';
import 'form_producto_screen.dart';

class ProductosScreen extends StatefulWidget {
  final UserModel user;
  const ProductosScreen({super.key, required this.user});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _service = ProductoService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  String _errorMsg = '';
  List _productos = [];
  bool _soloStock = false;

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
        busqueda: busqueda,
        soloStock: _soloStock,
      );
      if (result['success'] == true) {
        setState(() => _productos = result['productos']);
      } else {
        setState(() => _errorMsg = result['message'] ?? 'Error');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error de conexión: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _confirmarEliminar(Map producto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content:
            Text('¿Estás seguro de eliminar "${producto['produc_descrip']}"?'),
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

    if (confirm == true) {
      final productoIdeInt =
          int.tryParse(producto['produc_ide'].toString()) ?? 0;
      final result = await _service.eliminar(
        usuaIde: widget.user.usuaIde,
        productoIde: productoIdeInt,
      );
      if (result['success'] == true) {
        _mostrarSnack('Producto eliminado', AppColors.success);
        _cargar(_searchCtrl.text);
      } else {
        _mostrarSnack(result['message'] ?? 'Error', AppColors.error);
      }
    }
  }

  void _mostrarSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: Icon(
              _soloStock ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _soloStock ? AppColors.primary : AppColors.textSecondary,
            ),
            tooltip: 'Solo con stock',
            onPressed: () {
              setState(() => _soloStock = !_soloStock);
              _cargar(_searchCtrl.text);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargar(_searchCtrl.text),
          ),
        ],
      ),
      floatingActionButton: widget.user.esAdministrador
          ? FloatingActionButton(
              onPressed: () async {
                final creado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormProductoScreen(user: widget.user),
                  ),
                );
                if (creado == true) _cargar(_searchCtrl.text);
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          // ── Buscador ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => _cargar(v),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
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

          // ── Contador ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_productos.length} productos',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                if (_soloStock)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Solo con stock',
                      style: TextStyle(color: AppColors.primary, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ── Lista ─────────────────────────────────────────
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
                    : _productos.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    color: AppColors.textHint, size: 52),
                                SizedBox(height: 12),
                                Text('No se encontraron productos',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _productos.length,
                            itemBuilder: (context, index) {
                              final p = _productos[index];

                              final productoIdeInt =
                                  int.tryParse(p['produc_ide'].toString()) ?? 0;
                              final existen = double.tryParse(
                                      p['produc_existen'].toString()) ??
                                  0;
                              final precio1 = double.tryParse(
                                      p['produc_precio1'].toString()) ??
                                  0;
                              final sinStock = existen <= 0;
                              final stockMin = double.tryParse(
                                      p['produc_stock'].toString()) ??
                                  0;
                              final bajStock =
                                  existen > 0 && existen <= stockMin;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sinStock
                                        ? AppColors.error.withOpacity(0.3)
                                        : bajStock
                                            ? AppColors.warning.withOpacity(0.3)
                                            : AppColors.border,
                                  ),
                                ),

                                // ── Usamos Stack en lugar de ListTile
                                // para evitar el conflicto táctil ──────
                                child: Stack(
                                  children: [
                                    // Área principal (toca → detalle)
                                    Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () async {
                                          if (productoIdeInt == 0) return;
                                          final editado =
                                              await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DetalleProductoScreen(
                                                user: widget.user,
                                                productoIde: productoIdeInt,
                                              ),
                                            ),
                                          );
                                          if (editado == true) {
                                            _cargar(_searchCtrl.text);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              // Foto o ícono
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: ImagenProducto.widget(
                                                  p['produc_foto']?.toString(),
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  placeholder: _iconoProducto(),
                                                  errorWidget: _iconoProducto(),
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
                                                      p['produc_descrip'] ?? '',
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .textPrimary,
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
                                                        fontSize: 11,
                                                      ),
                                                    ),
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
                                                  ],
                                                ),
                                              ),

                                              // Espacio para los botones de admin
                                              if (widget.user.esAdministrador)
                                                const SizedBox(width: 72),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Stock (esquina derecha arriba)
                                    Positioned(
                                      top: 8,
                                      right:
                                          widget.user.esAdministrador ? 80 : 8,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            sinStock
                                                ? 'Sin stock'
                                                : bajStock
                                                    ? 'Stock bajo'
                                                    : 'En stock',
                                            style: TextStyle(
                                              color: sinStock
                                                  ? AppColors.error
                                                  : bajStock
                                                      ? AppColors.warning
                                                      : AppColors.success,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            existen % 1 == 0
                                                ? existen.toStringAsFixed(0)
                                                : existen.toStringAsFixed(2),
                                            style: TextStyle(
                                              color: sinStock
                                                  ? AppColors.error
                                                  : AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Botones admin (columna derecha)
                                    // Completamente separados del InkWell
                                    if (widget.user.esAdministrador)
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        right: 0,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Botón EDITAR
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                onTap: () async {
                                                  if (productoIdeInt == 0)
                                                    return;
                                                  final editado =
                                                      await Navigator.push<
                                                          bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          FormProductoScreen(
                                                        user: widget.user,
                                                        productoIde:
                                                            productoIdeInt,
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
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Botón ELIMINAR
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                onTap: () =>
                                                    _confirmarEliminar(p),
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  alignment: Alignment.center,
                                                  child: const Icon(
                                                    Icons.delete_outline,
                                                    color: AppColors.error,
                                                    size: 20,
                                                  ),
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

  Widget _iconoProducto() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.inventory_2_outlined,
          color: AppColors.primary,
          size: 24,
        ),
      );
}
