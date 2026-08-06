import 'package:city_connect/login.dart';
import 'package:city_connect/register.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final bool isWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Hero Banner - Spans 100% full screen width on both Web & Mobile
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isWeb ? 40 : screenHeight * 0.04,
                horizontal: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2B7FD8),
                    Color(0xFF5AA7EE),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/LOGO.png',
                    width: isWeb ? 110 : screenHeight * 0.13,
                    height: isWeb ? 110 : screenHeight * 0.13,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "CityConnect",
                    style: TextStyle(
                      fontSize: isWeb ? 36 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Report • Track • Resolve",
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 40 : 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Text Description Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Connecting citizens with\nmunicipal authorities.",
                          style: GoogleFonts.poppins(
                            fontSize: isWeb ? 22 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Report complaints, track their status, and stay\ninformed about local alerts — all in one place.",
                          style: GoogleFonts.poppins(
                            fontSize: isWeb ? 15 : 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    // Action Buttons & Copyright Footer
                    Column(
                      children: [
                        // Create an Account button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Register(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            backgroundColor: const Color(0xFF2B7FD8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            "Create an Account",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Login to Account button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            backgroundColor: const Color(0xFF90CAF9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            "Login to Account",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Footer Copyright text
                        Center(
                          child: Text(
                            "© 2026 CityConnect · All rights reserved",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
