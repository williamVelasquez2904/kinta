import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'app_config.dart';

class ImagenProducto {
  static String? _normalizarFoto(String? foto) {
    if (foto == null) return null;
    final valor = foto.trim();
    if (valor.isEmpty) return null;

    if (valor.startsWith('http') || valor.startsWith('//')) {
      return valor.startsWith('//') ? 'https:$valor' : valor;
    }

    if (_esDataUri(valor)) {
      return valor;
    }

    if (_esBase64(valor)) {
      return 'data:image/png;base64,$valor';
    }

    return Uri.parse(AppConfig.baseUrl).resolve(valor).toString();
  }

  static bool _esDataUri(String valor) => valor.startsWith('data:image');

  static bool _esBase64(String valor) {
    final limpio = valor.replaceAll(RegExp(r'\s+'), '');
    if (limpio.length < 80) return false;
    final regex = RegExp(r'^[A-Za-z0-9+/]+={0,2}\$');
    return regex.hasMatch(limpio);
  }

  static Uint8List? _bytesFromFoto(String foto) {
    try {
      if (_esDataUri(foto)) {
        final index = foto.indexOf(',');
        if (index < 0) return null;
        return base64Decode(foto.substring(index + 1));
      }
      if (_esBase64(foto)) {
        return base64Decode(foto.replaceAll(RegExp(r'\s+'), ''));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Widget widget(
    String? foto, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final imagen = foto?.trim();
    if (imagen == null || imagen.isEmpty) {
      return placeholder ?? _defaultPlaceholder(width, height);
    }

    final bytes = _bytesFromFoto(imagen);
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            errorWidget ?? placeholder ?? _defaultPlaceholder(width, height),
      );
    }

    final url = _normalizarFoto(imagen);
    if (url == null) {
      return placeholder ?? _defaultPlaceholder(width, height);
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          errorWidget ?? placeholder ?? _defaultPlaceholder(width, height),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        );
      },
    );
  }

  static Widget _defaultPlaceholder(double? width, double? height) => Container(
        width: width,
        height: height,
        color: const Color(0xFFEFEFEF),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      );
}
