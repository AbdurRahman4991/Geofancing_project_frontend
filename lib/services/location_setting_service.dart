import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../plugins/api_config.dart';
import 'dart:io';

class GeofenceService {
  /// ============================
  /// Headers
  /// ============================
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    return {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// ============================
  /// Sync Geofence
  /// ============================
  static Future<void> syncGeofences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/geofences'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        List<dynamic> geofenceList = jsonDecode(response.body);

        await prefs.setString(
          'geofancing',
          jsonEncode(geofenceList),
        );

        print("Geofence Synced");
      }
    } catch (e) {
      print("Sync Error: $e");
    }
  }

  /// ============================
  /// Create Geofence
  /// ============================
  static Future<bool> createGeofence({
    required int companyId,
    required int userId,
    required String firmName,
    required double latitude,
    required double longitude,
    required double radius,
    File? image,
  }) async {
    try {
      final headers = await _headers();

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiConfig.baseUrl}/geofences"),
      );

      request.headers.addAll(headers);

      request.fields["company_id"] = companyId.toString();
      request.fields["user_id"] = userId.toString();
      request.fields["firm_name"] = firmName;
      request.fields["latitude"] = latitude.toString();
      request.fields["longitude"] = longitude.toString();
      //request.fields["radius"] = radius.toString();
      request.fields["radius"] = radius.toInt().toString();

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "image",
            image.path,
          ),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      print("Status: ${response.statusCode}");
      print(body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        await syncGeofences();
        return true;
      }

      return false;
    } catch (e) {
      print("Create Error: $e");
      return false;
    }
  }

  /// ============================
  /// Update Geofence
  /// ============================
  static Future<bool> updateGeofence({
    required int id,
    required int companyId,
    required int userId,
    required String firmName,
    required double latitude,
    required double longitude,
    required double radius,
    File? image,
  }) async {
    try {
      final headers = await _headers();

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiConfig.baseUrl}/geofences/$id"),
      );

      request.headers.addAll(headers);

      // Laravel PUT
      request.fields["_method"] = "PUT";

      request.fields["company_id"] = companyId.toString();
      request.fields["user_id"] = userId.toString();
      request.fields["firm_name"] = firmName;
      request.fields["latitude"] = latitude.toString();
      request.fields["longitude"] = longitude.toString();
      //request.fields["radius"] = radius.toString();
      request.fields["radius"] = radius.toInt().toString();

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "image",
            image.path,
          ),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      print("Status: ${response.statusCode}");
      print(body);

      if (response.statusCode == 200) {
        await syncGeofences();
        return true;
      }

      return false;
    } catch (e) {
      print("Update Error: $e");
      return false;
    }
  }

  /// ============================
  /// Get Geofences
  /// ============================
  static Future<List<dynamic>> getGeofences() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/geofences"),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      print("Get Error: $e");
      return [];
    }
  }
}

// class GeofenceService {

//   // static Future<Map<String, String>> _headers() async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   final token = prefs.getString('access_token');
//   // print("TOKEN => $token");

//   //   return {
//   //     ...ApiConfig.headers,
//   //     'Authorization': 'Bearer $token',
//   //   };
//   // }
//   static Future<Map<String, String>> _headers() async {
//   final prefs = await SharedPreferences.getInstance();
//   final token = prefs.getString('access_token');

//   print("TOKEN => $token");

//   return {
//     "Content-Type": "application/json",
//     "Accept": "application/json",
//     "Authorization": "Bearer $token",
//   };
// }

//   /// ============================
//   /// Sync Geofence To SharedPreference
//   /// ============================
//   static Future<void> syncGeofences() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();

//       final response = await http.get(
//         Uri.parse('${ApiConfig.baseUrl}/geofences'),
//         headers: await _headers(),
//       );

//       if (response.statusCode == 200) {
//         List<dynamic> geofenceList = jsonDecode(response.body);

//         // Attendance page এই key use করছে
//         await prefs.setString(
//           'geofancing',
//           jsonEncode(geofenceList),
//         );

//         print("Geofence Synced Successfully");
//       }
//     } catch (e) {
//       print("Sync Error : $e");
//     }
//   }

//   /// ============================
//   /// Create
//   /// ============================
//   static Future<bool> createGeofence({
//     required int companyId,
//     required int userId,
//     required String firmName, 
//     required double latitude,
//     required double longitude,
//     required double radius,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('${ApiConfig.baseUrl}/geofences'),
//         headers: await _headers(),
//         body: jsonEncode({
//           "company_id": companyId,
//           "user_id": userId,
//           "firm_name": firmName,
//           "latitude": latitude,
//           "longitude": longitude,
//           "radius": radius,
//         }),
//       );

//       print("Status Code : ${response.statusCode}");
//       print("Response : ${response.body}");

//       if (response.statusCode == 200 ||
//           response.statusCode == 201) {

//         // SharedPreference Update
//         await syncGeofences();

//         return true;
//       }

//       return false;
//     } catch (e) {
//       print(e);
//       return false;
//     }
//   }

//   /// ============================
//   /// Update
//   /// ============================
//   static Future<bool> updateGeofence({
//     required int id,
//     required int companyId,
//     required int userId,
//     required String firmName, 
//     required double latitude,
//     required double longitude,
//     required double radius,
//   }) async {
//     try {
//       final response = await http.put(
//         Uri.parse('${ApiConfig.baseUrl}/geofences/$id'),
//         headers: await _headers(),
//         body: jsonEncode({
//           "company_id": companyId,
//           "user_id": userId,
//           "firm_name": firmName,
//           "latitude": latitude,
//           "longitude": longitude,
//           "radius": radius,
//         }),
//       );

//       print(response.body);

//       if (response.statusCode == 200) {

//         // SharedPreference Update
//         await syncGeofences();

//         return true;
//       }

//       return false;
//     } catch (e) {
//       print(e);
//       return false;
//     }
//   }

//   /// ============================
//   /// List
//   /// ============================
//   static Future<List<dynamic>> getGeofences() async {
//     try {
//       final response = await http.get(
//         Uri.parse('${ApiConfig.baseUrl}/geofences'),
//         headers: await _headers(),
//       );

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       }

//       return [];
//     } catch (e) {
//       print(e);
//       return [];
//     }
//   }
// }

