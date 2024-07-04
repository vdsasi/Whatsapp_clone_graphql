import 'package:flutter/material.dart';

class CallsTab extends StatelessWidget {
  final List<CallHistory> calls = [
    CallHistory(
      name: "Jane Cooper",
      timestamp: "February 11, 23:17",
      isVideoCall: false,
      isIncoming: true,
      profilePicture: "http://example.com/100",
    ),
    CallHistory(
      name: "Gloria",
      timestamp: "February 11, 16:26",
      isVideoCall: false,
      isIncoming: false,
      profilePicture: "http://example.com/100",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    print(context);
    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        return CallListItem(call: calls[index]);
      },
    );
  }
}

class CallListItem extends StatelessWidget {
  final CallHistory call;

  const CallListItem({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(call.profilePicture),
      ),
      title: Text(call.name),
      subtitle: Row(
        children: [
          Icon(
            call.isIncoming ? Icons.call_received : Icons.call_made,
            size: 16,
            color: call.isIncoming ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(call.timestamp),
        ],
      ),
      trailing: Icon(call.isVideoCall ? Icons.videocam : Icons.call),
    );
  }
}

class CallHistory {
  final String name;
  final String timestamp;
  final bool isVideoCall;
  final bool isIncoming;
  final String profilePicture;

  CallHistory({
    required this.name,
    required this.timestamp,
    required this.isVideoCall,
    required this.isIncoming,
    required this.profilePicture,
  });
}
