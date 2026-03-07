class ConversationMessage {
  final String role;
  final String content;

  const ConversationMessage({required this.role, required this.content});

  Map<String, String> toMap() {
    return {'role': role, 'content': content};
  }
}
