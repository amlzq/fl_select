import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// One chat turn sent to the model.
typedef LlmTurn = ({String role, String content});

/// Streams a model reply as text chunks.
abstract interface class LlmClient {
  Stream<String> stream({
    required String systemPrompt,
    required List<LlmTurn> history,
  });
}

/// Talks to any OpenAI-compatible `/chat/completions` endpoint (OpenAI,
/// DeepSeek, Moonshot, Qwen, ...), reading the server-sent-event stream.
class OpenAiCompatibleClient implements LlmClient {
  OpenAiCompatibleClient({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiKey;
  final String baseUrl;
  final String model;
  final http.Client _http;

  @override
  Stream<String> stream({
    required String systemPrompt,
    required List<LlmTurn> history,
  }) async* {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final request = http.Request('POST', Uri.parse('$base/chat/completions'))
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        'model': model,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          for (final turn in history)
            {'role': turn.role, 'content': turn.content},
        ],
      });

    final response = await _http.send(request);
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw http.ClientException(
        'LLM request failed (${response.statusCode}): $body',
        request.url,
      );
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data.isEmpty) continue;
      if (data == '[DONE]') break;
      final choices = (jsonDecode(data) as Map<String, Object?>)['choices'];
      if (choices is! List || choices.isEmpty) continue;
      final delta = (choices.first as Map<String, Object?>)['delta'];
      final content = delta is Map<String, Object?> ? delta['content'] : null;
      if (content is String && content.isNotEmpty) yield content;
    }
  }
}
