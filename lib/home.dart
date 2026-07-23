import 'package:city_connect/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:city_connect/register.dart';

class home extends StatefulWidget {
  const home({super.key});

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;
    double screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Column(
        children: [

          Expanded(
            flex: 1,
            child: Container(
              width: screenWidth,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2b7fd8),
                    Color(0xFF5AA7EE),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //   logo
                  Image.asset('assets/LOGO.png',width: screenHeight*0.2,height: screenHeight*0.2,),
                  // Transform.translate used to move a widget.
                  Transform.translate(offset: const Offset(0, -8),
                    child: Text(
                      "CityConnect",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  //used to crate empty vertical space between wiedgets
                  SizedBox(height: screenHeight*0.01,),
                  Text(
                    "Report • Track • Resolve",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(screenWidth*0.01),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Connecting citizens with\nmunicipal authorities.",
                    style:GoogleFonts.poppins(
                      fontSize:20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text("Report complaints, track their status, and stay\ninformed about local alerts — all in one place.",
                        style:GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight:FontWeight.w300,
                          color: Colors.black,
                        )
                    ),
                  ),
                  // create account button
                  SizedBox(height: screenHeight*0.1,),
              
                  Column(
                    children: [
                      ElevatedButton(
                          onPressed: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder:(context)=>const Register()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 55),
                              backgroundColor: Color(0xFF2B7FD8),
                              shape:RoundedRectangleBorder(
                                borderRadius:BorderRadius.circular(18),
                              )
                          ),
                          child: Text("Create an Account",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
              
                            ),
                          )
                      ),
              
                      // login buttton
              
                      SizedBox(height: screenHeight*0.02,),
              
                      ElevatedButton(
                          onPressed: (){
                            Navigator.push(context,MaterialPageRoute(builder: (context)=>const LoginPage()));
                          },
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 55),
                              backgroundColor: Color(0xFF90CAF9),
                              shape:RoundedRectangleBorder(
                                borderRadius:BorderRadius.circular(18),
                              )
                          ),
                          child: Text("Login to Account",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          )
                      ),
                    ],
                  ),
              
                  SizedBox(height: screenHeight*0.01,),
              
                  Text("© 2026 CityConnect · All rights reserved",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
