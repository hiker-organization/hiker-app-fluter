import 'dart:convert';

import 'package:app_hiker/src/models/user_profile.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserNotFoundException implements Exception {}

class UserService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  // Nick of the logged user, filled by getMe(). Used to tell the own profile apart
  // when opening a profile from a review.
  static String? myNick;

  UserService({ApiClient? apiClient, FlutterSecureStorage? storage})
      : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<UserProfile> getMe() async {
    final response = await _apiClient.get('/user/me');
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar o perfil');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final profile = UserProfile.fromJson(body['data'] as Map<String, dynamic>);
    myNick = profile.nomeUsuario;
    return profile;
  }

  // Returns only the reviews that are not hidden; the API filters them out.
  Future<UserProfile> getUserProfile(String nick) async {
    final response = await _apiClient.get('/user/${Uri.encodeComponent(nick)}');
    if (response.statusCode == 404) throw UserNotFoundException();
    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar o perfil');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return UserProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<String?> getMyPhotoUrl() async {
    try {
      return (await getMe()).fotoUrl;
    } catch (_) {
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
    myNick = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
