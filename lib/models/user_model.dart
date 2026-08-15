class UserModel {
  final int usuaIde;
  final String nombre;
  final String apellido;
  final String login;
  final String numiden;
  final int tius;
  final String tiusDescrip;

  UserModel({
    required this.usuaIde,
    required this.nombre,
    required this.apellido,
    required this.login,
    required this.numiden,
    required this.tius,
    this.tiusDescrip = '',
  });

  String get nombreCompleto => '$nombre $apellido';

  // Administrador del sistema o de tienda
  bool get esAdministrador => tius == 1 || tius == 3;

  // Acceso al reporte de inventario
  bool get accesoInventario => esAdministrador;

  // Descripción legible del tipo de usuario. Usa el valor recibido del API
  // si existe; sino se genera una descripción por `tius`.
  String get tipoUsuarioDescripcion {
    if (tiusDescrip.isNotEmpty) return tiusDescrip;
    switch (tius) {
      case 1:
        return 'ADMIN SISTEMA';
      case 2:
        return 'ASISTENTE';
      case 3:
        return 'ADMIN TIENDA';
      case 4:
        return 'VENDEDOR';
      case 5:
        return 'VENDEDOR DETAL';
      default:
        return 'USUARIO';
    }
  }

  // Acceso al módulo Ventas: Admin Tienda, Vendedor o Vendedor Detal
  bool get accesoVentas =>
      tius == 3 || tius == 4 || tius == 5 || tius == 1 || tius == 2;

  factory UserModel.fromJson(Map<String, dynamic> json, String login) {
    final tiusValue = json['tius'] ?? json['usua_tius'] ?? json['user_tius'];
    return UserModel(
      usuaIde: int.tryParse(
            json['usua_ide']?.toString() ?? json['usuaide']?.toString() ?? '0',
          ) ??
          0,
      nombre: json['nombre'] ?? json['usua_nombre'] ?? '',
      apellido: json['apellido'] ?? json['usua_apelli'] ?? '',
      login: login,
      numiden:
          json['numiden']?.toString() ?? json['usua_numiden']?.toString() ?? '',
      tius: int.tryParse(tiusValue?.toString() ?? '') ?? 0,
      tiusDescrip: json['tius_descrip'] ??
          json['tius_descripc'] ??
          json['tius_descripcion'] ??
          '',
    );
  }
}
