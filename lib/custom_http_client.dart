import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:gql_link/gql_link.dart';

class CustomHttpClient {
  static final CustomHttpClient _instance = CustomHttpClient._internal();
  factory CustomHttpClient() => _instance;

  late Dio _dio;
  late Link _link;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  CustomHttpClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:5000',
      validateStatus: (status) => status! < 500,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final csrfToken = await _secureStorage.read(key: 'csrfToken');
        if (csrfToken != null) {
          options.headers['X-CSRF-Token'] = csrfToken;
        }

        final authToken = await _secureStorage.read(key: 'authToken');
        if (authToken != null) {
          // Ensure that the cookie header is set properly
          options.headers['Cookie'] = 'token=$authToken';
        }

        print('Sending request: ${options.uri}');
        print('Request headers: ${options.headers}');
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        print('Response received: ${response.statusCode}');
        print('Response headers: ${response.headers}');

        // Handle CSRF token from response headers
        final csrfToken = response.headers['X-CSRF-Token']?.first;
        if (csrfToken != null) {
          await _secureStorage.write(key: 'csrfToken', value: csrfToken);
          print('New CSRF token stored: $csrfToken');
        }

        // Handle cookies from response headers
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          for (var cookie in cookies) {
            if (cookie.startsWith('token=')) {
              final authToken = cookie.split(';')[0].split('=')[1];
              await _secureStorage.write(key: 'authToken', value: authToken);
              print('New auth token stored: $authToken');
              break;
            }
          }
        }

        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        print('Error: ${e.message}');
        print('Error response: ${e.response?.data}');
        if (e.response?.statusCode == 403) {
          print('403 Forbidden error. Attempting to fetch new CSRF token...');
          await fetchCsrfToken();
        }
        return handler.next(e);
      },
    ));

    _link = DioLink(
      '/graphql',
      client: _dio,
    );
  }

  Dio get dio => _dio;
  Link get link => _link;

  Future fetchCsrfToken() async {
    try {
      final response = await _dio.get('/api/csrf-token');
      if (response.statusCode == 200) {
        final csrfToken = response.data['csrfToken'];
        await _secureStorage.write(key: 'csrfToken', value: csrfToken);
        print('New CSRF token fetched and stored: $csrfToken');
      } else {
        print('Failed to fetch CSRF token. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching CSRF token: $e');
    }
  }

  Future clearTokens() async {
    await _secureStorage.delete(key: 'csrfToken');
    await _secureStorage.delete(key: 'authToken');
    print('CSRF and auth tokens cleared');
  }
}
