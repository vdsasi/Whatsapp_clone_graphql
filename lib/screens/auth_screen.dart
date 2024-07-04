import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:whatsapp_clone/main.dart';
import 'package:whatsapp_clone/custom_http_client.dart';
import 'package:whatsapp_clone/models/shared_user_name.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});


  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _name = '';
  String _confirmPassword = '';
  bool _isLoading = false;
  String _csrfToken = '';

  @override
  void initState() {
    super.initState();
    _fetchCsrfToken();
  }

  Future<void> _fetchCsrfToken() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/csrf-token'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      // print('CSRF Token Response: ${response.body}'); // Debug print
      if (response.statusCode == 200) {
        setState(() {
          _csrfToken = json.decode(response.body)['csrfToken'];
        });
        // print('CSRF Token fetched: $_csrfToken'); // Debug print
      } else {
        // print('Failed to fetch CSRF token. Status code: ${response.statusCode}');
        throw Exception('Failed to fetch CSRF token');
      }
    } catch (error) {
      // print('Error fetching CSRF token: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to initialize security. Please try again.')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final CustomHttpClient httpClient = CustomHttpClient();

      final url = isLogin
          ? 'http://10.0.2.2:5000/api/login'
          : 'http://10.0.2.2:5000/api/signup';

      try {
        final response = await httpClient.dio.post(
          url,
          data: {
            'email': _email,
            'password': _password,
            if (!isLogin) 'name': _name,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Authentication successful
          // print('Authentication successful');
          final responseData = response.data;
          final userName = responseData['name'];

          // Save the user's name to SharedPreferences
          await SharedPrefsName.setUserName(userName);

          // print("authenticated username: " + userName);

          // The token should be automatically saved by the CustomHttpClient
          // You can navigate to the HomeScreen here
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // Authentication failed
          print('Authentication failed');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed. Please try again.')),
          );
        }
      } catch (error) {
        print('Error during authentication: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again later.')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 50),
                Text(
                  isLogin ? 'Login to WhatsApp' : 'Sign Up for WhatsApp',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (!isLogin) ...[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    onChanged: (value) => _name = value,
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                  onChanged: (value) => _email = value,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  onChanged: (value) => _password = value,
                ),
                if (!isLogin) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value != _password) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onChanged: (value) => _confirmPassword = value,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      _csrfToken.isEmpty || _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isLogin ? 'Login' : 'Sign Up'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  child: Text(
                    isLogin
                        ? 'Don\'t have an account? Sign Up'
                        : 'Already have an account? Login',
                  ),
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
