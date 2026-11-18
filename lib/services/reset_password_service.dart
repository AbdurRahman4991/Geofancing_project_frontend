
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../plugins/api_config.dart';

class ResetPasswordService {

  /// POST /api/reset-password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/reset-password',
    );

    final response = await http.post(
      uri,
      headers: {
        ...ApiConfig.headers,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {

      final message = decoded is Map
          ? decoded['message']?.toString()
          : null;

      throw Exception(
        message ??
            'Password reset failed (${response.statusCode})',
      );
    }

    if (decoded is! Map) {
      throw const FormatException(
        'Invalid reset password response format',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }
}
