import 'package:flutter/material.dart';

class SelectContactScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select contact'),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(Icons.group, color: Colors.white),
            ),
            title: Text('New group'),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(Icons.person_add, color: Colors.white),
            ),
            title: Text('New contact'),
          ),
          _buildContactTile('Abby', 'Hey there! I am using WhatsApp.', 'assets/abby.jpg'),
          _buildContactTile('Angie Nondorf', 'Hey there! I am using WhatsApp.', 'assets/angie.jpg'),
          _buildContactTile('Ash', 'Hey there! I am using WhatsApp.', null),
          _buildContactTile('Christy', 'Miss Congeniality/2nd runner up to Miss...', 'assets/christy.jpg'),
          _buildContactTile('Daniel Nondorf', '¡Hola! Estoy usando WhatsApp.', 'assets/daniel.jpg'),
          _buildContactTile('Jennifer Nondorf', 'Hey there! I am using WhatsApp.', 'assets/jennifer.jpg'),
          _buildContactTile('Mike Weston', 'Hey there! I am using WhatsApp.', null),
          _buildContactTile('Nick Pratt', 'Available', 'assets/nick.jpg'),
        ],
      ),
    );
  }

  Widget _buildContactTile(String name, String status, String? imagePath) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: imagePath != null ? AssetImage(imagePath) : null,
        child: imagePath == null ? Icon(Icons.person) : null,
      ),
      title: Text(name),
      subtitle: Text(
        status,
        style: TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}