// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '/plugins/api_config.dart';

// class ApiService {
//   static Future<String?> registerUser(
//       String employee_id, String phone) async {
//     try {
//       var url = Uri.parse('${ApiConfig.baseUrl}/register');

//       var response = await http.post(
//         url,
//         headers: ApiConfig.headers,
//         body: jsonEncode({
//           'employee_id': employee_id,
//           'phone': phone,
//         }),
//       );

//       var data = jsonDecode(response.body);

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         // ✅ Registration successful
//         return data['message'] ?? "Registration successful.";
//       } else if (response.statusCode == 422) {
//         // ✅ Laravel validation error
//         if (data['errors'] != null && data['errors'].isNotEmpty) {
//           final firstError = data['errors'].values.first[0];
//           return firstError;
//         }
//         return data['message'] ?? "Validation failed";
//       } else {
//         return data['message'] ?? "Something went wrong.";
//       }
//     } catch (e) {
//       return "Error: $e";
//     }
//   }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/plugins/api_config.dart';

class ApiService {
  static Future<String?> registerUser(
    String employeeId,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/register',
      );

      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'employee_id': employeeId.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      // Registration successful
      if (response.statusCode == 201 ||
          response.statusCode == 200) {
        return data['message'] ??
            'Registration successful.';
      }

      // Laravel validation error
      if (response.statusCode == 422) {
        final errors = data['errors'];

        if (errors != null &&
            errors is Map &&
            errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List &&
              firstError.isNotEmpty) {
            return firstError.first.toString();
          }

          return firstError.toString();
        }

        return data['message'] ??
            'Validation failed.';
      }

      // Unauthorized
      if (response.statusCode == 401) {
        return data['message'] ??
            'Unauthorized request.';
      }

      // Server error
      if (response.statusCode >= 500) {
        return 'Server error. Please try again later.';
      }

      // Other errors
      return data['message'] ??
          'Something went wrong.';
    } catch (e) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
  }
}