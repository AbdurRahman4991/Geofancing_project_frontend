
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '/services/attendance_service_api.dart'; 
import '/helpers/device_helper.dart';
import '/helpers/location_helper.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}
class _AttendancePageState extends State<AttendancePage> {
  int _selectedIndex = 0;
  bool isInsideOffice = false;
  bool isCheckedIn = false;
  String statusMessage = "Checking location...";
  Position? currentPosition;

  double? officeLatitude;
  double? officeLongitude;
  double? allowedRadius;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); 
  }  

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } else {
      
      String? geoJson = prefs.getString('geofancing');
      if (geoJson != null) {
        List<dynamic> geofencingList = jsonDecode(geoJson);

        
        if (geofencingList.isNotEmpty) {
          officeLatitude = double.parse(geofencingList[0]['latitude']);
          officeLongitude = double.parse(geofencingList[0]['longitude']);
          allowedRadius = double.parse(geofencingList[0]['radius'].toString());
        }
      }
      if (officeLatitude != null && officeLongitude != null && allowedRadius != null) {
        _checkLocationPermission();
        Timer.periodic(const Duration(seconds: 5), (timer) {
          _getCurrentLocation();
        });
      } else {
        setState(() => statusMessage = "No geofencing data found!");
      }
    }
  }

  
  Future<void> _checkLocationPermission() async {
    LocationPermission permission;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => statusMessage = "Location permission denied");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => statusMessage = "Location permission permanently denied");
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
  Position? position = await LocationHelper.getCurrentLocation();

  if (position == null) {
    setState(() => statusMessage = "⚠️ Unable to get current location");
    return;
  }

  setState(() => currentPosition = position);
  _checkProximity(position);
}

  
  void _checkProximity(Position position) {
  if (officeLatitude == null || officeLongitude == null || allowedRadius == null) {
    setState(() => statusMessage = "Geofence data missing!");
    return;
  }

  double distance = Geolocator.distanceBetween(
    officeLatitude!,
    officeLongitude!,
    position.latitude,
    position.longitude,
  );

  if (distance <= allowedRadius!) {
    setState(() {
      isInsideOffice = true;
      statusMessage = "You are inside the office area.";
    });
  } else {
    setState(() {
      isInsideOffice = false;
      statusMessage = "You are outside the office area!";
    });

    if (isCheckedIn) {
      _autoCheckOut(); 
    }
  }
}

  void _checkIn() async {
  if (currentPosition == null) return;

  setState(() => statusMessage = "⏳ Checking in...");
  String deviceId = await DeviceHelper.getDeviceId();

  final message = await AttendanceApiService.checkIn(
    latitude: currentPosition!.latitude,
    longitude: currentPosition!.longitude,
    deviceId: deviceId, 
  );

  setState(() {
    isCheckedIn = message.toLowerCase().contains("success"); 
    statusMessage = message;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

void _autoCheckOut() async {
  if (currentPosition == null) return;

  setState(() => statusMessage = "⏳ Checking out...");

  final message = await AttendanceApiService.checkOut(
    latitude: currentPosition!.latitude,
    longitude: currentPosition!.longitude,
  );

  setState(() {
    isCheckedIn = false;
    statusMessage = message;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Attendance"),
        backgroundColor: Colors.blue[400],
        centerTitle: true,
      ),

      

      body: Center(
        
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isInsideOffice ? Icons.location_on : Icons.location_off,
                color: isInsideOffice ? Colors.green : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              Text(
                currentPosition != null
                    ? "Lat: ${currentPosition!.latitude.toStringAsFixed(5)}\nLng: ${currentPosition!.longitude.toStringAsFixed(5)}"
                    : "Locating...",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _checkIn, 
                icon: const Icon(Icons.login),
                label: const Text("Check In"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(200, 60),
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: _autoCheckOut,
                icon: const Icon(Icons.logout),
                label: const Text("Check Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(200, 60),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // keeps track of the selected tab
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // change tab
          });
          if (index == 0) {
            Navigator.pushNamed(context, '/');
            } else if (index == 1) {
              Navigator.pushNamed(context, '/profile');
            }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      
    );
  }
}

