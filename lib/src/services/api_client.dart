import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SessionExpiredException implements Exception {}

class ApiClient {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  ApiClient({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<http.Response> get(String path) {
    return _authorizedRequest(
      (baseUrl, accessToken) => _client.get(
        Uri.parse('$baseUrl$path'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }

  Future<http.Response> post(String path) {
    return _authorizedRequest(
      (baseUrl, accessToken) => _client.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );
  }

  // files receives a factory because a MultipartFile stream can only be sent once,
  // and the request is rebuilt when the token has to be refreshed.
  Future<http.Response> postMultipart(
    String path, {
    required Map<String, String> fields,
    required Future<List<http.MultipartFile>> Function() files,
  }) {
    return _authorizedRequest((baseUrl, accessToken) async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..fields.addAll(fields)
        ..files.addAll(await files());
      return http.Response.fromStream(await _client.send(request));
    });
  }

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(String baseUrl, String accessToken) request,
  ) async {
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null) throw SessionExpiredException();

    var response = await request(baseUrl, accessToken);

    if (response.statusCode == 401) {
      final newAccessToken = await _refresh(baseUrl);
      if (newAccessToken == null) throw SessionExpiredException();
      response = await request(baseUrl, newAccessToken);
    }

    return response;
  }

  Future<String?> _refresh(String baseUrl) async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return null;

    final response = await _client.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final newAccessToken = body['access_token'] as String;

    await _storage.write(key: 'access_token', value: newAccessToken);
    await _storage.write(key: 'refresh_token', value: body['refresh_token'] as String);

    return newAccessToken;
  }
}
