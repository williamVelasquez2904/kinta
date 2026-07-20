import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/compra_service.dart';
import '../theme/app_theme.dart';

class ProveedoresScreen extends StatefulWidget {
  final UserModel user;
  const ProveedoresScreen({super.key, required this.user});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final _service = CompraService();
  final _searchCtrl = TextEditingController();

  bool _isLoading = true;
  List _proveedores = [];

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
    setState(() => _isLoading = true);
    try {
      final result = await _service.listarProveedores(
        usuaIde: widget.user.usuaIde,
        busqueda: busqueda,
      );
      if (result['success'] == true) {
        setState(() => _proveedores = result['proveedores'] ?? []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _mostrarFormulario({Map? proveedor}) async {
    final nombreCtrl =
        TextEditingController(text: proveedor?['prove_nombre'] ?? '');
    final rifCtrl = TextEditingController(text: proveedor?['prove_rif'] ?? '');
    final telefonoCtrl =
        TextEditingController(text: proveedor?['prove_telefono'] ?? '');
    final emailCtrl =
        TextEditingController(text: proveedor?['prove_email'] ?? '');
    final contactoCtrl =
        TextEditingController(text: proveedor?['prove_contacto'] ?? '');
    final direccionCtrl =
        TextEditingController(text: proveedor?['prove_direccion'] ?? '');

    final esEdicion = proveedor != null;
    bool guardando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _campo(nombreCtrl, 'Nombre *', Icons.business),
                const SizedBox(height: 10),
                _campo(rifCtrl, 'RIF', Icons.badge_outlined),
                const SizedBox(height: 10),
                _campo(telefonoCtrl, 'Teléfono', Icons.phone_outlined),
                const SizedBox(height: 10),
                _campo(emailCtrl, 'Email', Icons.email_outlined),
                const SizedBox(height: 10),
                _campo(contactoCtrl, 'Contacto', Icons.person_outline),
                const SizedBox(height: 10),
                _campo(direccionCtrl, 'Dirección', Icons.location_on_outlined),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: guardando
                        ? null
                        : () async {
                            if (nombreCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text('El nombre es requerido'),
                                backgroundColor: AppColors.error,
                              ));
                              return;
                            }
                            setModal(() => guardando = true);

                            Map<String, dynamic> result;
                            if (esEdicion) {
                              result = await _service.editarProveedor(
                                usuaIde: widget.user.usuaIde,
                                proveIde: int.tryParse(
                                        proveedor['prove_ide'].toString()) ??
                                    0,
                                nombre: nombreCtrl.text.trim(),
                                rif: rifCtrl.text.trim(),
                                telefono: telefonoCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                direccion: direccionCtrl.text.trim(),
                                contacto: contactoCtrl.text.trim(),
                              );
                            } else {
                              result = await _service.crearProveedor(
                                usuaIde: widget.user.usuaIde,
                                nombre: nombreCtrl.text.trim(),
                                rif: rifCtrl.text.trim(),
                                telefono: telefonoCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                direccion: direccionCtrl.text.trim(),
                                contacto: contactoCtrl.text.trim(),
                              );
                            }

                            setModal(() => guardando = false);

                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? ''),
                                  backgroundColor: result['success'] == true
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              );
                              if (result['success'] == true) _cargar();
                            }
                          },
                    icon: guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(esEdicion ? 'Actualizar' : 'Guardar Proveedor'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(Map p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text('¿Eliminar "${p['prove_nombre']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final result = await _service.eliminarProveedor(
        usuaIde: widget.user.usuaIde,
        proveIde: int.tryParse(p['prove_ide'].toString()) ?? 0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? ''),
          backgroundColor:
              result['success'] == true ? AppColors.success : AppColors.error,
        ));
        if (result['success'] == true) _cargar();
      }
    }
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icono) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icono, size: 18),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargar(_searchCtrl.text),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _cargar,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar proveedor...',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${_proveedores.length} proveedores',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _proveedores.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_outlined,
                                color: AppColors.textHint, size: 52),
                            SizedBox(height: 12),
                            Text('No hay proveedores registrados',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _proveedores.length,
                        itemBuilder: (ctx, i) {
                          final p = _proveedores[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.business_outlined,
                                    color: AppColors.primary, size: 22),
                              ),
                              title: Text(
                                p['prove_nombre'] ?? '',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((p['prove_rif'] ?? '').isNotEmpty)
                                    Text('RIF: ${p['prove_rif']}',
                                        style: const TextStyle(
                                            color: AppColors.textHint,
                                            fontSize: 11)),
                                  if ((p['prove_telefono'] ?? '').isNotEmpty)
                                    Text(p['prove_telefono'],
                                        style: const TextStyle(
                                            color: AppColors.textHint,
                                            fontSize: 11)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: AppColors.info, size: 20),
                                    onPressed: () =>
                                        _mostrarFormulario(proveedor: p),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppColors.error, size: 20),
                                    onPressed: () => _confirmarEliminar(p),
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
