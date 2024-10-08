import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trade_seller/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Check authentication state after a brief delay
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthentication();
    });
  }

  // Function to check authentication state
  void _checkAuthentication() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // If the user is logged in, navigate to Home Screen
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // If not logged in, navigate to Auth Screen
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Image.asset(
                  'assets/farmOS.png',
                  // height: 100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
