import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';

class AsistenteScreen extends StatefulWidget {
  final UserModel user;
  const AsistenteScreen({super.key, required this.user});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final _mensajeCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatService = ChatService();

  List<Map<String, dynamic>> _mensajes = [];
  List<Map<String, String>> _historial = [];
  bool _isTyping = false;

  final List<String> _sugerencias = [
    '¿Cuántos clientes tengo?',
    '¿Cuál es mi saldo total?',
    '¿Cuáles son mis últimos pagos?',
    '¿Cómo reporto un pago?',
    '¿Quién tiene el mayor saldo?',
  ];

  @override
  void initState() {
    super.initState();
    _agregarMensajeSistema(
      '¡Hola ${widget.user.nombre}! Soy Kin, tu asistente virtual. '
      'Puedo ayudarte con información sobre tus clientes, saldos y pagos. '
      '¿En qué te puedo ayudar?',
    );
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _agregarMensajeSistema(String texto) {
    setState(() {
      _mensajes.add({
        'role': 'assistant',
        'texto': texto,
        'hora': _horaActual(),
      });
    });
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _enviarMensaje([String? textoFijo]) async {
    final texto = textoFijo ?? _mensajeCtrl.text.trim();
    if (texto.isEmpty || _isTyping) return;

    _mensajeCtrl.clear();

    setState(() {
      _mensajes.add({
        'role': 'user',
        'texto': texto,
        'hora': _horaActual(),
      });
      _isTyping = true;
    });

    _scrollAlFinal();

    // Actualizar historial para contexto
    _historial.add({'role': 'user', 'content': texto});

    final result = await _chatService.enviarMensaje(
      mensaje: texto,
      numiden: widget.user.numiden,
      historial: _historial.length > 1
          ? _historial.sublist(0, _historial.length - 1)
          : [],
    );

    if (result['success'] == true) {
      final respuesta = result['respuesta'] as String;
      _historial.add({'role': 'assistant', 'content': respuesta});
      setState(() {
        _mensajes.add({
          'role': 'assistant',
          'texto': respuesta,
          'hora': _horaActual(),
        });
        _isTyping = false;
      });
    } else {
      setState(() {
        _mensajes.add({
          'role': 'assistant',
          'texto': 'Lo siento, tuve un problema al procesar tu consulta. '
              'Por favor intenta de nuevo.',
          'hora': _horaActual(),
          'error': true,
        });
        _isTyping = false;
      });
    }

    _scrollAlFinal();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.eco,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kin',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    )),
                Text(
                  _isTyping ? 'Escribiendo...' : 'Asistente virtual',
                  style: TextStyle(
                    color: _isTyping ? AppColors.primary : AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpiar chat',
            onPressed: () {
              setState(() {
                _mensajes = [];
                _historial = [];
              });
              _agregarMensajeSistema(
                '¡Chat limpiado! ¿En qué te puedo ayudar?',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Lista de mensajes ──────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _mensajes.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Indicador de typing
                if (_isTyping && index == _mensajes.length) {
                  return _bubbleTyping();
                }

                final msg = _mensajes[index];
                final esUser = msg['role'] == 'user';
                return _bubble(
                  texto: msg['texto'],
                  hora: msg['hora'],
                  esUser: esUser,
                  error: msg['error'] ?? false,
                );
              },
            ),
          ),

          // ── Sugerencias (solo al inicio) ───────────────
          if (_mensajes.length <= 1)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _sugerencias.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _enviarMensaje(_sugerencias[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      _sugerencias[index],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ── Input ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeCtrl,
                    maxLines: null,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu pregunta...',
                      hintStyle: const TextStyle(
                          color: AppColors.textHint, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _enviarMensaje(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isTyping ? null : _enviarMensaje,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isTyping ? AppColors.textHint : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble({
    required String texto,
    required String hora,
    required bool esUser,
    bool error = false,
  }) {
    return Align(
      alignment: esUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: esUser
              ? AppColors.primary
              : error
                  ? AppColors.errorBg
                  : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(esUser ? 16 : 4),
            bottomRight: Radius.circular(esUser ? 4 : 16),
          ),
          border: esUser ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              texto,
              style: TextStyle(
                color: esUser
                    ? Colors.white
                    : error
                        ? AppColors.error
                        : AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hora,
              style: TextStyle(
                color:
                    esUser ? Colors.white.withOpacity(0.6) : AppColors.textHint,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubbleTyping() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 150),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
