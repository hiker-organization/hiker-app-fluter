import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

String _extractMessage(dynamic message, String fallback) {
  if (message == null) return fallback;
  if (message is List) return message.join(', ');
  return message.toString();
}

class AuthService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  AuthService({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<void> login({required String email, required String password}) async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(_extractMessage(body['message'], 'Não foi possível fazer login'));
    }

    await _storage.write(key: 'access_token', value: body['access_token'] as String);
    await _storage.write(key: 'refresh_token', value: body['refresh_token'] as String);
  }

  Future<void> register({
    required String nomeUsuario,
    required String nomeExibicao,
    required String email,
    required String senha,
    required String numeroCelular,
    required DateTime dataNascimento,
    String? fotoPath,
  }) async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user'))
      ..fields.addAll({
        'nome_usuario': nomeUsuario,
        'nome_exibicao': nomeExibicao,
        'email': email,
        'senha': senha,
        'numero_celular': numeroCelular,
        'data_nascimento': dataNascimento.toIso8601String(),
      });

    if (fotoPath != null) {
      final extension = fotoPath.split('.').last.toLowerCase();
      request.files.add(await http.MultipartFile.fromPath(
        'foto',
        fotoPath,
        contentType: MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
      ));
    }

    final response = await http.Response.fromStream(await _client.send(request));
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(_extractMessage(body['message'], 'Não foi possível criar a conta'));
    }
  }

  Future<void> verifyResetCode({required String email, required String token}) async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/verify-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': token}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(_extractMessage(body['message'], 'Código inválido ou expirado'));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String senha,
  }) async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'token': token, 'senha': senha}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(_extractMessage(body['message'], 'Não foi possível redefinir a senha'));
    }
  }
}
