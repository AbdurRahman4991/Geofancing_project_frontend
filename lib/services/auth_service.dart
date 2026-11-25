// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthService {
//   static Future<int?> getUserId() async {
//     final prefs = await SharedPreferences.getInstance();

//     final userString = prefs.getString('user');

//     if (userString == null || userString.isEmpty) {
//       return null;
//     }

//     final user = jsonDecode(userString);

//     return user['id'];
//   }

//   static Future<int?> getCompanyId() async {
//     final prefs = await SharedPreferences.getInstance();

//     final userString = prefs.getString('user');

//     if (userString == null || userString.isEmpty) {
//       return null;
//     }

//     final user = jsonDecode(userString);

//     final employee = user['employee'];

//     if (employee == null) {
//       return null;
//     }

//     return employee['company_id'];
//   }
// }


import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  // =====================================
  // GET USER ID
  // =====================================

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString('user');

    if (userString == null || userString.isEmpty) {
      return null;
    }

    final user = jsonDecode(userString);

    return int.tryParse(user['id'].toString());
  }

  // =====================================
  // GET COMPANY ID
  // =====================================

  static Future<int?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString('user');

    if (userString == null || userString.isEmpty) {
      return null;
    }

    final user = jsonDecode(userString);

    final companyId = user['company_id'] ?? user['employee']?['company_id'];
    return companyId == null ? null : int.tryParse(companyId.toString());
  }

  // =====================================
  // GET HIERARCHY NODE IDS
  // =====================================

static Future<List<int>> getHierarchyNodeIds() async {
  final prefs = await SharedPreferences.getInstance();

  final userString = prefs.getString('user');

  if (userString == null || userString.isEmpty) {
    print('User data not found in SharedPreferences');
    return [];
  }

  final user = jsonDecode(userString);

  final assignments = user['hierarchy_assignments'];

  if (assignments == null || assignments is! List) {
    print('Hierarchy assignments not found');
    return [];
  }

  final List<int> nodeIds = assignments
      .where((item) => item['hierarchy_node_id'] != null)
      .map<int>((item) {
        return int.tryParse(
              item['hierarchy_node_id'].toString(),
            ) ??
            0;
      })
      .where((id) => id > 0)
      .toSet()
      .toList();

  print('Hierarchy Node IDs: $nodeIds');

  return nodeIds;
}

  // =====================================
  // GET SELECTED HIERARCHY NODE ID
  // =====================================

  // static Future<int?> getHierarchyNodeId() async {
  //   final nodeIds = await getHierarchyNodeIds();

  //   if (nodeIds.isEmpty) {
  //     return null;
  //   }

  //   return nodeIds.first;
  // }

  static Future<List<Map<String, dynamic>>>
    getHierarchyNodes() async {

  final prefs = await SharedPreferences.getInstance();

  final userString = prefs.getString('user');

  if (userString == null) return [];

  final user = jsonDecode(userString);

  final assignments = user['hierarchy_assignments'];

  if (assignments is! List) return [];

  return assignments
      .where((item) => item['hierarchy_node'] != null)
      .map<Map<String, dynamic>>((item) {
    return {
      'id': item['hierarchy_node']['id'],
      'name': item['hierarchy_node']['name'],
    };
  }).toList();
}
}
