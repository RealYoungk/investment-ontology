import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../api_secret.dart';

/// Anthropic API 키와 모델. 키가 없으면 AI 추출만 막히고 나머지는 그대로 동작한다.
abstract final class AnthropicConfig {
  static const secret = ApiSecret(
    passwordName: 'anthropicApiKey',
    envName: 'ANTHROPIC_API_KEY',
  );

  /// 기본 모델. 환경변수 `ANTHROPIC_MODEL`로 바꿀 수 있다.
  static const defaultModel = 'claude-sonnet-5';

  static String? key(Session session) => secret.read(session);

  static String get model {
    final m = Platform.environment['ANTHROPIC_MODEL']?.trim();
    return m == null || m.isEmpty ? defaultModel : m;
  }
}

class AnthropicException implements Exception {
  AnthropicException(this.message);
  final String message;

  @override
  String toString() => 'AnthropicException: $message';
}

/// Messages API (https://docs.anthropic.com) — 글 하나를 보내고 글 하나를 받는다.
class AnthropicClient {
  AnthropicClient(this.apiKey, {required this.model, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  static const endpoint = 'https://api.anthropic.com/v1/messages';

  final String apiKey;
  final String model;
  final http.Client _http;

  Future<String> complete({
    required String system,
    required String user,
    int maxTokens = 4096,
  }) async {
    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse(endpoint),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': maxTokens,
              'system': system,
              'messages': [
                {'role': 'user', 'content': user},
              ],
            }),
          )
          .timeout(const Duration(minutes: 3));
    } catch (e) {
      throw AnthropicException('요청 실패: $e');
    }
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw AnthropicException('HTTP ${res.statusCode}: $body');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final content = (json['content'] as List?) ?? const [];
    return [
      for (final c in content.cast<Map<String, dynamic>>())
        if (c['type'] == 'text') c['text'] as String,
    ].join();
  }

  void close() => _http.close();
}
