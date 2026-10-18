import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../plugins/api_config.dart';
import 'dart:io';

class GeofenceService {
  static String _errorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) return message;

        final errors = decoded['errors'];
        if (errors is Map) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) return value.first.toString();
            if (value is String && value.trim().isNotEmpty) return value;
          }
        }
      }
    } catch (_) {
      // The server may return plain text instead of JSON.
    }
    return body.trim().isNotEmpty ? body.trim() : fallback;
  }

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
  static Future<String?> createGeofence({
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

    // Login user থেকে hierarchy_node_id নেওয়া
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString == null) {
      print("User data not found.");
      return "User data not found. Please login again.";
    }

    final user = jsonDecode(userString);

    final hierarchyNodeId =
        user['hierarchy_assignment']?['hierarchy_node_id'];

    if (hierarchyNodeId == null) {
      print("No hierarchy node assigned to this user.");
      return "No hierarchy node assigned to this user.";
    }

    print("Logged-in User ID: ${user['id']}");
    print("Assigned Hierarchy Node ID: $hierarchyNodeId");

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("${ApiConfig.baseUrl}/geofences"),
    );

    request.headers.addAll(headers);

    request.fields["company_id"] = companyId.toString();
    request.fields["user_id"] = userId.toString();

    // Login user's assigned hierarchy node
    request.fields["hierarchy_node_id"] = hierarchyNodeId.toString();

    request.fields["firm_name"] = firmName;
    request.fields["latitude"] = latitude.toString();
    request.fields["longitude"] = longitude.toString();
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
      return null;
    }

    return _errorMessage(body, "Unable to save location (HTTP ${response.statusCode}).");
  } catch (e) {
    print("Create Error: $e");
    return e.toString();
  }
}

  /// ============================
  /// Update Geofence
  /// ============================
  static Future<String?> updateGeofence({
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
        return null;
      }

      return _errorMessage(body, "Unable to update location (HTTP ${response.statusCode}).");
    } catch (e) {
      print("Update Error: $e");
    return e.toString();
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
