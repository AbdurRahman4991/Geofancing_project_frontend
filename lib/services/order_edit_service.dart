import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';

class OrderEditService {
  static Future<String> _accessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }
    return token;
  }

  static Future<Map<String, dynamic>> _sendRequest(
    http.Response response, {
    required String action,
  }) async {
    dynamic decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = {'message': response.body};
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Failed to $action (${response.statusCode})');
    }

    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {'data': decoded};
  }

  /// Loads an order by ID for the edit form using GET /orders/{id}.
  static Future<Map<String, dynamic>> getOrder(int orderId) async {
    final token = await _accessToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _sendRequest(response, action: 'load order');
  }

  /// Updates an order using PUT /orders/{id}.
  static Future<Map<String, dynamic>> updateOrder({
    required int orderId,
    required String orderNumber,
    required int geofenceId,
    required List<Map<String, dynamic>> items,
    String status = 'pending',
    String? notes,
  }) async {
    final token = await _accessToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId'),
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
    return _sendRequest(response, action: 'update order');
  }
}
