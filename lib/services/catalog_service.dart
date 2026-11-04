import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';
import 'auth_service.dart';

class CatalogService {
  /// Fetches one page of catalog items for the signed-in user's company.
  ///
  /// Returns the item list and pagination metadata from the API response.
  static Future<Map<String, dynamic>> getCatalog({
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

    final uri = Uri.parse('${ApiConfig.baseUrl}/catalog').replace(
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

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(
        message ?? 'Failed to load catalog (${response.statusCode})',
      );
    }

    if (decoded is! Map) {
      throw const FormatException('Invalid catalog response format');
    }

    final pageData = decoded['data'];
    if (pageData is! Map) {
      throw const FormatException('Catalog response is missing pagination data');
    }

    final rawItems = pageData['data'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    int readInt(dynamic value, int fallback) =>
        int.tryParse(value?.toString() ?? '') ?? fallback;

    final currentPage = readInt(pageData['current_page'], page);
    return {
      'message': decoded['message'],
      'items': items,
      'current_page': currentPage,
      'last_page': readInt(pageData['last_page'], currentPage),
      'total': readInt(pageData['total'], items.length),
    };
  }
}
