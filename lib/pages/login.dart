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
