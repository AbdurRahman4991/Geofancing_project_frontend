import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>?> getCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();

  final userJson = prefs.getString('user');

  if (userJson == null) {
    return null;
  }
  return jsonDecode(userJson);
}