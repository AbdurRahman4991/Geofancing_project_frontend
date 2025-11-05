import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/services/register_service_api.dart'; 

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  int _selectedIndex = 0;
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false; // 👈 Loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.blue[400]!,
            Colors.blue[200]!,
            Colors.blue[100]!,
          ]),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("Register",
                        style: TextStyle(fontSize: 30, color: Colors.white)),
                    Text("Welcome",
                        style: TextStyle(fontSize: 10, color: Colors.white)),
                  ],
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 60),
                        TextFormField(
                          controller: _employeeIdController,
                          decoration: const InputDecoration(
                            labelText: "Employee ID",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Employee ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Phone",
                            border: OutlineInputBorder(),
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(11),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Phone Number';
                            } else if (value.length != 11) {
                              return 'Phone number must be 11 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(200, 60),
                                ),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    String? message =
                                        await ApiService.registerUser(
                                      _employeeIdController.text,
                                      _phoneController.text,
                                    );

                                    setState(() {
                                      _isLoading = false;
                                    });

                                    if (message != null &&
                                        message.toLowerCase().contains('success')) {                                     
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Registration successful!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      await Future.delayed(const Duration(seconds: 1));
                                      Navigator.pushReplacementNamed(context, '/login');
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(message ?? 'Registration failed')),
                                      );
                                    }
                                  }
                                },
                                child: const Text(
                                  "Submit",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text(
                            "Already registered? Login",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
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
            label: 'Pfofile',
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
