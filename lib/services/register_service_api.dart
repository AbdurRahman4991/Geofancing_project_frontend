import 'dart:convert';
import 'package:http/http.dart' as http;
import '/plugins/api_config.dart';

class ApiService {
  static Future<String?> registerUser(
      String employee_id, String phone) async {
    try {
      var url = Uri.parse('${ApiConfig.baseUrl}/register');

      var response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'employee_id': employee_id,
          'phone': phone,
        }),
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // ✅ Registration successful
        return data['message'] ?? "Registration successful.";
      } else if (response.statusCode == 422) {
        // ✅ Laravel validation error
        if (data['errors'] != null && data['errors'].isNotEmpty) {
          final firstError = data['errors'].values.first[0];
          return firstError;
        }
        return data['message'] ?? "Validation failed";
      } else {
        return data['message'] ?? "Something went wrong.";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
