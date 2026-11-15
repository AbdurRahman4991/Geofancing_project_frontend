import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../services/location_setting_service.dart';
import '../services/auth_service.dart';

class GeofenceMapPage extends StatefulWidget {
  final dynamic geofence;

  const GeofenceMapPage({
    super.key,
    this.geofence,
  });

  @override
  State<GeofenceMapPage> createState() =>
      _GeofenceMapPageState();
}

class _GeofenceMapPageState extends State<GeofenceMapPage> {
  GoogleMapController? mapController;

  LatLng? selectedLocation;

  File? selectedImage;

  String? imageUrl;

  int? geofenceId;



  bool isSaving = false;
  bool isLoading = true;

  List<Map<String, dynamic>> hierarchyNodes = [];

int? selectedHierarchyNodeId;

  final TextEditingController firmNameController =
      TextEditingController();

  final TextEditingController latController =
      TextEditingController();

  final TextEditingController lngController =
      TextEditingController();

  final TextEditingController radiusController =
      TextEditingController(text: "100");

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController hierarchyNodeController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    initializePage();
  }

  // =====================================
  // INITIALIZE PAGE
  // =====================================

  Future<void> initializePage() async {
  await checkAuth();

  if (!mounted) return;

  // Load Hierarchy Node IDs
  await loadHierarchyNodes();

  if (!mounted) return;

  if (widget.geofence != null) {
    loadGeofenceData();
  } else {
    await getCurrentLocation();
  }

  if (mounted) {
    setState(() {
      isLoading = false;
    });
  }
}

Future<void> loadHierarchyNodes() async {
  try {
    final nodes = await AuthService.getHierarchyNodes();

    if (!mounted) return;

    setState(() {
      hierarchyNodes = nodes;

      if (widget.geofence != null) {
        selectedHierarchyNodeId = int.tryParse(
          widget.geofence['hierarchy_node_id'].toString(),
        );
      } else if (nodes.isNotEmpty) {
        selectedHierarchyNodeId =
            int.tryParse(nodes.first['id'].toString());
      }
    });

    print('========== HIERARCHY NODES ==========');
    print('Nodes: $hierarchyNodes');
    print('Selected ID: $selectedHierarchyNodeId');
    print('=====================================');

  } catch (e) {
    print('Hierarchy Loading Error: $e');
  }
}

  // =====================================
  // AUTH CHECK
  // =====================================

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // =====================================
  // LOAD EXISTING GEOFENCE
  // =====================================

  void loadGeofenceData() {
    final data = widget.geofence;

    geofenceId = int.tryParse(data["id"].toString());

    final lat = double.tryParse(
      data["latitude"].toString(),
    );

    final lng = double.tryParse(
      data["longitude"].toString(),
    );

    selectedHierarchyNodeId = data["hierarchy_node_id"] == null
        ? null
        : int.tryParse(data["hierarchy_node_id"].toString());

    if (selectedHierarchyNodeId != null) {
      hierarchyNodeController.text =
          selectedHierarchyNodeId.toString();
    }

    if (lat != null && lng != null) {
      selectedLocation = LatLng(lat, lng);

      latController.text = lat.toString();
      lngController.text = lng.toString();
    }

    radiusController.text =
        data["radius"]?.toString() ?? "100";

    firmNameController.text =
        data["firm_name"]?.toString() ?? "";

    addressController.text =
        data["address"]?.toString() ?? "";

    imageUrl = data["image_url"]?.toString();
  }

  // =====================================
  // CURRENT LOCATION
  // =====================================

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        showMessage("Please enable location service.");
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showMessage("Location permission denied.");
        return;
      }

      Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        selectedLocation = LatLng(
          position.latitude,
          position.longitude,
        );

        latController.text =
            position.latitude.toString();

        lngController.text =
            position.longitude.toString();
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          selectedLocation!,
          16,
        ),
      );
    } catch (e) {
      showMessage("Unable to get current location: $e");
    }
  }

  // =====================================
  // MAP TAP
  // =====================================

  void onMapTap(LatLng location) {
    setState(() {
      selectedLocation = location;

      latController.text =
          location.latitude.toString();

      lngController.text =
          location.longitude.toString();
    });
  }

  // =====================================
  // TAKE PHOTO
  // =====================================

  Future<void> takePhoto() async {
    try {
      final picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      showMessage("Camera Error: $e");
    }
  }

  // =====================================
  // HIERARCHY NODE CHANGE
  // =====================================

  void onHierarchyNodeChanged(String value) {
    setState(() {
      selectedHierarchyNodeId = int.tryParse(value.trim());
    });
  }

  // =====================================
  // SAVE / UPDATE GEOFENCE
  // =====================================

  Future<void> saveGeofence() async {
    if (isSaving) return;

    FocusScope.of(context).unfocus();

    // USER ID
    final userId = await AuthService.getUserId();

    // COMPANY ID
    final companyId = await AuthService.getCompanyId();

    if (!mounted) return;

    if (userId == null || companyId == null) {
      showMessage(
        "User or Company information not found. Please login again.",
      );
      return;
    }

    // HIERARCHY VALIDATION
    final hierarchyNodeId = selectedHierarchyNodeId;

    if (hierarchyNodeId == null) {
      showMessage('Please select Hierarchy Node.');
      return;
    }

    selectedHierarchyNodeId = hierarchyNodeId;

    // FIRM NAME VALIDATION
    if (firmNameController.text.trim().isEmpty) {
      showMessage("Please enter Firm Name.");
      return;
    }

    // ADDRESS VALIDATION
    if (addressController.text.trim().isEmpty) {
      showMessage("Please enter Address.");
      return;
    }

    // LOCATION VALIDATION
    if (selectedLocation == null) {
      showMessage("Please select Location on Map.");
      return;
    }

    // RADIUS VALIDATION
    final radius = double.tryParse(
      radiusController.text.trim(),
    );

    if (radius == null || radius <= 0) {
      showMessage("Please enter valid Radius.");
      return;
    }

    setState(() {
      isSaving = true;
    });

    String? errorMessage;

    try {
      if (widget.geofence == null) {
        // =================================
        // CREATE GEOFENCE
        // =================================

        errorMessage =
            await GeofenceService.createGeofence(
          companyId: companyId,
          userId: userId,
          hierarchyNodeId: hierarchyNodeId,
          firmName: firmNameController.text.trim(),
          address: addressController.text.trim(),
          latitude: selectedLocation!.latitude,
          longitude: selectedLocation!.longitude,
          radius: radius,
          image: selectedImage,
        );
      } else {
        // =================================
        // UPDATE GEOFENCE
        // =================================

        if (geofenceId == null) {
          showMessage("Geofence ID not found.");
          return;
        }

        errorMessage =
            await GeofenceService.updateGeofence(
          id: geofenceId!,
          companyId: companyId,
          userId: userId,
          hierarchyNodeId: hierarchyNodeId,
          firmName: firmNameController.text.trim(),
          address: addressController.text.trim(),
          latitude: selectedLocation!.latitude,
          longitude: selectedLocation!.longitude,
          radius: radius,
          image: selectedImage,
        );
      }

      if (!mounted) return;

      if (errorMessage == null) {
        showMessage(
          widget.geofence == null
              ? "Location Saved Successfully"
              : "Location Updated Successfully",
        );

        Navigator.pop(context, true);
      } else {
        showMessage(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;

      showMessage("Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // =====================================
  // SNACKBAR
  // =====================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================
  // DISPOSE
  // =====================================

  @override
  void dispose() {
    firmNameController.dispose();
    latController.dispose();
    lngController.dispose();
    radiusController.dispose();
    addressController.dispose();
    hierarchyNodeController.dispose();

    mapController?.dispose();

    super.dispose();
  }

  // =====================================
  // BUILD UI
  // =====================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.geofence == null
              ? "Create Geofence"
              : "Update Geofence",
        ),
        actions: [
          IconButton(
            onPressed: getCurrentLocation,
            icon: const Icon(Icons.my_location),
            tooltip: "Current Location",
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : selectedLocation == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Location not available."),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: getCurrentLocation,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // =================================
                    // GOOGLE MAP
                    // =================================

                    Expanded(
                      flex: 5,
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
                            markerId:
                                const MarkerId("selected"),
                            position: selectedLocation!,
                            infoWindow: const InfoWindow(
                              title: "Selected Location",
                            ),
                          ),
                        },

                        circles: {
                          Circle(
                            circleId:
                                const CircleId("radius"),
                            center: selectedLocation!,
                            radius: double.tryParse(
                                  radiusController.text,
                                ) ??
                                100,
                            fillColor:
                                Colors.blue.withOpacity(0.2),
                            strokeColor: Colors.blue,
                            strokeWidth: 2,
                          ),
                        },

                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                      ),
                    ),

                    // =================================
                    // FORM
                    // =================================

                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Geofence Information",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // FIRM NAME

                            TextField(
                              controller: firmNameController,
                              decoration: const InputDecoration(
                                labelText: "Market / Firm Name",
                                prefixIcon: Icon(Icons.store),
                                border: OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // HIERARCHY NODE ID

                          DropdownButtonFormField<int>(
  value: hierarchyNodes.any(
    (node) =>
        int.tryParse(node['id'].toString()) ==
        selectedHierarchyNodeId,
  )
      ? selectedHierarchyNodeId
      : null,

  isExpanded: true,

  decoration: const InputDecoration(
    labelText: 'Select Hierarchy Node',
    prefixIcon: Icon(Icons.account_tree),
    border: OutlineInputBorder(),
  ),

  hint: const Text('Select Hierarchy Node'),

  items: hierarchyNodes.map((node) {
    return DropdownMenuItem<int>(
      value: int.parse(node['id'].toString()),
      child: Text(node['name'].toString()),
    );
  }).toList(),

  onChanged: (value) {
    setState(() {
      selectedHierarchyNodeId = value;
    });
  },
),

                            const SizedBox(height: 12),

                            // ADDRESS

                            TextField(
                              controller: addressController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: "Address",
                                hintText: "Enter Customer Address",
                                prefixIcon:
                                    Icon(Icons.location_on),
                                border: OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // LATITUDE

                            TextField(
                              controller: latController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: "Latitude",
                                prefixIcon: Icon(Icons.place),
                                border: OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // LONGITUDE

                            TextField(
                              controller: lngController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: "Longitude",
                                prefixIcon: Icon(Icons.place),
                                border: OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // RADIUS

                            TextField(
                              controller: radiusController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: "Radius (Meter)",
                                prefixIcon: Icon(Icons.radar),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) {
                                setState(() {});
                              },
                            ),

                            const SizedBox(height: 16),

                            // CAMERA BUTTON

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: takePhoto,
                                icon: const Icon(
                                  Icons.camera_alt,
                                ),
                                label: const Text(
                                  "Take Market / Office Photo",
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // SELECTED IMAGE

                            if (selectedImage != null)
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(10),
                                child: Image.file(
                                  selectedImage!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (imageUrl != null &&
                                imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(10),
                                child: Image.network(
                                  imageUrl!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stack) {
                                    return const Text(
                                      "Image Load Failed",
                                    );
                                  },
                                ),
                              ),

                            const SizedBox(height: 20),

                            // SAVE BUTTON

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed:
                                    isSaving ? null : saveGeofence,
                                icon: isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  isSaving
                                      ? "Please Wait..."
                                      : widget.geofence == null
                                          ? "Save Location"
                                          : "Update Location",
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
