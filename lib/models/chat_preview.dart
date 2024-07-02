class ChatPreview {
  final String chatId;
  final String name;
  final String lastMessage;
  final String timestamp;
  final String profilePicture;

  ChatPreview(
      {required this.chatId,
      required this.name,
      required this.lastMessage,
      required this.timestamp,
      required this.profilePicture});

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    return ChatPreview(
      chatId: json['chatId'],
      name: json['name'],
      lastMessage: json['lastMessage'],
      timestamp: json['timestamp'],
      profilePicture: json['profilePicture'],
    );
  }
}
