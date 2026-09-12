// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '/services/login_service_api.dart';
// import '/helpers/device_helper.dart';
// import '/helpers/location_helper.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/background_location_service.dart';

// class Login extends StatefulWidget {
   
//   @override
//   _LoginState createState() => _LoginState();
// }
// class _LoginState extends State<Login> {
//   int _selectedIndex = 0;
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _deviceIdController = TextEditingController();
//   final _latitudeController = TextEditingController();
//   final _longitudeController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadDeviceInfo();
//     _getCurrentLocation();
//   }
//   Future<void> _loadDeviceInfo() async {
//     String deviceId = await DeviceHelper.getDeviceId();
//     setState(() {
//       _deviceIdController.text = deviceId;
//     });
//   }

//   Future<void> _getCurrentLocation() async {
//   var position = await LocationHelper.getCurrentLocation();
//   if (position != null) {
//     setState(() {
//       _latitudeController.text = position.latitude.toString();
//       _longitudeController.text = position.longitude.toString();
//     });
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Colors.blue[400]!,
//               Colors.blue[300]!,
//               Colors.blue[100]!,
//             ],
//           ),
//         ),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               const SizedBox(height: 40),
//               const Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("Login",
//                         style: TextStyle(fontSize: 30, color: Colors.white)),
//                     Text("Welcome",
//                         style: TextStyle(fontSize: 10, color: Colors.white)),
//                   ],
//                 ),
//               ),
//               Container(
//                 height: MediaQuery.of(context).size.height * 0.75,
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(60),
//                     topRight: Radius.circular(60),
//                   ),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       children: <Widget>[
//                         const SizedBox(height: 40),
//                         TextFormField(
//                           controller: _nameController,
//                           decoration: const InputDecoration(
//                             labelText: "Employee ID",
//                             border: OutlineInputBorder(),
//                           ),
//                           validator: (value) =>
//                               value == null || value.isEmpty
//                                   ? 'Please enter Employee ID'
//                                   : null,
//                         ),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _phoneController,
//                           keyboardType: TextInputType.phone,
//                           inputFormatters: [
//                             LengthLimitingTextInputFormatter(11),
//                             FilteringTextInputFormatter.digitsOnly,
//                           ],
//                           decoration: const InputDecoration(
//                             labelText: "Phone",
//                             border: OutlineInputBorder(),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter phone number';
//                             } else if (value.length != 11) {
//                               return 'Phone number must be 11 digits';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _deviceIdController,
//                           //readOnly: true,
//                           decoration: const InputDecoration(
//                             labelText: "Device ID",
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _latitudeController,
//                           readOnly: true,
//                           decoration: const InputDecoration(
//                             labelText: "Latitude",
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _longitudeController,
//                           readOnly: true,
//                           decoration: const InputDecoration(
//                             labelText: "Longitude",
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(minimumSize: const Size(200, 60)),
//                           onPressed: () async {
//                             if (_formKey.currentState!.validate()) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content: Text("Logging in...")),
//                               );

//                               String employeeId = _nameController.text.trim();
//                               String phone = _phoneController.text.trim();
//                               String deviceId = _deviceIdController.text.trim();
//                               String latitude = _latitudeController.text.trim();
//                               String longitude = _longitudeController.text.trim();

//                               // ✅ API Call
//                               String? result = await ApiService.loginUser(
//                                 employeeId,
//                                 phone,
//                                 deviceId,
//                                 latitude,
//                                 longitude,
//                               );

                             
//                               // if (result != null && result.toLowerCase().contains('success')) {
//                               //   ScaffoldMessenger.of(context).showSnackBar(
//                               //     const SnackBar(
//                               //       content: Text("Login successful!"),
//                               //       backgroundColor: Colors.green,
//                               //     ),
//                               //   );

                                
//                               //   await Future.delayed(const Duration(seconds: 1));
//                               //   Navigator.pushReplacementNamed(context, '/HomePage()');
//                              if (result != null && result.toLowerCase().contains('success')) {

//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text("Login successful!"),
//                                     backgroundColor: Colors.green,
//                                   ),
//                                 );

//                                 await BackgroundLocationService.initializeService();

//                                 await Future.delayed(const Duration(seconds: 1));

//                                 Navigator.pushReplacementNamed(context, '/home');


//                               } else {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                     content: Text(result ?? "Login failed"),
//                                     backgroundColor: Colors.red,
//                                   ),
//                                 );
//                               }
//                             }
//                           },
//                           child: const Text("Login"),
//                         ),
//                         const SizedBox(height: 20),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.pushNamed(context, '/register');
//                           },
//                           child: const Text(
//                             "Signup",
//                             style: TextStyle(color: Colors.blue),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       // bottomNavigationBar: BottomNavigationBar(
//       //   currentIndex: _selectedIndex, // keeps track of the selected tab
//       //   onTap: (index) {
//       //     setState(() {
//       //       _selectedIndex = index; // change tab
//       //     });
//       //     if (index == 0) {
//       //       Navigator.pushNamed(context, '/');
//       //       } else if (index == 1) {
//       //         Navigator.pushNamed(context, '/profile');
//       //       }
//       //   },
//       //   items: const [
//       //     BottomNavigationBarItem(
//       //       icon: Icon(Icons.home),
//       //       label: 'Home',
//       //     ),
//       //     BottomNavigationBarItem(
//       //       icon: Icon(Icons.person),
//       //       label: 'Profile',
//       //     ),
//       //     BottomNavigationBarItem(
//       //       icon: Icon(Icons.settings),
//       //       label: 'Settings',
//       //     ),
//       //   ],
//       // ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/services/login_service_api.dart';
import '/helpers/device_helper.dart';
import '/helpers/location_helper.dart';
import '../services/background_location_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();

  // Email
  final TextEditingController _emailController =
      TextEditingController();

  // Password
  final TextEditingController _passwordController =
      TextEditingController();

  // Device ID
  final TextEditingController _deviceIdController =
      TextEditingController();

  // Latitude
  final TextEditingController _latitudeController =
      TextEditingController();

  // Longitude
  final TextEditingController _longitudeController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _loadDeviceInfo();
    _getCurrentLocation();
  }

  // Get Device ID
  Future<void> _loadDeviceInfo() async {
    final String deviceId = await DeviceHelper.getDeviceId();

    if (!mounted) return;

    setState(() {
      _deviceIdController.text = deviceId;
    });
  }

  // Get Current Location
  Future<void> _getCurrentLocation() async {
    final position = await LocationHelper.getCurrentLocation();

    if (position != null && mounted) {
      setState(() {
        _latitudeController.text =
            position.latitude.toString();

        _longitudeController.text =
            position.longitude.toString();
      });
    }
  }

  // Login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String email =
          _emailController.text.trim();

      final String password =
          _passwordController.text;

      final String deviceId =
          _deviceIdController.text.trim();

      final String latitude =
          _latitudeController.text.trim();

      final String longitude =
          _longitudeController.text.trim();

      // API Call
      final String? result =
          await ApiService.loginUser(
        email,
        password,
        deviceId,
        latitude,
        longitude,
      );

      if (!mounted) return;

      if (result != null &&
          result.toLowerCase().contains('success')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful!"),
            backgroundColor: Colors.green,
          ),
        );

        // Start background location service
        await BackgroundLocationService
            .initializeService();

        await Future.delayed(
          const Duration(seconds: 1),
        );

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result ?? "Login failed",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Something went wrong: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _deviceIdController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue[400]!,
              Colors.blue[300]!,
              Colors.blue[100]!,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Welcome",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // =========================
                      // Email
                      // =========================
                      TextFormField(
                        controller: _emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        decoration:
                            const InputDecoration(
                          labelText: "Email",
                          hintText:
                              "Enter your email",
                          border:
                              OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter email';
                          }

                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // =========================
                      // Password
                      // =========================
                      TextFormField(
                        controller:
                            _passwordController,
                        obscureText:
                            _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          hintText:
                              "Enter your password",
                          border:
                              const OutlineInputBorder(),
                          prefixIcon:
                              const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Please enter password';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // =========================
                      // Device ID
                      // =========================
                      TextFormField(
                        controller:
                            _deviceIdController,
                        readOnly: true,
                        decoration:
                            const InputDecoration(
                          labelText: "Device ID",
                          border:
                              OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.phone_android),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =========================
                      // Latitude
                      // =========================
                      TextFormField(
                        controller:
                            _latitudeController,
                        readOnly: true,
                        decoration:
                            const InputDecoration(
                          labelText: "Latitude",
                          border:
                              OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.location_on),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =========================
                      // Longitude
                      // =========================
                      TextFormField(
                        controller:
                            _longitudeController,
                        readOnly: true,
                        decoration:
                            const InputDecoration(
                          labelText: "Longitude",
                          border:
                              OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.location_on),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // =========================
                      // Login Button
                      // =========================
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style:
                                  ElevatedButton.styleFrom(
                                minimumSize:
                                    const Size(200, 60),
                              ),
                              onPressed: _login,
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),

                      const SizedBox(height: 20),

                      // =========================
                      // Signup
                      // =========================
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/register',
                          );
                        },
                        child: const Text(
                          "Don't have an account? Signup",
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}