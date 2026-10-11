import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../plugins/api_config.dart';

class LocationSettingListService {
  static Future<Map<String, dynamic>> getGeofences({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) throw Exception('No access token found');

    final uri = Uri.parse('${ApiConfig.baseUrl}/geofences').replace(
      queryParameters: {'page': page.toString()},
    );
    final response = await http.get(uri, headers: {
      ...ApiConfig.headers,
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to load geofences (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final pageData = decoded['data'] as Map<String, dynamic>;
    return {
      'items': (pageData['data'] as List<dynamic>?) ?? <dynamic>[],
      'current_page': pageData['current_page'] as int? ?? page,
      'last_page': pageData['last_page'] as int? ?? page,
    };
  }
}
