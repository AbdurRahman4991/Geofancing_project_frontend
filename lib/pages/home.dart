
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  String userName = "";
  String userEmail = "";
  String nearestOfficeName = "";
  double nearestDistance = 0;  
  double? nearestLat;
  double? nearestLng;

  @override
void initState() {
  super.initState();
  loadUser();
  loadNearestOffice();

}

Future<void> loadUser() async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = prefs.getString('user');

  if (userJson != null) {
    final user = jsonDecode(userJson);

    setState(() {
      userName = user['name'] ?? "";
      userEmail = user['email'] ?? "";
    });
  }
}


Future<void> loadNearestOffice() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    return;
  }

  LocationPermission permission =
      await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return;
  }

  Position position = await Geolocator.getCurrentPosition();

  final prefs = await SharedPreferences.getInstance();
  final geoJson = prefs.getString("geofancing");

  if (geoJson == null) return;

  final offices = jsonDecode(geoJson);

  double minDistance = double.infinity;
  Map<String, dynamic>? nearestOffice;

  for (final office in offices) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      double.parse(office["latitude"].toString()),
      double.parse(office["longitude"].toString()),
    );

    if (distance < minDistance) {
      minDistance = distance;
      nearestOffice = office;
    }
  }

  if (nearestOffice != null) {
    print("Nearest Office Map: $nearestOffice");
  print("Firm Name: ${nearestOffice["firm_name"]}");
    setState(() {
  nearestOfficeName =
      nearestOffice!["firm_name"] ??
      nearestOffice["user"]?["employee"]?["name"] ??
      "Office";

  nearestDistance = minDistance;

  nearestLat = double.parse(
    nearestOffice["latitude"].toString(),
  );

  nearestLng = double.parse(
    nearestOffice["longitude"].toString(),
  );
});
  }
}

Future<void> openGoogleMap() async {
  if (nearestLat == null || nearestLng == null) return;

  final Uri url = Uri.parse(
    "https://www.google.com/maps/dir/?api=1&destination=$nearestLat,$nearestLng",
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }
}

  Widget _homeMenu(
  BuildContext context,
  String title,
  IconData icon,
  String route,
) {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 50,
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Get Current Location"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
             
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : "A",
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            
            ListTile(
              title: const Text("Register"),
              leading: const Icon(Icons.app_registration_rounded),
              onTap: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
            ListTile(
              title: const Text("Login"),
              leading: const Icon(Icons.login),
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),

            ListTile(
              title: const Text("System Configure"),
              leading: const Icon(Icons.settings_applications),
              onTap: () {
                Navigator.pushNamed(context, '/syste-configure');
              },
            ),


                        
            ListTile(
              title: const Text("Logout"),
              leading: const Icon(Icons.logout),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('access_token');
                await prefs.remove('geofancing'); // optional: remove geofencing data

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false, // remove all previous routes
                  );
                }
              },
            ),
          ],
        ),
      ),
     
      
      // body: const Center(
        
      //   child: Text(" Hello "),
      // ),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              Card(
          elevation: 4,
          child: InkWell(
            onTap: openGoogleMap,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(
                Icons.location_city,
                color: Colors.blue,
              ),
              title: Text(
                nearestOfficeName.isEmpty
                    ? "Nearest Office"
                    : nearestOfficeName,
              ),
              subtitle: Text(
                nearestDistance == 0
                    ? "Calculating..."
                    : "${nearestDistance.toStringAsFixed(0)} meters away",
              ),
              trailing: const Icon(
                Icons.directions,
                color: Colors.green,
              ),
            ),
          ),
        ),

      const SizedBox(height: 15),

      Expanded(
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [

            _homeMenu(
              context,
              "New Farm",
              Icons.location_searching,
              '/location-setting',
            ),

            _homeMenu(
              context,
              "Farms",
              Icons.map,
              '/location-setting-list',
            ),

            _homeMenu(
              context,
              "Checkin/out",
              Icons.fact_check,
              '/attendance',
            ),

            _homeMenu(
              context,
              "Checkin History",
              Icons.history,
              '/attendance-history',
            ),
          ],
        ),
      ),
    ],
  ),
),

    );
  }
}