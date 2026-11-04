import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';

class OrderService {
  /// Fetches one page of orders using GET /orders?page=...
  static Future<Map<String, dynamic>> getOrders({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/orders').replace(
      queryParameters: {'page': page.toString()},
    );
    final response = await http.get(
      uri,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Failed to load orders (${response.statusCode})');
    }
    if (decoded is! Map) {
      throw const FormatException('Invalid orders response format');
    }

    final pageData = decoded['data'];
    final rawItems = pageData is Map ? pageData['data'] : pageData;
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((order) => Map<String, dynamic>.from(order))
            .toList()
        : <Map<String, dynamic>>[];
    final currentPage = pageData is Map
        ? int.tryParse('${pageData['current_page'] ?? page}') ?? page
        : page;
    final lastPage = pageData is Map
        ? int.tryParse('${pageData['last_page'] ?? currentPage}') ?? currentPage
        : currentPage;

    return {
      'message': decoded['message'],
      'items': items,
      'current_page': currentPage,
      'last_page': lastPage,
      'total': pageData is Map
          ? int.tryParse('${pageData['total'] ?? items.length}') ?? items.length
          : items.length,
    };
  }
}
