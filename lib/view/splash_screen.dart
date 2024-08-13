import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fresh_guard/model/login_screen.dart';
import 'package:lottie/lottie.dart';

import 'home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4), () {});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Lottie.asset(
              'lib/assets/loading.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 30),
            // Uncomment and use the following code if you want to display the text with animation
            /*
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: Duration(seconds: 2),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value,
                    child: child,
                  ),
                );
              },
              child: Text(
                'Keep your food fresh',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w100,
                  color: Colors.blueGrey,
                  shadows: [
                    Shadow(
                      blurRadius: 5.0,
                      color: Colors.grey.withOpacity(0.5),
                      offset: const Offset(2.0, 2.0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            */
          ],
        ),
      ),
    );
  }
}
