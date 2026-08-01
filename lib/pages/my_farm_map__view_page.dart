import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MyFarmMapViewPage extends StatefulWidget {
  const MyFarmMapViewPage({super.key});

  @override
  State<MyFarmMapViewPage> createState() => _MyFarmMapViewPageState();
}


class _MyFarmMapViewPageState extends State<MyFarmMapViewPage> {
  GoogleMapController? mapController;

  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  List<dynamic> geofences = [];

  @override
  void initState() {
    super.initState();
    loadGeofences();();
  }

  
  Future<void> loadGeofences() async {
  final prefs = await SharedPreferences.getInstance();

  final json = prefs.getString("geofancing");

  if (json == null) return;

  geofences = jsonDecode(json);

  _loadGeofences();

  setState(() {});
}

  void _loadGeofences() {
    for (int i = 0; i < geofences.length; i++) {
      final item = geofences[i];

      final lat = double.parse(item["latitude"].toString());
      final lng = double.parse(item["longitude"].toString());
      final radius =
          double.parse(item["radius"].toString());

      _markers.add(
        Marker(
          markerId: MarkerId("marker_$i"),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: item["firm_name"],
            snippet: "Radius : ${item["radius"]} Meter",
          ),
        ),
      );

      _circles.add(
        Circle(
          circleId: CircleId("circle_$i"),
          center: LatLng(lat, lng),
          radius: radius,
          fillColor: Colors.green.withOpacity(0.20),
          strokeColor: Colors.green,
          strokeWidth: 2,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (geofences.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Farm Locations"),
        ),
        body: const Center(
          child: Text("No Geofence Found"),
        ),
      );
    }

    final first = geofences.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Farm Locations"),
        backgroundColor: Colors.green,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            double.parse(first["latitude"].toString()),
            double.parse(first["longitude"].toString()),
          ),
          zoom: 14,
        ),
        markers: _markers,
        circles: _circles,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }
}