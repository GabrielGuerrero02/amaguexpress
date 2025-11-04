import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'bot',
      'text': 'Hola 👋 Soy Amagú, tu asistente virtual. ¿En qué puedo ayudarte?'
    }
  ];

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void initState() {
    super.initState();
    _scheduleScrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _controller.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': messageText});
      _isSending = true;
      _controller.clear();
      _focusNode.requestFocus();
    });
    _scheduleScrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://amaguexpress.com/api/gptamagu/message'), //
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': '123', // 🧪 puedes personalizar con el ID real
          'message': messageText,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Respuesta completa del backend: ${response.body}');
        final body = json.decode(response.body);

        if (body.containsKey('reply')) {
          setState(() {
            _messages.add({'sender': 'bot', 'text': body['reply']});
          });
          _scheduleScrollToBottom();
        } else {
          setState(() {
            _messages.add({
              'sender': 'bot',
              'text': '⚠️ La respuesta no contiene el campo "reply".'
            });
          });
          _scheduleScrollToBottom();
        }
      } else {
        print('❌ Código de estado: ${response.statusCode}');
        print('❌ Cuerpo de error: ${response.body}');
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text':
                'Lo siento, hubo un problema al responder. Código: ${response.statusCode}'
          });
        });
        _scheduleScrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Ocurrió un error de red. Intenta de nuevo más tarde.'
        });
      });
      _scheduleScrollToBottom();
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isUser ? Colors.orange.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message['text'],
          style: TextStyle(
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habla con Amagú'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu pregunta...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.orange,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
