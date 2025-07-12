import 'dart:async';
import 'package:employeehealthcare/screens/auth_check.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInLogo;
  late Animation<double> _scaleLogo;
  late Animation<double> _fadeInText;
  @override
  void initState() {
    // TODO: implement initState
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeInLogo = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleLogo = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeInText = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();
    startTimer();
    super.initState();
  }
  startTimer(){
    var duration=const Duration(seconds: 4);
    return Timer(duration,route);
  }
  route(){
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>   AuthCheck()),
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.4;
    double textSize = screenWidth * 0.07;
    return Scaffold(
      backgroundColor: Colors.white, // Change background color if needed
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInLogo.value,
                  child: Transform.scale(
                    scale: _scaleLogo.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/splash_logo.png',
                width: logoSize,
              ),
            ),
            SizedBox(height: screenWidth * 0.08),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeInText.value,
                  child: child,
                );
              },
              child: Text(
                'UAAR Employee Healthcare',
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
