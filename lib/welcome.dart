import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'index.dart';
import 'admin.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Ensure splash screen is displayed for 2.5 seconds on every cold app start
    final minimumSplashDelay = Future.delayed(const Duration(milliseconds: 2500));

    Widget targetScreen = const home();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        targetScreen = await _checkUserRole(currentUser);
      }
    } catch (e) {
      debugPrint('Error during splash auth check: $e');
    }

    await minimumSplashDelay;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => targetScreen,
        ),
      );
    }
  }

  Future<Widget> _checkUserRole(User user) async {
    final email = user.email ?? '';
    final uid = user.uid;

    try {
      // 1. Check if Admin by Email query
      QuerySnapshot adminQuery = await FirebaseFirestore.instance
          .collection("AdminDetails")
          .where("AdminEmail", isEqualTo: email)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        return const AdminDashboardPage();
      }

      // Check Admin by lowercased email
      QuerySnapshot adminQueryLower = await FirebaseFirestore.instance
          .collection("AdminDetails")
          .where("AdminEmail", isEqualTo: email.toLowerCase())
          .get();

      if (adminQueryLower.docs.isNotEmpty) {
        return const AdminDashboardPage();
      }

      // Check Admin by UID doc
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection("AdminDetails")
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        return const AdminDashboardPage();
      }

      // 2. Check if Normal User by UID doc
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("UserDetails")
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          final bool isBlocked = (userData['IsBlocked'] == true ||
              userData['isBlocked'] == true ||
              userData['Status'] == 'Blocked');
          if (isBlocked) {
            await FirebaseAuth.instance.signOut();
            return const home();
          }
        }
        return const HomeScreen();
      }

      // Check Normal User by Email
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection("UserDetails")
          .where("Email", isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data() as Map<String, dynamic>?;
        if (userData != null) {
          final bool isBlocked = (userData['IsBlocked'] == true ||
              userData['isBlocked'] == true ||
              userData['Status'] == 'Blocked');
          if (isBlocked) {
            await FirebaseAuth.instance.signOut();
            return const home();
          }
        }
        return const HomeScreen();
      }

      return const HomeScreen();
    } catch (e) {
      debugPrint('Error checking user role: $e');
      return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;
    double screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Container(
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
            Image.asset(
              'assets/LOGO.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_city_rounded,
                    size: 80,
                    color: Color(0xFF1976D2),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            const Text(
              "Welcome To\nCityConnect",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 50),
            const Text(
              "Report • Track • Resolve",
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