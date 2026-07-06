
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  //int _currentIndex = 0;
  int _selectedIndex = 0;
  String userName = "";
  String userEmail = "";

  @override
void initState() {
  super.initState();
  loadUser();
}

Future<void> loadUser() async {
  final prefs = await SharedPreferences.getInstance();

  final userJson = prefs.getString('user');

  if (userJson != null) {
    final user = jsonDecode(userJson);

    setState(() {
      userName = user['name'] ?? "";
      userEmail = user['email'] ?? "";
    });
  }
}

  Widget _homeMenu(
  BuildContext context,
  String title,
  IconData icon,
  String route,
) {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 50,
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Get Current Location"),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
             
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : "A",
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            // UserAccountsDrawerHeader(
            //   accountName: Text("Abdur Rahman"),
            //   accountEmail: Text("engrabdurrahman4991@gmail.com"),
            //   currentAccountPicture: CircleAvatar(
            //     backgroundColor: Colors.white,
            //     child: Text("A", style: TextStyle(fontSize: 30)),
            //   ),
            // ),
            ListTile(
              title: const Text("Register"),
              leading: const Icon(Icons.app_registration_rounded),
              onTap: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
            ListTile(
              title: const Text("Login"),
              leading: const Icon(Icons.login),
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
                        
            ListTile(
              title: const Text("Logout"),
              leading: const Icon(Icons.logout),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('access_token');
                await prefs.remove('geofancing'); // optional: remove geofencing data

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false, // remove all previous routes
                  );
                }
              },
            ),
          ],
        ),
      ),
     
      
      // body: const Center(
        
      //   child: Text(" Hello "),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _homeMenu(
              context,
              "Location Setting",
              Icons.location_searching,
              '/location-setting',
            ),
            _homeMenu(
              context,
              "Location Setting List",
              Icons.map,
              '/location-setting-list',
            ),
            _homeMenu(
              context,
              "Attendance",
              Icons.fact_check,
              '/attendance',
            ),
            _homeMenu(
              context,
              "Attendance History",
              Icons.history,
              '/attendance-history',
            ),
          ],
        ),
      ),

      
    //  bottomNavigationBar: BottomNavigationBar(
    //     currentIndex: _selectedIndex, // keeps track of the selected tab
    //     onTap: (index) {
    //       setState(() {
    //         _selectedIndex = index; // change tab
    //       });
    //       if (index == 0) {
    //       Navigator.pushNamed(context, '/');
    //       } else if (index == 1) {
    //         Navigator.pushNamed(context, '/profile');
    //       }
    //     },
    //     items: const [
    //       BottomNavigationBarItem(
    //         icon: Icon(Icons.home),
    //         label: 'Home',
    //       ),
    //       BottomNavigationBarItem(
    //         icon: Icon(Icons.person),
    //         label: 'Profile',
    //       ),
    //       BottomNavigationBarItem(
    //         icon: Icon(Icons.settings),
    //         label: 'Settings',
    //       ),
    //     ],
    //   ),
    );
  }
}