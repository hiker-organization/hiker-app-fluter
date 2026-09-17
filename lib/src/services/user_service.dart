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

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
