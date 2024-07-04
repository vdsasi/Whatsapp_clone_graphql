import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatsapp_clone/components/individual_status_view.dart';
import 'package:whatsapp_clone/models/status_update.dart';

class StatusTab extends StatefulWidget {
  const StatusTab({super.key});

  @override
  _StatusTabState createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  Map<String, List<StatusUpdate>> groupedUpdates = {};
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? '';
    });
  }

  String _getUpdateTime(String timestamp) {
    final difference = DateTime.now().difference(DateTime.parse(timestamp));
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Stack(
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
          title: const Text("My status"),
          subtitle: const Text("Tap to add status update"),
          onTap: () {},
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Recent updates",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Query(
            options: QueryOptions(
              document: gql(getContactsQuery),
              variables: {'name': userName},
            ),
            builder: (QueryResult result, {fetchMore, refetch}) {
              if (result.hasException) {
                return Text(result.exception.toString());
              }

              if (result.isLoading) {
                return const CircularProgressIndicator();
              }

              final contacts = (result.data!['getContacts'] as List<dynamic>)
                  .cast<Map<String, dynamic>>();

              final contactNames =
                  contacts.map((contact) => contact['name'] as String).toList();

              return Query(
                options: QueryOptions(
                  document: gql(getStatusUpdatesQuery),
                  variables: {'names': contactNames},
                ),
                builder: (QueryResult statusResult, {fetchMore, refetch}) {
                  if (statusResult.hasException) {
                    return Text(statusResult.exception.toString());
                  }

                  if (statusResult.isLoading) {
                    return const CircularProgressIndicator();
                  }

                  final statusUpdates =
                      (statusResult.data!['getStatusUpdates'] as List<dynamic>)
                          .cast<Map<String, dynamic>>();

                  Map<String, List<StatusUpdate>> newGroupedUpdates = {};

                  for (var status in statusUpdates) {
                    final statusName = status['name'];
                    final contact = contacts.firstWhere(
                      (c) => c['name'] == statusName,
                      orElse: () => {'name': statusName, 'profilePicture': ''},
                    );

                    final statusUpdate = StatusUpdate(
                      name: statusName,
                      timestamp: status['timestamp'],
                      profilePicture: contact['profilePicture'] ??
                          'https://via.placeholder.com/150',
                      imageUrl: status['imageUrl'] ??
                          'https://via.placeholder.com/300',
                    );

                    if (!newGroupedUpdates.containsKey(statusName)) {
                      newGroupedUpdates[statusName] = [];
                    }
                    newGroupedUpdates[statusName]!.add(statusUpdate);
                  }

                  newGroupedUpdates.forEach((key, value) {
                    value.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                  });

                  List<MapEntry<String, List<StatusUpdate>>> sortedEntries =
                      newGroupedUpdates.entries.toList()
                        ..sort((a, b) => b.value.first.timestamp
                            .compareTo(a.value.first.timestamp));

                  return ListView(
                    children: [
                      ...sortedEntries.map((entry) => StatusListItem(
                          name: entry.key, statuses: entry.value))
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class StatusListItem extends StatelessWidget {
  final String name;
  final List<StatusUpdate> statuses;

  const StatusListItem({
    super.key,
    required this.name,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(statuses.first.profilePicture),
      ),
      title: Text(name),
      subtitle: Text(
        '${_getUpdateTime(statuses.first.timestamp)} (${statuses.length} updates)',
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatusViewScreen(
              statuses: statuses,
            ),
          ),
        );
      },
    );
  }

  String _getUpdateTime(String timestamp) {
    final difference = DateTime.now().difference(DateTime.parse(timestamp));
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

const String getContactsQuery = '''
  query GetContacts(\$name: String!) {
    getContacts(name: \$name) {
      name
      profilePicture
    }
  }
''';

const String getStatusUpdatesQuery = '''
  query GetStatusUpdates(\$names: [String!]!) {
    getStatusUpdates(names: \$names) {
      name
      timestamp
      imageUrl
    }
  }
''';
