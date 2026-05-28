class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? source;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.source,
  });
}
