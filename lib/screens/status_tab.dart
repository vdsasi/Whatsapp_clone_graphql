import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatsapp_clone/components/individual_status_view.dart';
import 'package:whatsapp_clone/models/status_update.dart';

class StatusTab extends StatefulWidget {
  @override
  _StatusTabState createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  List<StatusUpdate> recentUpdates = [];
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserNameAndFetchUpdates();
  }

  Future<void> _loadUserNameAndFetchUpdates() async {
    await _loadUserName();
    await _fetchStatusUpdates();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? '';
    });
  }

  Future<void> _fetchStatusUpdates() async {
    if (userName.isEmpty) {
      print('Username not found in SharedPreferences');
      return;
    }

    final GraphQLClient client = GraphQLProvider.of(context).value;
    final result = await client.query(
      QueryOptions(
        document: gql(getStatusUpdatesQuery),
        variables: {'name': userName},
      ),
    );

    if (result.hasException) {
      print(result.exception.toString());
    } else {
      final statusUpdates = result.data!['getStatusUpdates'] as List<dynamic>;
      final contacts = result.data!['getContacts'] as List<dynamic>;

      setState(() {
        recentUpdates = statusUpdates.map((status) {
          final contact = contacts.firstWhere(
            (c) => c['name'] == status['name'],
            orElse: () => {'name': 'Unknown', 'profilePicture': ''},
          );

          return StatusUpdate(
            name: contact['name'],
            timestamp: status['timestamp'],
            profilePicture: contact['profilePicture'],
            imageUrl: status['imageUrl'],
          );
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage:
                    NetworkImage("https://picsum.photos/id/1062/200/200"),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.teal,
                  radius: 10,
                  child: Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          title: Text("My status"),
          subtitle: Text("Tap to add status update"),
          onTap: () {
            // TODO: Implement add status functionality
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Recent updates",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...recentUpdates
            .map((status) =>
                StatusListItem(status: status, allStatuses: recentUpdates))
            .toList(),
      ],
    );
  }
}

// StatusListItem widget remains the same
class StatusListItem extends StatelessWidget {
  final StatusUpdate status;
  final List<StatusUpdate> allStatuses;

  const StatusListItem(
      {Key? key, required this.status, required this.allStatuses})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(status.profilePicture),
      ),
      title: Text(status.name),
      subtitle: Text(status.timestamp),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatusViewScreen(
              status: status,
              allStatuses: allStatuses,
              initialIndex: 0,
            ),
          ),
        );
      },
    );
  }
}

// Add this at the top of your file or in a separate constants file
const String getStatusUpdatesQuery = '''
  query GetStatusUpdates(\$name: String!) {
    getStatusUpdates(name: \$name) {
      timestamp
      imageUrl
    }
    getContacts(name: \$name) {
      name
      profilePicture
    }
  }
''';
