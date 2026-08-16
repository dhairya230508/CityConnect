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
  final TextEditingController resetEmailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    resetEmailController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final String inputEmail = emailController.text.trim();
    final String inputPassword = passwordController.text.trim();

    try {
      // 1. Authenticate with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: inputEmail,
        password: inputPassword,
      );

      final String userEmail = (userCredential.user?.email ?? inputEmail).trim();
      final String uid = userCredential.user?.uid ?? '';

      // 2. Check if Admin (by AdminEmail query or UID doc)
      QuerySnapshot adminQuery = await FirebaseFirestore.instance
          .collection("AdminDetails")
          .where("AdminEmail", isEqualTo: userEmail)
          .get();

      bool isAdmin = adminQuery.docs.isNotEmpty;

      if (!isAdmin && uid.isNotEmpty) {
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance
            .collection("AdminDetails")
            .doc(uid)
            .get();
        if (adminDoc.exists) isAdmin = true;
      }

      if (!isAdmin) {
        // Case-insensitive query fallback for admin email
        QuerySnapshot adminQueryLower = await FirebaseFirestore.instance
            .collection("AdminDetails")
            .where("AdminEmail", isEqualTo: userEmail.toLowerCase())
            .get();
        if (adminQueryLower.docs.isNotEmpty) isAdmin = true;
      }

      if (isAdmin) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboardPage(),
          ),
          (route) => false,
        );
        return;
      }

      // 3. Check if User (by UID doc or Email query)
      bool isUser = false;
      if (uid.isNotEmpty) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("UserDetails")
            .doc(uid)
            .get();
        if (userDoc.exists) isUser = true;
      }

      if (!isUser) {
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection("UserDetails")
            .where("Email", isEqualTo: userEmail)
            .get();
        if (userQuery.docs.isNotEmpty) isUser = true;
      }

      if (!isUser) {
        QuerySnapshot userQueryLower = await FirebaseFirestore.instance
            .collection("UserDetails")
            .where("Email", isEqualTo: userEmail.toLowerCase())
            .get();
        if (userQueryLower.docs.isNotEmpty) isUser = true;
      }

      // 4. Navigate to User Home Screen
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = "Login failed. Please check your credentials.";
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'INVALID_LOGIN_CREDENTIALS') {
        errorMessage = "Incorrect email or password. Please try again.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format. Please enter a valid email address.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "This user account has been disabled.";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Too many failed attempts. Please try again later.";
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login error: ${e.toString()}"),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // FORGOT PASSWORD — confirmation box (matches reference design)
  // If the login email field already has a value, it is shown as
  // plain confirmation text and the user just taps "Send Email".
  // If it's empty, an inline editable field appears in its place
  // so the user can type the email once, right inside this dialog,
  // without needing to go back and fill the field above.
  // ============================================================
  void _showForgotPasswordDialog(BuildContext context) {
    resetEmailController.text = emailController.text.trim();
    bool isSending = false;

    // Decided ONCE, when the dialog opens — not recalculated on every
    // keystroke. This is what stopped the input field from vanishing
    // after the first character typed.
    final bool wasEmailPrefilled = resetEmailController.text.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon badge
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF4FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: Color(0xFF2563EB),
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Send Reset Link",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Either a plain confirmation line (email already
                    // known) or a compact inline field to type it.
                    // wasEmailPrefilled is fixed for the dialog's whole
                    // lifetime, so typing never swaps this section away.
                    if (wasEmailPrefilled)
                      Text(
                        "A password reset link will be sent to "
                            "${resetEmailController.text.trim()}. Continue?",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      )
                    else ...[
                      Text(
                        "Enter your email to receive the reset link.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        onChanged: (value) {
                          setState(() {});
                        },
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Enter your email",
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF64748B),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 1.6,
                            ),
                          ),
                        ),
                      )
                    ],

                    const SizedBox(height: 26),

                    Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSending
                                ? null
                                : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Send Email button — always active once an
                        // email is present, whether typed above or here.
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (isSending ||
                                resetEmailController.text.trim().isEmpty)
                                ? null
                                : () async {
                              final email = resetEmailController.text.trim();
                              setState(() => isSending = true);
                              final scaffoldMessenger = ScaffoldMessenger.of(context);

                              try {
                                // Verify email exists in database (UserDetails or AdminDetails)
                                final QuerySnapshot userQuery =
                                await FirebaseFirestore.instance
                                    .collection("UserDetails")
                                    .where("Email", isEqualTo: email)
                                    .limit(1)
                                    .get();

                                bool isRegistered = userQuery.docs.isNotEmpty;

                                if (!isRegistered) {
                                  final QuerySnapshot adminQuery =
                                  await FirebaseFirestore.instance
                                      .collection("AdminDetails")
                                      .where("AdminEmail", isEqualTo: email)
                                      .limit(1)
                                      .get();
                                  isRegistered = adminQuery.docs.isNotEmpty;
                                }

                                if (!isRegistered) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        "No registered account found with this email address.",
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: const Color(0xFFDC2626),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                await _auth.sendPasswordResetEmail(
                                  email: email,
                                );

                                // Keep the login form's email field
                                // in sync with what was just used.
                                emailController.text = email;

                                if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
                                  Navigator.pop(dialogContext);
                                }

                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Reset link sent to $email",
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor:
                                    const Color(0xFF16A34A),
                                    behavior:
                                    SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.message ??
                                          "Failed to send reset email.",
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor:
                                    const Color(0xFFDC2626),
                                    behavior:
                                    SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                              finally {
                                if (dialogContext.mounted) {
                                  setState(() {
                                    isSending = false;
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF2563EB),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSending
                                ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              "Send Email",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
                child: Form(
                  key: _formKey,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: "you@example.com",
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xffF7F8FC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
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
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xffF7F8FC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please Enter Your Password";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 8),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      _showForgotPasswordDialog(context),
                                  child: Text(
                                    "Forgot Password?",
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : loginUser,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xff1976D2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Register(),
                                  ),
                                );
                              },
                              child: Text(
                                "Create Account",
                                style: GoogleFonts.poppins(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w700,
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
            ),
          ],
        ),
      ),
    );
  }
}