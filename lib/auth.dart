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
    // Check if Admin
    QuerySnapshot adminQuery = await FirebaseFirestore.instance
        .collection("AdminDetails")
        .where("AdminEmail", isEqualTo: user.email)
        .get();

    if (adminQuery.docs.isNotEmpty) {
      return const AdminDashboardPage();
    }

    // Check if Normal User
    QuerySnapshot userQuery = await FirebaseFirestore.instance
        .collection("UserDetails")
        .where("Email", isEqualTo: user.email)
        .get();

    if (userQuery.docs.isNotEmpty) {
      return const HomeScreen();
    }

    // If no record found
    await FirebaseAuth.instance.signOut();
    return const Welcome();
  }
}