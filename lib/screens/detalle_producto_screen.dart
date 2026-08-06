import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/producto_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato_numero.dart';
import '../utils/imagen_producto.dart';
import 'form_producto_screen.dart';

class DetalleProductoScreen extends StatefulWidget {
  final UserModel user;
  final int productoIde;

  const DetalleProductoScreen({
    super.key,
    required this.user,
    required this.productoIde,
  });

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  final _service = ProductoService();
  bool _isLoading = true;
  Map _producto = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service
          .detalle(widget.productoIde)
          .timeout(const Duration(seconds: 10));
      if (result['success'] == true) {
        setState(() => _producto = result['producto']);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_producto['produc_descrip'] ?? 'Producto'),
        actions: [
          if (widget.user.esAdministrador && _producto.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () async {
                final editado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormProductoScreen(
                      user: widget.user,
                      productoIde: widget.productoIde,
                    ),
                  ),
                );
                if (editado == true) {
                  await _cargar();
                  if (mounted) Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Foto ────────────────────────────────
                  if (_producto['produc_foto'] != null)
                    Container(
                      width: double.infinity,
                      height: 220,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: ImagenProducto.widget(
                            _producto['produc_foto']?.toString(),
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorWidget: const Center(
                              child: Icon(Icons.image_not_supported,
                                  color: AppColors.textHint, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Info general ─────────────────────────
                  _seccion('INFORMACIÓN GENERAL'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila('Código',
                        _producto['produc_codigo']?.toString() ?? '-'),
                    _fila('Descripción',
                        _producto['produc_descrip']?.toString() ?? '-'),
                    _fila(
                      'Tipo',
                      (int.tryParse(_producto['produc_servicio'].toString()) ??
                                  0) ==
                              1
                          ? 'Servicio'
                          : 'Producto',
                    ),
                    _fila(
                        'Color', _producto['produc_color']?.toString() ?? '-'),
                    _fila(
                        'Talla', _producto['produc_talla']?.toString() ?? '-'),
                  ]),

                  const SizedBox(height: 16),

                  // ── Clasificación ────────────────────────
                  _seccion('CLASIFICACIÓN'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(
                      'Departamento',
                      _producto['depart_descrip']?.toString() ?? '-',
                      color: AppColors.primary,
                      negrita: true,
                    ),
                    _fila(
                        'Marca', _producto['marca_descrip']?.toString() ?? '-'),
                    _fila('Modelo',
                        _producto['modelo_descrip']?.toString() ?? '-'),
                    _fila('Unidad',
                        _producto['unidmed_descrip']?.toString() ?? '-'),
                    _fila(
                      'Impuesto',
                      '${_producto['impuesto_porcent']?.toString() ?? '0'}%',
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Stock ────────────────────────────────
                  _seccion('STOCK'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(
                      'Existencia',
                      _producto['produc_existen']?.toString() ?? '0',
                      color: (double.tryParse(
                                      _producto['produc_existen'].toString()) ??
                                  0) >
                              0
                          ? AppColors.success
                          : AppColors.error,
                      negrita: true,
                    ),
                    _fila('Stock mínimo',
                        _producto['produc_stock']?.toString() ?? '0'),
                  ]),

                  const SizedBox(height: 16),

                  // ── Precios ──────────────────────────────
                  _seccion('PRECIOS'),
                  const SizedBox(height: 8),
                  _bloque([
                    _fila(
                      'Costo',
                      FormatoNumero.monedaConSimbolo(double.tryParse(
                              _producto['produc_costo'].toString()) ??
                          0),
                    ),
                    _fila(
                      'Precio 1',
                      FormatoNumero.monedaConSimbolo(double.tryParse(
                              _producto['produc_precio1'].toString()) ??
                          0),
                      color: AppColors.primary,
                      negrita: true,
                    ),
                    _fila(
                      'Precio 2',
                      FormatoNumero.monedaConSimbolo(double.tryParse(
                              _producto['produc_precio2'].toString()) ??
                          0),
                    ),
                    _fila(
                      'Precio 3',
                      FormatoNumero.monedaConSimbolo(double.tryParse(
                              _producto['produc_precio3'].toString()) ??
                          0),
                    ),
                    _fila(
                      'Precio 4',
                      FormatoNumero.monedaConSimbolo(double.tryParse(
                              _producto['produc_precio4'].toString()) ??
                          0),
                    ),
                    _fila(
                      'Precio USD',
                      '\$${(double.tryParse(_producto['produc_preciodolar'].toString()) ?? 0).toStringAsFixed(2)}',
                      color: AppColors.info,
                    ),
                  ]),

                  // ── Observaciones ────────────────────────
                  if ((_producto['produc_observa'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _seccion('OBSERVACIONES'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        _producto['produc_observa'].toString(),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ── Widgets auxiliares ───────────────────────────────────

  Widget _seccion(String titulo) => Text(
        titulo,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );

  Widget _bloque(List<Widget> hijos) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: hijos),
      );

  Widget _fila(
    String label,
    String valor, {
    Color color = AppColors.textPrimary,
    bool negrita = false,
  }) =>
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                Flexible(
                  child: Text(
                    valor,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 16),
        ],
      );
}
