import 'dart:io';

class NetworkHelper {

  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');

      if (result.isNotEmpty &&
          result[0].rawAddress.isNotEmpty) {
        return true;
      }

    } catch (e) {
      return false;
    }

    return false;
  }
}