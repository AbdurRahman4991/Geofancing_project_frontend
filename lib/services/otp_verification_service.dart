
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:TrackingApp/plugins/api_config.dart';

class OtpVerificationService {

  /// POST /api/verify-otp
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/verify-otp',
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
            'OTP verification failed (${response.statusCode})',
      );
    }

    if (decoded is! Map) {
      throw const FormatException(
        'Invalid OTP response format',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }
}
