import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';
import 'auth_service.dart';

class ProductService {
  /// Fetches one page of products for the signed-in user's company.
  ///
  /// Returns the product items and pagination metadata from the API response.
  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int? companyId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }

    final resolvedCompanyId = companyId ?? await AuthService.getCompanyId();
    if (resolvedCompanyId == null) {
      throw Exception('No company ID found for the signed-in user');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/products').replace(
      queryParameters: {
        'company_id': resolvedCompanyId.toString(),
        'page': page.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load products (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid product response format');
    }

    final pageData = decoded['data'];
    if (pageData is! Map<String, dynamic>) {
      throw const FormatException('Product response is missing pagination data');
    }

    final rawItems = pageData['data'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    return {
      'message': decoded['message'],
      'items': items,
      'current_page': pageData['current_page'] as int? ?? page,
      'last_page': pageData['last_page'] as int? ?? page,
      'total': pageData['total'] as int? ?? items.length,
    };
  }
}
