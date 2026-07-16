import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'pages/Home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/background_location_service.dart';
import 'package:permission_handler/permission_handler.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen>
  with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    /// 🎬 Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    _controller.forward();
    _checkLogin();
  }
Future<void> _checkLogin() async {

  await Future.delayed(
    const Duration(seconds: 2),
  );


  final prefs =
      await SharedPreferences.getInstance();


  final token =
      prefs.getString('access_token');


  if (!mounted) return;


  if (token != null && token.isNotEmpty) {


    // Android 13+ notification permission
    await Permission.notification.request();


    // Background service start
    await BackgroundLocationService
        .initializeService();


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );


  } else {


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Login(),
      ),
    );

  }
}
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
      Widget build(BuildContext context) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade400,
                  Colors.red.shade300,
                  Colors.red.shade100,
                ],
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logopng.png',
                        height: 90,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }