import 'dart:convert';
import 'package:http/http.dart' as http;
import '../plugins/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
class GeofenceService {
  // static Future<bool> createGeofence({
  //   required int companyId,
  //   required int userId,
  //   required double latitude,
  //   required double longitude,
  //   required double radius,
  // }) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('${ApiConfig.baseUrl}/geofences'),
  //       headers: ApiConfig.headers,
  //       body: jsonEncode({
  //         "company_id": companyId,
  //         "user_id": userId,
  //         "latitude": latitude,
  //         "longitude": longitude,
  //         "radius": radius,
  //       }),
  //     );

  //     print(response.body);

  //     return response.statusCode == 200 ||
  //         response.statusCode == 201;
  //   } catch (e) {
  //     print(e);
  //     return false;
  //   }
  // }
  static Future<bool> createGeofence({
  required int companyId,
  required int userId,
  required double latitude,
  required double longitude,
  required double radius,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/geofences'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
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

 static Future<bool> updateGeofence({
  required int id,
  required int companyId,
  required int userId,
  required double latitude,
  required double longitude,
  required double radius,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/geofences/$id'),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "company_id": companyId,
        "user_id": userId,
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius,
      }),
    );

    print(response.statusCode);
    print(response.body);

    return response.statusCode == 200;
  } catch (e) {
    print(e);
    return false;
  }
}
}