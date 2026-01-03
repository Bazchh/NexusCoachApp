import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/session_models.dart';

class NexusApi {
  NexusApi(this.baseUrl, {http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<SessionStartResult> startSession({
    required String deviceId,
    required String locale,
    required String champion,
    required String lane,
    String? enemy,
  }) async {
    final payload = await _postJson('/session/start', {
      'device_id': deviceId,
      'locale': locale,
      'initial_context': {
        'champion': champion,
        'lane': lane,
        if (enemy != null && enemy.isNotEmpty) 'enemy': enemy,
      },
    });

    return SessionStartResult(
      sessionId: payload['session_id'] as String,
      state: (payload['state'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<TurnResult> sendTurn({
    required String sessionId,
    required String text,
    Map<String, dynamic>? clientStateHint,
  }) async {
    final payload = await _postJson('/turn', {
      'session_id': sessionId,
      'text': text,
      if (clientStateHint != null) 'client_state_hint': clientStateHint,
    });

    return TurnResult(
      replyText: payload['reply_text'] as String,
      updatedState: (payload['updated_state'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<void> endSession(String sessionId) async {
    await _postJson('/session/end', {
      'session_id': sessionId,
    });
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _parseEnvelope(response);
  }

  Map<String, dynamic> _parseEnvelope(http.Response response) {
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Resposta inválida do servidor.');
    }

    final ok = payload['ok'] == true;
    if (ok) {
      return (payload['data'] as Map<String, dynamic>?) ?? {};
    }

    final error = payload['error'] as Map<String, dynamic>?;
    final message = error?['user_message'] as String? ??
        'Não foi possível concluir a ação.';
    throw ApiException(message);
  }
}
