import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:math_anchor/config/app_skin_config.dart';

class VivoChatMessage {
  final String role;
  final String content;

  VivoChatMessage({required this.role, required this.content});

  Map<String, String> toMap() => <String, String>{
        'role': role,
        'content': content,
      };
}

class VivoChatResponse {
  final String content;
  final String? reasoning;

  VivoChatResponse({required this.content, this.reasoning});
}

class VivoAiChatService {
  static const String _apiKeyEnv = 'VIVO_API_KEY';
  static const String _modelEnv = 'VIVO_MODEL_ID';
  static bool _dotenvLoaded = false;

  Future<void> _ensureEnvLoaded() async {
    if (_dotenvLoaded) return;
    await dotenv.load(fileName: '.env');
    _dotenvLoaded = true;
  }

  Future<VivoChatResponse> sendMessage(List<VivoChatMessage> messages, {String? modelId}) async {
    await _ensureEnvLoaded();

    final String apiKey = (dotenv.env[_apiKeyEnv] ?? '').trim();
    final String resolvedModel =
        (modelId != null && modelId.trim().isNotEmpty ? modelId : dotenv.env[_modelEnv])?.trim() ?? AppSkinConfig.vivoModelId;
    final String baseUrl = AppSkinConfig.vivoBaseUrl;

    if (apiKey.isEmpty) {
      throw Exception('Missing env config: VIVO_API_KEY');
    }

    final List<Map<String, String>> formattedMessages = messages
        .map((m) => m.toMap())
        .toList();

    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $apiKey',
    };

    final Map<String, dynamic> body = <String, dynamic>{
      'model': resolvedModel,
      'messages': formattedMessages,
      'temperature': 0.7,
      'max_tokens': 2048,
    };

    final http.Response response = await http
        .post(
          Uri.parse(baseUrl),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('请求超时，请重试'),
        );

    final String rawBody = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      debugPrint('Vivo API error: $rawBody');
      throw Exception('Vivo API error: $rawBody');
    }

    dynamic data;
    try {
      data = jsonDecode(rawBody);
    } catch (e) {
      debugPrint('Vivo API response invalid json: $e');
      throw Exception('Vivo API response invalid json');
    }

    return _extractResponse(data);
  }

  VivoChatResponse _extractResponse(dynamic data) {
    final dynamic message = data['choices']?[0]?['message'];
    final String content = (message?['content'] as String?)?.trim() ?? '';
    final String? reasoning =
        (message?['reasoning_content'] as String?)?.trim();

    if (content.isEmpty) {
      throw Exception('Vivo API returned empty content.');
    }

    return VivoChatResponse(content: content, reasoning: reasoning);
  }
}
