import 'package:intl/intl.dart';

class FormatoNumero {
  // Formato: 457.732,22
  static final _formato = NumberFormat('#,##0.00', 'es_ES');

  static String moneda(double valor) {
    return _formato.format(valor);
  }

  static String monedaConSimbolo(double valor) {
    return '\$${_formato.format(valor)}';
  }

  static String decimal(double valor) {
    return _formato.format(valor);
  }
}
