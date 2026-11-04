import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';

class CreateOrderService {
  /// Creates an order using POST /orders.
  static Future<Map<String, dynamic>> createOrder({
    required String orderNumber,
    required int geofenceId,
    required List<Map<String, dynamic>> items,
    String status = 'pending',
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/orders');
    final response = await http.post(
      uri,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'order_number': orderNumber,
        'geofence_id': geofenceId,
        'status': status,
        'notes': notes,
        'items': items,
      }),
    );

    dynamic decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = {'message': response.body};
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['message']?.toString()
          : null;
      throw Exception(message ?? 'Failed to create order (${response.statusCode})');
    }

    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {'data': decoded};
  }
}
