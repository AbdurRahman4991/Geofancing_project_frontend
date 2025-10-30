import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool isInsideOffice = false;
  bool isCheckedIn = false;
  String statusMessage = "Checking location...";
  Position? currentPosition;

  // ✅ অফিসের নির্দিষ্ট লোকেশন সেট করো
  final double officeLatitude = 23.8103; // উদাহরণস্বরূপ: ঢাকা
  final double officeLongitude = 90.4125;
  final double allowedRadius = 7000; // 100 মিটার এর মধ্যে হলে চেক-ইন সম্ভব

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _getCurrentLocation();
    });
  }

  // ✅ লোকেশন পারমিশন চেক
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

  // ✅ বর্তমান লোকেশন পাওয়া
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => currentPosition = position);
      _checkProximity(position);
    } catch (e) {
      setState(() => statusMessage = "Error getting location: $e");
    }
  }

  // ✅ অফিস এলাকায় আছি কিনা চেক
  void _checkProximity(Position position) {
    double distance = Geolocator.distanceBetween(
      officeLatitude,
      officeLongitude,
      position.latitude,
      position.longitude,
    );

    if (distance <= allowedRadius) {
      setState(() {
        isInsideOffice = true;
        statusMessage = "You are inside the office area.";
      });
    } else {
      setState(() {
        isInsideOffice = false;
        statusMessage = "You are outside the office area!";
      });

      // বাইরে গেলে Auto Check-out
      if (isCheckedIn) {
        _autoCheckOut();
      }
    }
  }

  // ✅ Check-in ফাংশন
  void _checkIn() {
    setState(() {
      isCheckedIn = true;
      statusMessage = "✅ Checked in successfully!";
    });
  }

  // ✅ Auto Check-out ফাংশন
  void _autoCheckOut() {
    setState(() {
      isCheckedIn = false;
      statusMessage = "⚠️ You left the office area. Auto checked-out!";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Auto Checked Out due to leaving area."),
        backgroundColor: Colors.red,
      ),
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
                onPressed: isInsideOffice && !isCheckedIn
                    ? _checkIn
                    : null, // ✅ কেবল অফিস এলাকায় থাকলে সক্রিয়
                icon: const Icon(Icons.login),
                label: Text(isCheckedIn ? "Checked In" : "Check In"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckedIn ? Colors.grey : Colors.blue,
                  minimumSize: const Size(200, 60),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: isCheckedIn ? _autoCheckOut : null,
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
    );
  }
}
