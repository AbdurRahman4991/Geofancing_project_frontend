import 'package:flutter/material.dart';
import '../services/location_setting_list_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/location_setting.dart';

class LocationSettingList extends StatefulWidget {
  const LocationSettingList({super.key});
 
  @override
  State<LocationSettingList> createState() => _LocationSettingListState();
}

class _LocationSettingListState extends State<LocationSettingList> {
  late Future<List<dynamic>> futureLocations;

  @override
  void initState() {
    super.initState();
    futureLocations = LocationSettingListService.getGeofences();
    checkAuth();
  }

    Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

   // getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Settings"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureLocations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final locations = snapshot.data!;

          if (locations.isEmpty) {
            return const Center(
              child: Text("No Location Found"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final item = locations[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.location_on),
                  ),
                  title: Text(
                     item["company"]?["company_name"] ?? " ",
                    
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Latitude : ${item["latitude"]}"),
                        Text("Longitude : ${item["longitude"]}"),
                        Text("Radius : ${item["radius"]} m"),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result =  await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GeofenceMapPage(
                                geofence: item,
                              ),
                            ),
                          );

                          if (result == true) {
                            setState(() {
                              futureLocations = LocationSettingListService.getGeofences();
                            });
                          }                       
                      } 
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),                     
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GeofenceMapPage(),
            ),
          );

          if (result == true) {
            setState(() {
              futureLocations = LocationSettingListService.getGeofences();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}