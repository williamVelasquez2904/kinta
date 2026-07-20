class CarritoItem {
  final int productoIde;
  final String codigo;
  final String descripcion;
  final double existencia;
  final double precio1;
  final double precioDolar;
  final double costo;
  double cantidad;
  double descuento;

  CarritoItem({
    required this.productoIde,
    required this.codigo,
    required this.descripcion,
    required this.existencia,
    required this.precio1,
    required this.precioDolar,
    required this.costo,
    this.cantidad = 1,
    this.descuento = 0,
  });

  double precioSegun(int tipoPrecio) => tipoPrecio == 2 ? precioDolar : precio1;

  double subtotal(int tipoPrecio) {
    final precio = precioSegun(tipoPrecio);
    return (precio * cantidad) * (1 - descuento / 100);
  }

  factory CarritoItem.fromJson(Map json) {
    return CarritoItem(
      productoIde: int.tryParse(json['produc_ide'].toString()) ?? 0,
      codigo: json['produc_codigo']?.toString() ?? '',
      descripcion: json['produc_descrip']?.toString() ?? '',
      existencia: double.tryParse(json['produc_existen'].toString()) ?? 0,
      precio1: double.tryParse(json['produc_precio1'].toString()) ?? 0,
      precioDolar: double.tryParse(json['produc_preciodolar'].toString()) ?? 0,
      costo: double.tryParse(json['produc_costo']?.toString() ?? '0') ?? 0,
    );
  }
}
