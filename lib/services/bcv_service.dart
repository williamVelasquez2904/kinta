import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BcvService {
  // `api.bcv.org.ve` no siempre resuelve. Usar dominio principal (`bcv.org.ve`).
  static const String _baseUrl = 'https://bcv.org.ve';
  static const String _prefTasa = 'bcv_tasa';
  static const String _prefFecha = 'bcv_tasa_fecha';
  static const String _prefUrl = 'bcv_tasa_url';
  static const String _prefProxyUrl = 'bcv_tasa_proxy_url';
  static const String _prefRaw = 'bcv_tasa_raw';
  static const String _prefError = 'bcv_tasa_error';

  Future<Map<String, dynamic>> actualizarTasaDiaria({DateTime? fecha}) async {
    try {
      final now = fecha ?? DateTime.now();
      final fechaStr = _formatFecha(now);
      final fechaAlt = _formatFechaAlt(now);
      final paths = [
        '/indicadores/tipo_de_cambio',
        '/tipo_de_cambio',
        '/tipo_de_cambio/v2',
        '/tipo_cambio',
        '/tipo_cambio/v2',
      ];
      final queryParams = [
        '',
        '?fecha=$fechaStr',
        '?fecha=$fechaAlt',
      ];
      final endpoints = <String>[];
      for (final path in paths) {
        for (final query in queryParams) {
          endpoints.add('$_baseUrl$path$query');
        }
      }

      for (final url in endpoints) {
        final result = await _consultarEndpoint(url);
        if (result['success'] == true) {
          return result;
        }
      }

      return {
        'success': false,
        'message': 'No se encontró una respuesta válida de BCV',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener tasa BCV: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _consultarEndpoint(String url) async {
    http.Response? response;
    String proxyUrl = '';
    String errorMessage = '';
    try {
      response = await _enviarSolicitud(url);
    } catch (e) {
      errorMessage = e.toString();
      if (kIsWeb) {
        final proxyPrefixes = [
          'https://api.allorigins.win/raw?url=',
          'https://api.codetabs.com/v1/proxy?quest=',
          'https://thingproxy.freeboard.io/fetch/',
        ];
        final proxyResult = await _tryProxies(url, proxyPrefixes);
        response = proxyResult['response'] as http.Response?;
        proxyUrl = proxyResult['proxyUrl'] as String;
        if (response == null) {
          await _guardarDebug(url, '', errorMessage, proxyUrl);
          return {
            'success': false,
            'message': 'Error de conexión BCV proxy: $errorMessage',
            'raw': '',
            'url': url,
            'proxy': proxyUrl,
          };
        }
      } else {
        await _guardarDebug(url, '', errorMessage, '');
        return {
          'success': false,
          'message': 'Error de conexión BCV: $errorMessage',
          'raw': '',
          'url': url,
          'proxy': '',
        };
      }
    }

    if (response == null) {
      await _guardarDebug(url, '', 'No se obtuvo respuesta', proxyUrl);
      return {
        'success': false,
        'message': 'No se obtuvo respuesta BCV',
        'raw': '',
        'url': url,
        'proxy': proxyUrl,
      };
    }

    if (response.statusCode != 200 && kIsWeb && proxyUrl.isEmpty) {
      final proxyPrefixes = [
        'https://api.allorigins.win/raw?url=',
        'https://api.codetabs.com/v1/proxy?quest=',
        'https://thingproxy.freeboard.io/fetch/',
      ];
      final proxyResult = await _tryProxies(url, proxyPrefixes);
      response = proxyResult['response'] as http.Response?;
      proxyUrl = proxyResult['proxyUrl'] as String;
    }

    if (response == null) {
      await _guardarDebug(url, '', 'No se obtuvo respuesta', proxyUrl);
      return {
        'success': false,
        'message': 'No se obtuvo respuesta BCV',
        'raw': '',
        'url': url,
        'proxy': proxyUrl,
      };
    }

    if (response.statusCode != 200) {
      await _guardarDebug(
          url, response.body, 'HTTP ${response.statusCode}', proxyUrl);
      return {
        'success': false,
        'message': 'HTTP ${response.statusCode}',
        'raw': response.body,
        'url': url,
        'proxy': proxyUrl,
      };
    }

    final data = jsonDecode(response.body);
    final tasa = _extraerTasa(data);
    if (tasa == null) {
      await _guardarDebug(
          url, response.body, 'No se pudo parsear la tasa BCV', proxyUrl);
      return {
        'success': false,
        'message': 'No se pudo parsear la tasa BCV',
        'raw': data,
        'url': url,
        'proxy': proxyUrl,
      };
    }

    final fecha = _extraerFecha(data) ?? _formatFecha(DateTime.now());
    await _guardarTasa(tasa, fecha);
    await _guardarDebug(url, response.body, '', proxyUrl);
    return {
      'success': true,
      'tasa': tasa,
      'fecha': fecha,
      'raw': data,
      'url': url,
      'proxy': proxyUrl,
    };
  }

  Future<Map<String, dynamic>> obtenerTasaGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'tasa': prefs.getDouble(_prefTasa),
      'fecha': prefs.getString(_prefFecha) ?? '',
      'url': prefs.getString(_prefUrl) ?? '',
      'proxy': prefs.getString(_prefProxyUrl) ?? '',
      'raw': prefs.getString(_prefRaw) ?? '',
      'error': prefs.getString(_prefError) ?? '',
    };
  }

  Future<void> _guardarTasa(double tasa, String fecha) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefTasa, tasa);
    await prefs.setString(_prefFecha, fecha);
  }

  Future<void> _guardarDebug(
      String url, String raw, String error, String proxyUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefUrl, url);
    await prefs.setString(_prefProxyUrl, proxyUrl);
    await prefs.setString(
        _prefRaw, raw.length > 1200 ? '${raw.substring(0, 1200)}...' : raw);
    await prefs.setString(_prefError, error);
  }

  Future<http.Response> _enviarSolicitud(String url) async {
    final uri = Uri.parse(url);
    return await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 12));
  }

  Future<Map<String, dynamic>> _tryProxies(
      String url, List<String> proxyPrefixes) async {
    for (final prefix in proxyPrefixes) {
      final proxyUrl = '$prefix${Uri.encodeComponent(url)}';
      try {
        final response = await http
            .get(Uri.parse(proxyUrl), headers: _headers())
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) {
          return {'response': response, 'proxyUrl': proxyUrl};
        }
        await _guardarDebug(
            url, response.body, 'Proxy HTTP ${response.statusCode}', proxyUrl);
      } catch (e) {
        await _guardarDebug(url, '', e.toString(), proxyUrl);
      }
    }

    return {'response': null, 'proxyUrl': ''};
  }

  double? _extraerTasa(dynamic json) {
    if (json == null) return null;
    if (json is num) return json.toDouble();
    if (json is String) {
      final valor = json.trim().replaceAll(' ', '').replaceAll('\u00A0', '');
      final normalized = valor.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(normalized);
    }
    if (json is Map<String, dynamic>) {
      final keys = json.keys.map((e) => e.toString().toLowerCase()).toList();
      for (final key in keys) {
        final value = json[key];
        if (key.contains('tasa') ||
            key.contains('valor') ||
            key.contains('precio') ||
            key.contains('cierre') ||
            key.contains('ultimo')) {
          final tasa = _extraerTasa(value);
          if (tasa != null) return tasa;
        }
      }
      for (final value in json.values) {
        final tasa = _extraerTasa(value);
        if (tasa != null) return tasa;
      }
    }
    if (json is List) {
      for (final item in json) {
        final tasa = _extraerTasa(item);
        if (tasa != null) return tasa;
      }
    }
    return null;
  }

  String? _extraerFecha(dynamic json) {
    if (json == null) return null;
    if (json is String) {
      return _parseFecha(json);
    }
    if (json is Map<String, dynamic>) {
      for (final entry in json.entries) {
        final key = entry.key.toLowerCase();
        if (key.contains('fecha') || key.contains('date')) {
          final fecha = _extraerFecha(entry.value);
          if (fecha != null) return fecha;
        }
      }
      for (final value in json.values) {
        final fecha = _extraerFecha(value);
        if (fecha != null) return fecha;
      }
    }
    if (json is List) {
      for (final item in json) {
        final fecha = _extraerFecha(item);
        if (fecha != null) return fecha;
      }
    }
    return null;
  }

  String _formatFecha(DateTime fecha) {
    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatFechaAlt(DateTime fecha) {
    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    return '$day-$month-$year';
  }

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0',
      };

  String? _parseFecha(String texto) {
    final plain = texto.trim();
    final regex = RegExp(r'^(\d{4})[-/](\d{2})[-/](\d{2})');
    final match = regex.firstMatch(plain);
    if (match != null) {
      return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
    }
    return null;
  }
}
