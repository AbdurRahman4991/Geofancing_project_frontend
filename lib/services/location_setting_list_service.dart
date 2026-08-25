// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../plugins/api_config.dart';

// class LocationSettingListService {
//   static Future<List<dynamic>> getGeofences() async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('access_token');

//     if (token == null) {
//       print("⚠️ No token found!");
//       return [];
//     }

//     final uri = Uri.parse("${ApiConfig.baseUrl}/geofences");

//     final headers = {
//       ...ApiConfig.headers,
//       'Authorization': 'Bearer $token',
//     };

//     final response = await http.get(uri, headers: headers);

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body) as List<dynamic>;
//     }

//     return [];
//   } catch (e) {
//     print(e);
//     return [];
//   }
// }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../plugins/api_config.dart';

class LocationSettingListService {
  static Future<List<dynamic>> getGeofences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        print("⚠️ No token found!");
        return [];
      }

      final uri = Uri.parse("${ApiConfig.baseUrl}/geofences");

      final headers = {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        uri,
        headers: headers,
      );

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body);

        final Map<String, dynamic> data =
            json['data'] as Map<String, dynamic>;

        final List<dynamic> locations =
            data['data'] as List<dynamic>;

        return locations;
      }

      print("API ERROR: ${response.statusCode}");
      return [];
    } catch (e) {
      print("GET GEOFENCES ERROR: $e");
      return [];
    }
  }
}