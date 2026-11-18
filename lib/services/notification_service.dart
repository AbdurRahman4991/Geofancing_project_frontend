
// import 'dart:convert';

// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// import '../plugins/api_config.dart';

// class NotificationService {
//   /// GET /api/notifications
//   static Future<Map<String, dynamic>> getNotifications({
//     int page = 1,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('access_token');
//     if (token == null || token.isEmpty) {
//       throw Exception('No access token found. Please sign in again.');
//     }

//     final uri = Uri.parse(
//       '${ApiConfig.baseUrl}/notifications',
//     ).replace(
//       queryParameters: {
//         'page': page.toString(),
//       },
//     );

//     final response = await http.get(
//       uri,
//       headers: {
//         ...ApiConfig.headers,
//         'Authorization': 'Bearer $token',
//         'Accept': 'application/json',
//       },
//     );

//     dynamic decoded;

//     try {
//       decoded = jsonDecode(response.body);
//     } on FormatException {
//       decoded = null;
//     }

//     if (response.statusCode < 200 ||
//         response.statusCode >= 300) {
//       final message = decoded is Map
//           ? decoded['message']?.toString()
//           : null;

//       throw Exception(
//         message ??
//             'Failed to fetch notifications (${response.statusCode})',
//       );
//     }

//     if (decoded is! Map) {
//       throw const FormatException(
//         'Invalid notification response format',
//       );
//     }

//     return Map<String, dynamic>.from(decoded);
//   }

//   /// Get unread notification count
//   static Future<int> getUnreadCount() async {
//     final response = await getNotifications();

//     return int.tryParse(
//           response['unread_count']?.toString() ?? '0',
//         ) ??
//         0;
//   }
// }

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/api_config.dart';

class NotificationService {
  /// Get Authorization Headers
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception(
        'No access token found. Please sign in again.',
      );
    }

    return {
      ...ApiConfig.headers,
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// Handle API Response
  static Map<String, dynamic> _handleResponse(
    http.Response response,
    String errorMessage,
  ) {
    dynamic decoded;

    try {
      decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['message']?.toString()
          : null;

      throw Exception(
        message ?? '$errorMessage (${response.statusCode})',
      );
    }

    if (decoded is! Map) {
      throw const FormatException(
        'Invalid notification response format',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  /// GET /api/notifications
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/notifications',
    ).replace(
      queryParameters: {
        'page': page.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    return _handleResponse(
      response,
      'Failed to fetch notifications',
    );
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    final response = await getNotifications();

    return int.tryParse(
          response['unread_count']?.toString() ?? '0',
        ) ??
        0;
  }

  /// PATCH /api/notifications/{notificationId}/read
  static Future<Map<String, dynamic>> markAsRead({
    required String notificationId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/notifications/'
      '${Uri.encodeComponent(notificationId)}/read',
    );

    final response = await http.patch(
      uri,
      headers: await _getHeaders(),
    );

    return _handleResponse(
      response,
      'Failed to mark notification as read',
    );
  }

  /// PATCH /api/notifications/read-all
  static Future<Map<String, dynamic>> markAllAsRead() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/notifications/read-all',
    );

    final response = await http.patch(
      uri,
      headers: await _getHeaders(),
    );

    return _handleResponse(
      response,
      'Failed to mark all notifications as read',
    );
  }
}
