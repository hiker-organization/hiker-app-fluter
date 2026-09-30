import 'dart:convert';

import 'package:app_hiker/src/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  UserService({ApiClient? apiClient, FlutterSecureStorage? storage})
      : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getMyPhotoUrl() async {
    try {
      final response = await _apiClient.get('/user/me');
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      return data?['foto_url'] as String?;
    } on SessionExpiredException {
      return null;
    }
  }

  // Validates the stored session against the API; ApiClient refreshes the token on 401.
  // Returns false only when the session is known to be invalid. Network failures and
  // server errors keep the user logged in so an offline start doesn't force a new login.
  Future<bool> hasValidSession() async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) return false;

    try {
      final response = await _apiClient.get('/user/me').timeout(const Duration(seconds: 5));
      if (response.statusCode == 401) {
        await logout();
        return false;
      }
      return true;
    } on SessionExpiredException {
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
