import 'package:flutter/material.dart';
import 'dart:async';
import 'login.dart';
import 'home.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();

}


class _WelcomeState extends State<Welcome> {
  @override
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const home(),
          ),
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {


    double screenWidth = MediaQuery.sizeOf(context).width;

    double screenHeight = MediaQuery.sizeOf(context).height;

    return  Scaffold(
      body:Container(
          height: screenHeight,
          width: screenWidth,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFF64B5F6),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/LOGO.png',width: 150,height: 150,),
            const SizedBox(height: 25),

            const Text("Welcome To\nCityConnect",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
            ),
            SizedBox(height: 50,),
            const Text("Report • Track • Resolve",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w200,
                color: Colors.white,
                height: 1,
              ),
            )
          ],
        ),
      ),
    );
  }
}