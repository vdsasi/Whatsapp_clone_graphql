import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:whatsapp_clone/models/chat_preview.dart';
import 'package:whatsapp_clone/models/shared_user_name.dart';

class ChatScreen extends StatefulWidget {
  final ChatPreview chat;

  const ChatScreen({super.key, required this.chat});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final String fetchMessagesQuery = """
    query GetMessages(\$name: String!, \$chatId: ID!) {
      getMessages(name: \$name, chatId: \$chatId) {
        text
        isMe
        timestamp
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name),
        actions: [
          IconButton(icon: Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: Icon(Icons.call), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<String?>(
        future: SharedPrefsName.getUserName(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final userName = snapshot.data ?? '';

          return Query(
            options: QueryOptions(
              document: gql(fetchMessagesQuery),
              variables: {
                "name": userName,
                "chatId": widget.chat.chatId,
              },
            ),
            builder: (QueryResult result,
                {VoidCallback? refetch, FetchMore? fetchMore}) {
              if (result.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (result.hasException) {
                return Center(
                    child: Text("Error: ${result.exception.toString()}"));
              }

              if (result.data == null || result.data!['getMessages'] == null) {
                return Center(child: Text("No messages found"));
              }

              List<ChatMessage> messages = (result.data!['getMessages'] as List)
                  .map((message) => ChatMessage.fromJson(message))
                  .toList();

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(message: messages[index]);
                      },
                    ),
                  ),
                  _buildMessageComposer(messages),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageComposer(List<ChatMessage> messages) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      height: 70.0,
      color: Colors.white,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.emoji_emotions),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration.collapsed(
                hintText: 'Type a message',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _handleSubmitted(messages);
            },
          ),
        ],
      ),
    );
  }

  void _handleSubmitted(List<ChatMessage> messages) {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        messages.add(ChatMessage(
          text: _messageController.text,
          isMe: true,
          timestamp: DateTime.now().toString().substring(11, 16),
        ));
      });
      _messageController.clear();
    }
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: message.isMe ? Colors.lightGreen[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text),
            SizedBox(height: 4),
            Text(
              message.timestamp,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final String timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isMe: json['isMe'],
      timestamp: json['timestamp'],
    );
  }
}
