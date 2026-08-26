import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'employee_location_service.dart';

class ConnectivityService {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static void start() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      (results) async {
        final hasInternet =
            results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.ethernet);

        if (hasInternet) {
          print('Internet restored. Syncing locations...');

          await EmployeeLocationService.syncIfInternetAvailable();
        }
      },
    );
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}