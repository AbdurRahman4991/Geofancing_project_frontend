
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../plugins/api_config.dart';

class ForgotPasswordService {
  /// POST /api/password/forgot
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/password/forgot',
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
            'Failed to send reset link (${response.statusCode})',
      );
    }

    if (decoded is! Map) {
      throw const FormatException(
        'Invalid forgot password response format',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }
}
