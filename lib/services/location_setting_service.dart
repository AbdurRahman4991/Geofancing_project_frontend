import 'dart:convert';
import 'package:http/http.dart' as http;
import '../plugins/api_config.dart';

class GeofenceService {
  static Future<bool> createGeofence({
    required int companyId,
    required int userId,
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/geofences'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "company_id": companyId,
          "user_id": userId,
          "latitude": latitude,
          "longitude": longitude,
          "radius": radius,
        }),
      );

      print(response.body);

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }
}