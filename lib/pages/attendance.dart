import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '/helpers/location_helper.dart';
import '../services/location_setting_service.dart';
import '../services/AttendanceManager.dart';


class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() =>
      _AttendancePageState();
}


class _AttendancePageState extends State<AttendancePage> {

  final AttendanceManager attendanceManager =
      AttendanceManager();


  bool isInsideOffice = false;
  bool isCheckedIn = false;

  String statusMessage =
      "Checking location...";

  Position? currentPosition;


  StreamSubscription<Position>? _positionStream;

  StreamSubscription? connectivitySubscription;


  bool _isTrackingStarted = false;



  @override
  void initState() {
    super.initState();

    _initialize();


    connectivitySubscription =
        Connectivity()
            .onConnectivityChanged
            .listen((result) {

      if (!result.contains(
          ConnectivityResult.none)) {

        attendanceManager
            .syncOfflineAttendance();
      }

    });
  }



  Future<void> _initialize() async {

    final prefs =
        await SharedPreferences.getInstance();


    final token =
        prefs.getString('access_token');


    if (token == null || token.isEmpty) {

      if (mounted) {
        Navigator.pushReplacementNamed(
            context,
            '/login'
        );
      }

      return;
    }



    await GeofenceService.syncGeofences();


    await attendanceManager.loadGeofence();



    if (!attendanceManager.hasGeofence) {

      setState(() {

        statusMessage =
            "No geofencing data found!";

      });

      return;
    }



    await _checkLocationPermission();


    attendanceManager
        .syncOfflineAttendance();

  }




  Future<void> _checkLocationPermission() async {


    bool serviceEnabled =
        await Geolocator
            .isLocationServiceEnabled();


    if (!serviceEnabled) {

      await Geolocator
          .openLocationSettings();

      return;
    }



    LocationPermission permission =
        await Geolocator.checkPermission();



    if (permission ==
        LocationPermission.denied) {


      permission =
          await Geolocator.requestPermission();


      if (permission ==
          LocationPermission.denied) {


        setState(() {

          statusMessage =
              "Location permission denied";

        });


        return;
      }
    }



    if (permission ==
        LocationPermission.deniedForever) {


      setState(() {

        statusMessage =
            "Location permission permanently denied";

      });


      return;
    }



    await _getCurrentLocation();


    _startLocationTracking();

  }




  Future<void> _getCurrentLocation() async {


    final position =
        await LocationHelper
            .getCurrentLocation();



    if (position == null) {


      setState(() {

        statusMessage =
            "Unable to get location";

      });


      return;
    }



    setState(() {

      currentPosition =
          position;

    });



    _checkProximity(position);

  }





  void _startLocationTracking() {


    if (_isTrackingStarted) return;


    _isTrackingStarted = true;



    const settings =
        LocationSettings(

      accuracy:
          LocationAccuracy.high,

      distanceFilter:
          10,

    );



    _positionStream =
        Geolocator
            .getPositionStream(
              locationSettings:
                  settings,
            )
            .listen((position) {


      if (!mounted) return;


      setState(() {

        currentPosition =
            position;

      });



      _checkProximity(position);


    });

  }





  void _checkProximity(Position position) {


    final inside =
        attendanceManager
            .isInsideOffice(position);



    setState(() {

      isInsideOffice =
          inside;


      statusMessage =
          inside
              ? "You are inside office area"
              : "You are outside office area";

    });



    if (inside && !isCheckedIn) {

      _checkIn();

    }


    if (!inside && isCheckedIn) {

      _checkOut();

    }

  }







  Future<void> _checkIn() async {


    if (currentPosition == null)
      return;



    final message =
        await attendanceManager
            .checkIn(
              currentPosition!,
            );



    if (!mounted) return;



    setState(() {


      isCheckedIn =
          message
              .toLowerCase()
              .contains("success")
          ||
          message.contains("Offline");


      statusMessage =
          message;

    });



    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content:
            Text(message),
      ),

    );

  }







  Future<void> _checkOut() async {


    if (currentPosition == null)
      return;



    final message =
        await attendanceManager
            .checkOut(
              currentPosition!,
            );



    if (!mounted) return;



    setState(() {


      isCheckedIn =
          false;


      statusMessage =
          message;

    });



    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content:
            Text(message),
      ),

    );

  }






  @override
  void dispose() {

    _positionStream?.cancel();

    connectivitySubscription?.cancel();

    super.dispose();

  }







  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
          Colors.blue[50],


      appBar:
          AppBar(

        title:
            const Text(
              "Attendance",
            ),

        backgroundColor:
            Colors.blue,

        centerTitle:
            true,

      ),



      body:
          Center(

        child:
            Padding(

          padding:
              const EdgeInsets.all(24),


          child:
              Column(

            mainAxisAlignment:
                MainAxisAlignment.center,


            children: [



              Icon(

                isInsideOffice
                    ? Icons.location_on
                    : Icons.location_off,


                size:
                    80,


                color:
                    isInsideOffice
                        ? Colors.green
                        : Colors.red,

              ),



              const SizedBox(
                  height:20),




              Text(

                statusMessage,


                textAlign:
                    TextAlign.center,


                style:
                    const TextStyle(

                  fontSize:
                      16,


                  fontWeight:
                      FontWeight.w500,

                ),

              ),




              const SizedBox(
                  height:30),




              Text(

                currentPosition != null

                    ? 
                    "Lat: ${currentPosition!.latitude.toStringAsFixed(5)}\nLng: ${currentPosition!.longitude.toStringAsFixed(5)}"

                    :

                    "Locating...",


                textAlign:
                    TextAlign.center,

              ),




              const SizedBox(
                  height:40),




              ElevatedButton.icon(

                onPressed:
                    _checkIn,


                icon:
                    const Icon(
                        Icons.login),


                label:
                    const Text(
                        "Check In"),


                style:
                    ElevatedButton.styleFrom(

                  minimumSize:
                      const Size(
                          200,60),

                  backgroundColor:
                      Colors.blue,

                ),

              ),




              const SizedBox(
                  height:15),




              ElevatedButton.icon(

                onPressed:
                    _checkOut,


                icon:
                    const Icon(
                        Icons.logout),


                label:
                    const Text(
                        "Check Out"),


                style:
                    ElevatedButton.styleFrom(

                  minimumSize:
                      const Size(
                          200,60),


                  backgroundColor:
                      Colors.redAccent,
                ),

              ),
            ],

          ),

        ),

      ),

    );

  }

}