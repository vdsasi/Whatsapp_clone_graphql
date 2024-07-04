import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:whatsapp_clone/components/chat_screen.dart';
import 'package:whatsapp_clone/models/chat_preview.dart';
import 'package:whatsapp_clone/models/shared_user_name.dart';

class ChatsTab extends StatelessWidget {
  final String fetchChatsQuery = """
    query GetChats(\$name: String!) {
      getChats(name: \$name) {
        chatId
        name
        lastMessage
        timestamp
        profilePicture
      }
    }
  """;

  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SharedPrefsName.getUserName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final userName = snapshot.data ?? '';
        print("Fetching chats for user: $userName");

        return Query(
          options: QueryOptions(
            document: gql(fetchChatsQuery),
            variables: {"name": userName},
          ),
          builder: (QueryResult result,
              {VoidCallback? refetch, FetchMore? fetchMore}) {
            if (result.isLoading) {
              print("Query is loading");
              return Center(child: CircularProgressIndicator());
            }

            if (result.hasException) {
              print("Query exception: ${result.exception.toString()}");
              return Center(
                  child: Text("Error: ${result.exception.toString()}"));
            }

            if (result.data == null || result.data!['getChats'] == null) {
              print("No data received from the query");
              return Center(child: Text("No chats found"));
            }

            List<ChatPreview> chats = (result.data!['getChats'] as List)
                .map((chat) => ChatPreview.fromJson(chat))
                .toList();

            print("Received ${chats.length} chats");
          
            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                return ChatListItem(chat: chats[index]);
              },
            );
          },
        );
      },
    );
  }
}

class ChatListItem extends StatelessWidget {
  final ChatPreview chat;

  const ChatListItem({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(chat.profilePicture),
      ),
      title: Text(chat.name),
      subtitle: Text(chat.lastMessage),
      // trailing: Text(chat.timestamp),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(chat: chat)),
        );
      },
    );
  }
}
