import 'package:flutter/material.dart';
import 'package:niccioli/services/chat_service.dart';
import 'package:niccioli/services/firebase_context_service.dart';
import 'package:niccioli/app/views/widgets/data_badge.dart';

const _bgDark = Color(0xFF0D1B2A);
const _bgCard = Color(0xFF162236);
const _accent = Color(0xFFF5A623);
const _textPrimary = Color(0xFFFFFFFF);
const _textHint = Color(0xFF6B8CAE);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatMessage> _history = [];

  String _streamBuffer = '';
  bool _loading = false;
  bool _contextLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final context = await FirebaseContextService.buildContext();
    final systemContent = context.isEmpty
        ? 'Você é um assistente útil e objetivo. Responda em português.'
        : 'Você é um assistente útil e objetivo do app Niccioli. Responda em português.\n'
            'Baseie suas respostas APENAS nos dados abaixo. Se a informação não estiver '
            'nos dados, diga que não tem essa informação disponível.\n\n$context';
    if (mounted) {
      setState(() {
        _history
          ..clear()
          ..add(ChatMessage(role: 'system', content: systemContent));
        _contextLoaded = true;
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading || !_contextLoaded) return;
    _controller.clear();

    setState(() {
      _history.add(ChatMessage(role: 'user', content: text));
      _streamBuffer = '';
      _loading = true;
    });

    _scrollToBottom();

    await ChatService.sendMessage(
      history: _history,
      onChunk: (chunk) {
        setState(() => _streamBuffer += chunk);
        _scrollToBottom();
      },
      onDone: () => setState(() {
        if (_streamBuffer.isNotEmpty) {
          _history.add(ChatMessage(role: 'assistant', content: _streamBuffer));
        }
        _streamBuffer = '';
        _loading = false;
      }),
      onError: (err) => setState(() {
        _streamBuffer = 'Erro: $err';
        _loading = false;
      }),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<ChatMessage> get _visibleMessages =>
      _history.where((m) => m.role != 'system').toList();

  @override
  Widget build(BuildContext context) {
    final messages = [
      ..._visibleMessages,
      if (_streamBuffer.isNotEmpty)
        ChatMessage(role: 'assistant', content: _streamBuffer),
    ];

    final isEmpty = messages.isEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _bgDark,

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _textPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  const CabecalhoData(),
                ],
              ),
            ),
            const SizedBox(height: 34),
            Expanded(
              child: isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: _textPrimary, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.memory_rounded,
                            color: _textPrimary,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ENERSYS',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Escreva sua pergunta abaixo',
                          style: TextStyle(color: _textHint, fontSize: 14),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: messages.length,
                      itemBuilder: (_, i) =>
                          _MessageBubble(message: messages[i]),
                    ),
            ),
            if (!_contextLoaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: _accent,
                  backgroundColor: _bgCard,
                ),
              ),
            if (_loading && _streamBuffer.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: _accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
            _InputBar(
              controller: _controller,
              loading: _loading || !_contextLoaded,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? _accent.withValues(alpha: 0.15) : _bgCard,
          border: Border.all(
            color: isUser ? _accent.withValues(alpha: 0.4) : Colors.white10,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? _accent : _textPrimary,
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 52),
      color: _bgDark,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'O que deseja perguntar?',
                  hintStyle: TextStyle(color: _textHint, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: loading ? null : onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
