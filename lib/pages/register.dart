// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '/services/register_service_api.dart'; 

// class Register extends StatefulWidget {
//   @override
//   _RegisterState createState() => _RegisterState();
// }

// class _RegisterState extends State<Register> {
//   int _selectedIndex = 0;
//   final _formKey = GlobalKey<FormState>();
//   final _employeeIdController = TextEditingController();
//   final _phoneController = TextEditingController();

//   bool _isLoading = false; // 👈 Loading state

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(colors: [
//             Colors.blue[400]!,
//             Colors.blue[200]!,
//             Colors.blue[100]!,
//           ]),
//         ),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               const SizedBox(height: 20),
//               Padding(
//                 padding: const EdgeInsets.only(left: 10.0),
//                 child: IconButton(
//                   icon: const Icon(Icons.arrow_back,
//                       color: Colors.white, size: 28),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                 ),
//               ),
//               const Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: <Widget>[
//                     Text("Register",
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
//                         const SizedBox(height: 60),
//                         TextFormField(
//                           controller: _employeeIdController,
//                           decoration: const InputDecoration(
//                             labelText: "Employee ID",
//                             border: OutlineInputBorder(),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter Employee ID';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _phoneController,
//                           keyboardType: TextInputType.phone,
//                           decoration: const InputDecoration(
//                             labelText: "Phone",
//                             border: OutlineInputBorder(),
//                           ),
//                           inputFormatters: [
//                             LengthLimitingTextInputFormatter(11),
//                             FilteringTextInputFormatter.digitsOnly,
//                           ],
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter Phone Number';
//                             } else if (value.length != 11) {
//                               return 'Phone number must be 11 digits';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 30),
//                         _isLoading
//                             ? const CircularProgressIndicator()
//                             : ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   minimumSize: const Size(200, 60),
//                                 ),
//                                 onPressed: () async {
//                                   if (_formKey.currentState!.validate()) {
//                                     setState(() {
//                                       _isLoading = true;
//                                     });

//                                     String? message =
//                                         await ApiService.registerUser(
//                                       _employeeIdController.text,
//                                       _phoneController.text,
//                                     );

//                                     setState(() {
//                                       _isLoading = false;
//                                     });

//                                     if (message != null &&
//                                         message.toLowerCase().contains('success')) {                                     
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(
//                                           content: Text('Registration successful!'),
//                                           backgroundColor: Colors.green,
//                                         ),
//                                       );

//                                       await Future.delayed(const Duration(seconds: 1));
//                                       Navigator.pushReplacementNamed(context, '/login');
//                                     } else {
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         SnackBar(content: Text(message ?? 'Registration failed')),
//                                       );
//                                     }
//                                   }
//                                 },
//                                 child: const Text(
//                                   "Submit",
//                                   style: TextStyle(fontSize: 18),
//                                 ),
//                               ),
//                         const SizedBox(height: 20),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.pushNamed(context, '/login');
//                           },
//                           child: const Text(
//                             "Already registered? Login",
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
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex, // keeps track of the selected tab
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index; // change tab
//           });
//             if (index == 0) {
//             Navigator.pushNamed(context, '/');
//             } else if (index == 1) {
//               Navigator.pushNamed(context, '/profile');
//             }
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Pfofile',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/services/register_service_api.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  int _selectedIndex = 0;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _employeeIdController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String employeeId =
          _employeeIdController.text.trim();

      final String email =
          _emailController.text.trim();

      final String password =
          _passwordController.text;

      final String confirmPassword =
          _confirmPasswordController.text;

      final String? message = await ApiService.registerUser(
        employeeId,
        email,
        password,
        confirmPassword,
      );

      if (!mounted) return;

      if (message != null &&
          message.toLowerCase().contains('successful')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(
          const Duration(seconds: 1),
        );

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/login',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message ?? 'Registration failed',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue[400]!,
              Colors.blue[200]!,
              Colors.blue[100]!,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Register",
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

                      // Employee ID
                      TextFormField(
                        controller: _employeeIdController,
                        decoration: const InputDecoration(
                          labelText: "Employee ID",
                          hintText: "Enter Employee ID",
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter Employee ID';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          hintText: "Enter Email",
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter Email';
                          }

                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Password
                      TextFormField(
                        controller:
                            _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          hintText: "Enter Password",
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
                            return 'Please enter Password';
                          }

                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Confirm Password
                      TextFormField(
                        controller:
                            _confirmPasswordController,
                        obscureText:
                            _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          hintText:
                              "Enter Confirm Password",
                          border:
                              const OutlineInputBorder(),
                          prefixIcon:
                              const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Please confirm Password';
                          }

                          if (value !=
                              _passwordController.text) {
                            return 'Passwords do not match';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      // Submit
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style:
                                  ElevatedButton.styleFrom(
                                minimumSize:
                                    const Size(200, 60),
                              ),
                              onPressed: _register,
                              child: const Text(
                                "Register",
                                style:
                                    TextStyle(fontSize: 18),
                              ),
                            ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/login',
                          );
                        },
                        child: const Text(
                          "Already registered? Login",
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

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            Navigator.pushNamed(context, '/');
          } else if (index == 1) {
            Navigator.pushNamed(
              context,
              '/profile',
            );
          } else if (index == 2) {
            Navigator.pushNamed(
              context,
              '/settings',
            );
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