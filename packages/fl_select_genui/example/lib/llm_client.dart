import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
class ChatCompletionsClient implements LlmClient {
  ChatCompletionsClient({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    http.Client? httpClient,
    this.logHttp = kDebugMode,
  }) : _http = httpClient ?? http.Client();

  final String apiKey;
  final String baseUrl;
  final String model;
  final http.Client _http;

  /// Prints the request, response status and streamed reply to the console.
  final bool logHttp;

  /// Longest slice printed in one call. The platform log (logcat, iOS
  /// console) truncates long lines, which cut off big prompts and replies.
  static const _logChunkSize = 800;

  // Distinct tags so request and response lines are easy to tell apart.
  static const _requestTag = 'LLM ▶ REQUEST';
  static const _responseTag = 'LLM ◀ RESPONSE';

  void _log(String tag, String message) {
    if (!logHttp) return;
    // Split on line breaks first so slices stay readable, then cut any line
    // longer than the limit.
    final slices = <String>[];
    for (final line in message.split('\n')) {
      if (line.length <= _logChunkSize) {
        slices.add(line);
        continue;
      }
      for (var i = 0; i < line.length; i += _logChunkSize) {
        final end = i + _logChunkSize;
        slices.add(line.substring(i, end > line.length ? line.length : end));
      }
    }
    // Pack consecutive slices into one print per chunk to limit the number of
    // calls, and tag continuations so the output can be stitched back.
    final buffer = StringBuffer();
    var part = 0;
    void flush() {
      if (buffer.isEmpty) return;
      debugPrint('[$tag${part == 0 ? '' : ' #${part + 1}'}] $buffer');
      buffer.clear();
      part++;
    }

    for (final slice in slices) {
      if (buffer.isNotEmpty &&
          buffer.length + slice.length + 1 > _logChunkSize) {
        flush();
      }
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(slice);
    }
    flush();
  }

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

    // The Authorization header is deliberately left out of the log.
    _log(_requestTag, 'POST ${request.url}\n${_prettyJson(request.body)}');
    final stopwatch = Stopwatch()..start();
    final response = await _http.send(request);
    _log(
      _responseTag,
      'status ${response.statusCode} (headers in '
      '${stopwatch.elapsedMilliseconds}ms)',
    );
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      _log(_responseTag, 'error body: $body');
      throw http.ClientException(
        'LLM request failed (${response.statusCode}): $body',
        request.url,
      );
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    final reply = StringBuffer();
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data.isEmpty) continue;
      if (data == '[DONE]') break;
      final choices = (jsonDecode(data) as Map<String, Object?>)['choices'];
      if (choices is! List || choices.isEmpty) continue;
      final delta = (choices.first as Map<String, Object?>)['delta'];
      final content = delta is Map<String, Object?> ? delta['content'] : null;
      if (content is String && content.isNotEmpty) {
        reply.write(content);
        yield content;
      }
    }
    _log(
      _responseTag,
      'stream done in ${stopwatch.elapsedMilliseconds}ms, '
      '${reply.length} chars\n$reply',
    );
  }

  static String _prettyJson(String raw) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } on FormatException {
      return raw;
    }
  }
}
