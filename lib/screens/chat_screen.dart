import 'package:flutter/material.dart';
import 'dart:async';
import '../services/jarvis_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _sending = true;
    });
    _scrollDown();
    try {
      final reply = await JarvisService.sendMessage(text, _messages.sublist(0, _messages.length - 1));
      setState(() => _messages.add(ChatMessage(role: 'assistant', content: reply)));
    } catch (e) {
      setState(() => _messages.add(ChatMessage(role: 'assistant', content: 'Что-то пошло не так...')));
    } finally {
      setState(() => _sending = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080810),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFFAFA9EC), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Лея', style: TextStyle(fontSize: 16, color: Color(0xFFe0e0f0), fontWeight: FontWeight.w300)),
            Text(
              _sending ? 'печатает...' : 'здесь',
              style: TextStyle(
                fontSize: 11,
                color: _sending ? const Color(0xFF7F77DD) : const Color(0xFF3a3a5a),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text('Начни разговор', style: TextStyle(color: Color(0xFF2a2a4a), fontSize: 14)),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length) return _typingIndicator();
        final m = _messages[i];
        final isUser = m.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF1e1a3a) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: Border.all(
                color: isUser
                    ? const Color(0xFF3a3060)
                    : Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Text(m.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isUser ? const Color(0xFFc8c0f0) : const Color(0xFFd8d8f0),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
          ),
        ),
        child: const SizedBox(
          width: 36, height: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Dot(delay: 0),
              _Dot(delay: 150),
              _Dot(delay: 300),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF080810),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 14, color: Color(0xFFd0d0f0)),
                decoration: const InputDecoration(
                  hintText: 'Напиши...',
                  hintStyle: TextStyle(color: Color(0xFF3a3a5a)),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _send(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF7F77DD).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7F77DD).withValues(alpha: 0.5), width: 0.5),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFAFA9EC), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  Widget build(BuildContext context) {
    return _AnimatedDot(delay: delay);
  }
}

class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});
  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    // Запуск с задержкой по delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6, height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF7F77DD),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

