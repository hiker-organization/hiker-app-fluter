import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmailServiceException implements Exception {
  final String message;
  EmailServiceException(this.message);

  @override
  String toString() => message;
}

String _extractMessage(dynamic message, String fallback) {
  if (message == null) return fallback;
  if (message is List) return message.join(', ');
  return message.toString();
}

class EmailService {
  final http.Client _client;

  EmailService({http.Client? client}) : _client = client ?? http.Client();

  Future<void> forgotPassword({required String email}) async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw EmailServiceException(_extractMessage(body['message'], 'Não foi possível enviar o e-mail'));
    }
  }
}
