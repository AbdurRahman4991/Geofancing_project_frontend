import 'package:flutter/material.dart';
import 'pages/register.dart';
import 'pages/login.dart';
import 'pages/attendance.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  
  const MyApp({super.key});
  
  
  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Geofance',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // Handle named routes
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        switch (uri.path) {
          case '/register':
            return MaterialPageRoute(builder: (_) =>  Register());
          case '/login':
          return MaterialPageRoute(builder: (_) => Login());
          case '/attendance':
          return MaterialPageRoute(builder: (_) => AttendancePage());
          default:
            return MaterialPageRoute(builder: (_) => const HomePage());
        }
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int _selectedIndex =0;

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
            const UserAccountsDrawerHeader(
              accountName: Text("Abdur Rahman"),
              accountEmail: Text("engrabdurrahman4991@gmail.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text("A", style: TextStyle(fontSize: 30)),
              ),
            ),
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
              title: const Text("Attendance"),
              leading: const Icon(Icons.present_to_all),
              onTap: () {
                Navigator.pushNamed(context, '/attendance');
              }
              ),
            
            // ListTile(
            //   title: const Text("Logout"),
            //   leading: const Icon(Icons.logout),
            //   onTap: () {
            //     Navigator.pushNamed(context, '/logout');
            //   },
            // ),
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
     
      
      body: const Center(
        
        child: Text(""),
      ),
     bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // keeps track of the selected tab
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // change tab
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Back',
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
