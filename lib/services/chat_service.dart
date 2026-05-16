import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role;
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class ChatService {
  // Dispositivo físico na mesma rede Wi-Fi
  static const String _baseUrl = 'http://10.217.162.75:8000';
  static const String _model = 'llama-3.3-70b-versatile';

  static Future<void> sendMessage({
    required List<ChatMessage> history,
    required void Function(String chunk) onChunk,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/chat'))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'messages': history.map((m) => m.toJson()).toList(),
          'model': _model,
        });

      final response = await request.send();

      if (response.statusCode != 200) {
        onError('Erro ${response.statusCode}');
        return;
      }

      await for (final line in response.stream.transform(utf8.decoder)) {
        for (final part in line.split('\n')) {
          if (part.startsWith('data: ')) {
            final data = part.substring(6).trim();
            if (data == '[DONE]') {
              onDone();
              return;
            }
            try {
              final json = jsonDecode(data);
              onChunk(json['text'] as String);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      onError(e.toString());
    }
  }
}
