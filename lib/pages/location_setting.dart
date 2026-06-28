import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_setting_service.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeofenceMapPage extends StatefulWidget {
   final dynamic geofence;
  const GeofenceMapPage({super.key, this.geofence});

  @override
  State<GeofenceMapPage> createState() => _GeofenceMapPageState();
}

class _GeofenceMapPageState extends State<GeofenceMapPage> {
  GoogleMapController? mapController;

  LatLng? selectedLocation;


  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();
  final TextEditingController radiusController =
      TextEditingController(text: "500");

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    checkAuth();
    
  }
// Future<void> checkAuth() async {
//   final prefs = await SharedPreferences.getInstance();
//   final token = prefs.getString('access_token');

//   if (token == null || token.isEmpty) {
//     if (!mounted) return;
//     Navigator.pushReplacementNamed(context, '/login');
//     return;
//   }

//   getCurrentLocation();
// }
  int? geofenceId;

Future<void> checkAuth() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null || token.isEmpty) {
    Navigator.pushReplacementNamed(context, '/login');
    return;
  }

  if (widget.geofence != null) {
    final data = widget.geofence;

    geofenceId = data["id"];

    final lat = double.parse(data["latitude"].toString());
    final lng = double.parse(data["longitude"].toString());

    setState(() {
      selectedLocation = LatLng(lat, lng);

      latController.text = lat.toString();
      lngController.text = lng.toString();
      radiusController.text = data["radius"].toString();
    });
  } else {
    getCurrentLocation();
  }
}
  Future<void> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      selectedLocation = LatLng(position.latitude, position.longitude);
      latController.text = position.latitude.toString();
      lngController.text = position.longitude.toString();
    });
  }

  void onMapTap(LatLng location) {
    setState(() {
      selectedLocation = location;
      latController.text = location.latitude.toString();
      lngController.text = location.longitude.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Geofence Map")),
      body: selectedLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: selectedLocation!,
                      zoom: 16,
                    ),
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                    onTap: onMapTap,
                    markers: {
                      Marker(
                        markerId: const MarkerId("selected"),
                        position: selectedLocation!,
                      )
                    },
                    circles: {
                      Circle(
                        circleId: const CircleId("radius"),
                        center: selectedLocation!,                        
                        fillColor: Colors.blue.withOpacity(0.2),
                        strokeColor: Colors.blue,
                        strokeWidth: 2,
                      )
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: latController,
                        decoration: const InputDecoration(
                          labelText: "Latitude",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: lngController,
                        decoration: const InputDecoration(
                          labelText: "Longitude",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: radiusController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Radius (meter)",
                        ),                     
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {

  final userId = await AuthService.getUserId();
  final companyId = await AuthService.getCompanyId();

  bool success;

  if (widget.geofence == null) {

    success = await GeofenceService.createGeofence(
      companyId: companyId!,
      userId: userId!,
      latitude: double.parse(latController.text),
      longitude: double.parse(lngController.text),
      radius: double.parse(radiusController.text),
    );

  } else {

    success = await GeofenceService.updateGeofence(
      id: geofenceId!,
      companyId: companyId!,
      userId: userId!,
      latitude: double.parse(latController.text),
      longitude: double.parse(lngController.text),
      radius: double.parse(radiusController.text),
    );

  }

  if(success){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.geofence == null
              ? "Geofence Created"
              : "Geofence Updated",
        ),
      ),
    );

    Navigator.pop(context, true);

  }else{

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Operation Failed"),
      ),
    );

  }

},
                          // onPressed: () async {
                          //   final userId = await AuthService.getUserId();
                          //   final companyId = await AuthService.getCompanyId();

                          //     if (userId == null || companyId == null) {
                          //       ScaffoldMessenger.of(context).showSnackBar(
                          //         const SnackBar(
                          //           content: Text("User information not found"),
                          //         ),
                          //       );
                          //       return;
                          //     }

                          //     bool success = await GeofenceService.createGeofence(
                          //       companyId: companyId,
                          //       userId: userId,
                          //       latitude: double.parse(latController.text),
                          //       longitude: double.parse(lngController.text),
                          //       radius: double.parse(radiusController.text),
                          //     );

                          //     if (success) {
                          //       ScaffoldMessenger.of(context).showSnackBar(
                          //         const SnackBar(
                          //           content: Text("Geofence Created Successfully"),
                          //         ),
                          //       );
                          //     } else {
                          //       ScaffoldMessenger.of(context).showSnackBar(
                          //         const SnackBar(
                          //           content: Text("Failed to Create Geofence"),
                          //         ),
                          //       );
                          //     }
                          //   },
                            // child: const Text("Save Geofence"),
                            child: Text(
                              widget.geofence == null
                                  ? "Save Geofence"
                                  : "Update Geofence",
                            ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}