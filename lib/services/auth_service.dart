import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final user = jsonDecode(prefs.getString('user')!);

    return user['id'];
  }

  static Future<int?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    final user = jsonDecode(prefs.getString('user')!);

    return user['employee']['company_id'];
  }
}