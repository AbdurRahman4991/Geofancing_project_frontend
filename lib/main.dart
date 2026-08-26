import 'package:flutter/material.dart';
import '/pages/attendance_history.dart';
import 'pages/register.dart';
import 'pages/login.dart';
import 'pages/attendance.dart';
import 'pages/location_setting.dart';
import 'services/background_location_service.dart';
import 'pages/home.dart';
import 'pages/location_setting_list.dart';
import 'splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/system_check_page.dart';
import 'pages/my_farm_map__view_page.dart'; 
import 'services/connectivity_service.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();


  await Hive.initFlutter();

  await Hive.openBox('location_queue');
  await Hive.openBox('attendance_offline');
  ConnectivityService.start();


  await BackgroundLocationService.initializeService();


  runApp(
    const MyApp()
  );
}
class MyApp extends StatelessWidget {
  
  const MyApp({super.key});    
  @override
  Widget build(BuildContext context) {   
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Geofance',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      // Handle named routes
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        switch (uri.path) {
          case '/register':
            return MaterialPageRoute(builder: (_) =>  Register());
          case '/login':
            return MaterialPageRoute(builder: (_) => Login());
          case '/syste-configure':
          return MaterialPageRoute(builder: (_) => const SystemCheckPage());
          case '/location-setting':
            return MaterialPageRoute(builder: (_) => GeofenceMapPage());
          case '/myfarm-mapview':            
            return MaterialPageRoute(builder: (_) => MyFarmMapViewPage(            
            ));
          case '/location-setting-list':
            return MaterialPageRoute(builder: (_) => LocationSettingList() );
          case '/attendance':                  
            return MaterialPageRoute(builder: (_) => const AttendancePage());
          case '/attendance-history':
            return MaterialPageRoute(builder: (_) => AttendanceHistory());
          default:
            return MaterialPageRoute(builder: (_) => const HomePage());
        }
      },
    );
  }
}