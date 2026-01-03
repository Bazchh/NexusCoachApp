class HistoryEntry {
  const HistoryEntry(this.role, this.text);

  final String role;
  final String text;
}

class SessionStartResult {
  const SessionStartResult({required this.sessionId, required this.state});

  final String sessionId;
  final Map<String, dynamic> state;
}

class TurnResult {
  const TurnResult({required this.replyText, required this.updatedState});

  final String replyText;
  final Map<String, dynamic> updatedState;
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;
}
