import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:whatsapp_clone/screens/calls_tab.dart';
import 'package:whatsapp_clone/screens/chats_tab.dart';
import 'package:whatsapp_clone/screens/status_tab.dart';
import 'package:whatsapp_clone/screens/auth_screen.dart';
import 'package:whatsapp_clone/screens/select_contact_screen.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:dio/dio.dart';
import 'package:whatsapp_clone/custom_http_client.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();

  final CustomHttpClient httpClient = CustomHttpClient();

  // Fetch initial CSRF token
  await httpClient.fetchCsrfToken();

  final Link link = httpClient.link;

  final client = GraphQLClient(
    cache: GraphQLCache(store: HiveStore()),
    link: link,
  );

  runApp(
    GraphQLProvider(
      client: ValueNotifier(client),
      child: MyApp(),
    ),
  );
}

class _DioHttpClient extends http.BaseClient {
  final Dio _dio;

  _DioHttpClient(this._dio);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final options = Options(
      method: request.method,
      headers: request.headers,
    );

    try {
      final dioResponse = await _dio.requestUri(
        request.url,
        options: options,
        data: request is http.Request ? request.body : null,
      );

      return http.StreamedResponse(
        Stream.fromIterable([dioResponse.data?.toString().codeUnits ?? []]),
        dioResponse.statusCode ?? 200,
        headers: _normalizeHeaders(dioResponse.headers.map),
      );
    } on DioException catch (e) {
      return http.StreamedResponse(
        Stream.fromIterable([e.response?.data?.toString().codeUnits ?? []]),
        e.response?.statusCode ?? 500,
        headers: _normalizeHeaders(e.response?.headers.map ?? {}),
      );
    }
  }

  Map<String, String> _normalizeHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.join(', '));
      }
      return MapEntry(key, value.toString());
    });
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Clone',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF075E54),
          secondary: Color(0xFF25D366),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF075E54),
          foregroundColor: Colors.white,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF25D366),
          foregroundColor: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WhatsApp'),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'CHATS'),
            Tab(text: 'STATUS'),
            Tab(text: 'CALLS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatsTab(),
          StatusTab(),
          CallsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.message),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SelectContactScreen()),
          );
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'WhatsApp Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                // TODO: Implement logout functionality
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
