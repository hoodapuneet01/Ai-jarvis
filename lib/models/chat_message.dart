class ChatMessage {
  const ChatMessage(this.text, {required this.fromUser, this.unknownPhrase});

  final String text;
  final bool fromUser;

  /// Set on "I haven't been taught that" replies so the user can teach it.
  final String? unknownPhrase;
}
