import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome.dart';

import 'login.dart';
import 'index.dart';
import 'admin.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<Widget>(
            future: _checkUserRole(snapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (roleSnapshot.hasData) {
                return roleSnapshot.data!;
              }

              return const Welcome();
            },
          );
        }

        return const Welcome();
      },
    );
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
        return const HomeScreen();
      }

      // Check Normal User by Email
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection("UserDetails")
          .where("Email", isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return const HomeScreen();
      }

      // Default fallback for logged in users
      return const HomeScreen();
    } catch (e) {
      debugPrint('Error checking user role: $e');
      return const HomeScreen();
    }
  }
}