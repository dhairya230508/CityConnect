import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin.dart';

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
      // Login first
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Now you can use userCredential
      QuerySnapshot adminQuery = await FirebaseFirestore.instance
          .collection("AdminDetails")
          .where(
        "AdminEmail",
        isEqualTo: userCredential.user!.email,
      )
          .get();

      if (adminQuery.docs.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboardPage(),
          ),
        );
        return;
      }

      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection("UserDetails")
          .where(
        "Email",
        isEqualTo: userCredential.user!.email,
      )
          .get();

      if (userQuery.docs.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User record not found")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login Failed")),
      );
    }
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _showForgotPasswordDialog(BuildContext context) {
    final emailResetController = TextEditingController(text: emailController.text.trim());
    final formKey = GlobalKey<FormState>();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              elevation: 10,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAF4FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Color(0xFF2563EB),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "Reset Password",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Enter your email address and we'll send you a link to reset your password.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailResetController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: "you@example.com",
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: const Color(0xffF7F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter your email";
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSending
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setState(() {
                                        isSending = true;
                                      });
                                      try {
                                        await FirebaseAuth.instance.sendPasswordResetEmail(
                                          email: emailResetController.text.trim(),
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Password reset link sent to ${emailResetController.text.trim()}"),
                                              backgroundColor: const Color(0xFF22C55E),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                        Navigator.pop(dialogContext);
                                      } on FirebaseAuthException catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(e.message ?? "Failed to send reset email."),
                                              backgroundColor: const Color(0xFFEF4444),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: ${e.toString()}"),
                                              backgroundColor: const Color(0xFFEF4444),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } finally {
                                        setState(() {
                                          isSending = false;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF2563EB),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSending
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "Send",
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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
                                  onPressed: () => _showForgotPasswordDialog(context),

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