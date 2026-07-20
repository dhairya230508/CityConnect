import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'index.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Successful"),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Login Failed"),
        ),
      );
    }
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20,20,20,30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "WELCOME BACK",
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Login",
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                        fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Sign in to your CityConnect account",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,

                decoration: const BoxDecoration(
                  color: Color(0xffF4F6FA),
                ),

                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [

                      const SizedBox(height: 15),

                      // Profile Icon

                      Container(
                        height: 72,
                        width: 72,

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),

                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff309BFF),
                              Color(0xff1565C0),
                            ],
                          ),
                        ),

                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Login Card

                      Container(
                        padding: const EdgeInsets.all(22),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(.04),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),

                        child: Form(
                          key: _formKey,

                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              Text(
                                "EMAIL ADDRESS",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  letterSpacing: 1,
                                ),
                              ),

                              const SizedBox(height: 10),

                              TextFormField(
                                controller: emailController,
                                keyboardType:
                                TextInputType.emailAddress,

                                decoration: InputDecoration(
                                  hintText: "you@example.com",

                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                  ),

                                  filled: true,
                                  fillColor:
                                  const Color(0xffF7F8FC),

                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value)
                                {
                                  if(value==null || value.isEmpty)
                                    {
                                      return "Please Enter Email";
                                    }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 22),

                              Text(
                                "PASSWORD",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  letterSpacing: 1,
                                ),
                              ),

                              const SizedBox(height: 10),

                              TextFormField(
                                controller: passwordController,
                                obscureText: obscurePassword,

                                decoration: InputDecoration(
                                  hintText: "Enter your password",

                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                  ),

                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),

                                    onPressed: () {
                                      setState(() {
                                        obscurePassword =
                                        !obscurePassword;
                                      });
                                    },
                                  ),

                                  filled: true,
                                  fillColor:
                                  const Color(0xffF7F8FC),

                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value)
                                {
                                  if(value==null || value.isEmpty)
                                    {
                                      return "Please Enter Your Password";
                                    }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 8),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},

                                  child: Text(
                                    "Forgot Password?",
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue,
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 56,

                        child: ElevatedButton(
                          onPressed: loginUser,

                          style: ElevatedButton.styleFrom(
                            elevation: 0,

                            backgroundColor:
                            const Color(0xff1976D2),

                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(18),
                            ),
                          ),

                          child: Text(
                            "Login",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: 12),
                            child: Text("or"),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [

                          Text(
                            "Don't have an account?",
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> Register()));
                            },

                            child: Text(
                              "Create Account",
                              style: GoogleFonts.poppins(
                                color: Colors.blue,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}