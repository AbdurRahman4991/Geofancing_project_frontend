import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';
import 'auth_service.dart';

class TourPlanService {
  static Future<Map<String, dynamic>> createTourPlan({
    required int userId,
    required String planDate,
    String? notes,
    required List<Map<String, dynamic>> stops,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) throw Exception('No access token found');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/tour-plans'),
      headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'user_id': userId,
        'plan_date': planDate,
        'notes': notes,
        'stops': stops,
      }),
    );
    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded is Map ? decoded['message']?.toString() ?? 'Could not create tour plan (${response.statusCode})' : 'Could not create tour plan (${response.statusCode})');
    }
    return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
  }

  static Future<Map<String, dynamic>> getTourPlans({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) throw Exception('No access token found');
    final userId = await AuthService.getUserId();
    final query = <String, String>{'page': '$page'};
    if (userId != null) query['user_id'] = '$userId';
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tour-plans').replace(queryParameters: query),
      headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
    );
    final decoded = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded is Map ? decoded['message']?.toString() ?? 'Could not load tour plans (${response.statusCode})' : 'Could not load tour plans (${response.statusCode})');
    }
    if (decoded is! Map) throw const FormatException('Invalid tour plans response');
    final pageData = decoded['data'];
    final rawItems = pageData is Map ? pageData['data'] : pageData;
    return {
      'items': rawItems is List ? rawItems.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : <Map<String, dynamic>>[],
      'current_page': pageData is Map ? int.tryParse('${pageData['current_page'] ?? page}') ?? page : page,
      'last_page': pageData is Map ? int.tryParse('${pageData['last_page'] ?? page}') ?? page : page,
    };
  }

  static dynamic _decode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try { return jsonDecode(body); } on FormatException { return {'message': body}; }
  }
}
