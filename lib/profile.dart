import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'bottom_navigation_bar.dart';
import 'searchable_city_field.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  bool isUpdating = false;
  bool isSendingResetEmail = false;
  String docId = '';

  String userName = '';
  String userEmail = '';

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final wardController = TextEditingController();
  final pincodeController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  Future<void> _showForgotPasswordDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 40,
                  color: Color(0xFF2563EB),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Send Reset Link",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "A password reset link will be sent to\n$userEmail.\nContinue?",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(
                            email: userEmail,
                          );

                          if (!mounted) return;

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Password reset email sent successfully."),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text(e.message ?? "Something went wrong"),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Send Email",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    wardController.dispose();
    pincodeController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection("UserDetails")
            .where("Email", isEqualTo: user.email)
            .get();

        if (query.docs.isNotEmpty) {
          var data = query.docs.first.data() as Map<String, dynamic>;
          docId = query.docs.first.id;

          nameController.text = data['Name']?.toString() ?? '';
          emailController.text = data['Email']?.toString() ?? user.email ?? '';
          phoneController.text = data['Contact']?.toString() ?? '';
          cityController.text = data['City']?.toString() ?? '';
          wardController.text = data['Ward']?.toString() ?? '';
          pincodeController.text = data['Pincode']?.toString() ?? '';
          addressController.text = data['Address']?.toString() ?? '';

          userName = data['Name']?.toString() ?? 'Citizen';
          userEmail = data['Email']?.toString() ?? user.email ?? '';
        } else {
          // Fallback to checking by UID directly if email query returned no results
          DocumentSnapshot doc = await FirebaseFirestore.instance
              .collection("UserDetails")
              .doc(user.uid)
              .get();

          if (doc.exists) {
            var data = doc.data() as Map<String, dynamic>;
            docId = doc.id;

            nameController.text = data['Name']?.toString() ?? '';
            emailController.text = data['Email']?.toString() ?? user.email ?? '';
            phoneController.text = data['Contact']?.toString() ?? '';
            cityController.text = data['City']?.toString() ?? '';
            wardController.text = data['Ward']?.toString() ?? '';
            pincodeController.text = data['Pincode']?.toString() ?? '';
            addressController.text = data['Address']?.toString() ?? '';

            userName = data['Name']?.toString() ?? 'Citizen';
            userEmail = data['Email']?.toString() ?? user.email ?? '';
          } else {
            // New user, pre-fill Email
            docId = user.uid;
            emailController.text = user.email ?? '';
            userName = 'New Citizen';
            userEmail = user.email ?? '';
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isUpdating = true;
    });

    try {
      final updateData = {
        "Name": nameController.text.trim(),
        "Contact": phoneController.text.trim(),
        "City": cityController.text.trim(),
        "Ward": wardController.text.trim(),
        "Pincode": pincodeController.text.trim(),
        "Address": addressController.text.trim(),
      };

      if (docId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("UserDetails")
            .doc(docId)
            .update(updateData);
      } else {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection("UserDetails")
              .doc(user.uid)
              .set({
            "Email": user.email ?? emailController.text.trim(),
            ...updateData,
          });
          docId = user.uid;
        }
      }

      setState(() {
        userName = nameController.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated Successfully"),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to Update Profile"),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEAEA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Logout",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Are you sure you want to logout?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
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
                        onPressed: () async {
                          Navigator.pop(context);
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFEF4444),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Logout",
                          style: GoogleFonts.inter(
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
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Hero(
            tag: 'profile_avatar',
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName.isEmpty ? "Citizen" : userName,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
            ),
            child: Text(
              "Citizen",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2563EB),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2563EB)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Profile",
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),

                  // Personal Information Card
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Personal Information",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 20),
                            PremiumTextField(
                              controller: nameController,
                              label: "Full Name",
                              prefixIcon: Icons.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Full Name cannot be empty";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            PremiumTextField(
                              controller: emailController,
                              label: "Email Address",
                              prefixIcon: Icons.email,
                              readOnly: true,
                            ),
                            const SizedBox(height: 20),
                            PremiumTextField(
                              controller: phoneController,
                              label: "Mobile Number",
                              prefixIcon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Mobile Number cannot be empty";
                                }
                                if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                                  return "Contact Number must be exactly 10 digits";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SearchableCityField(
                              cityController: cityController,
                              pincodeController: pincodeController,
                              label: "City",
                              primaryColor: const Color(0xFF2563EB),
                              borderRadius: 16,
                              isProfileStyle: true,
                              validator: (value) {
                                if (cityController.text.trim().isEmpty) {
                                  return "Please select your city";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            PremiumTextField(
                              controller: wardController,
                              label: "Ward Number",
                              prefixIcon: Icons.home,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Ward cannot be empty";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            PremiumTextField(
                              controller: pincodeController,
                              label: "Pincode",
                              prefixIcon: Icons.pin_drop,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Pincode cannot be empty";
                                }
                                if (!RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) {
                                  return "Pincode must be exactly 6 digits";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            PremiumTextField(
                              controller: addressController,
                              label: "Address",
                              prefixIcon: Icons.home,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Address cannot be empty";
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Update Profile Button
                  PremiumButton(
                    text: "Update Profile",
                    onPressed: _updateProfile,
                    isLoading: isUpdating,
                  ),
                  const SizedBox(height: 32),

                  // Account Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Account Settings",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Account Actions Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        PremiumActionTile(
                          icon: Icons.lock,
                          title: "Forgot Password",
                          subtitle: "Send password reset email",
                          onTap: _showForgotPasswordDialog,
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E7EB), indent: 16, endIndent: 16),
                        PremiumActionTile(
                          icon: Icons.logout,
                          title: "Logout",
                          subtitle: "Sign out of your account",
                          iconColor: const Color(0xFFEF4444),
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }
}

class PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool readOnly;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: readOnly ? const Color(0xFF6B7280) : const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            prefixIcon: Icon(
              prefixIcon,
              color: const Color(0xFF2563EB),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            hintText: "Enter $label",
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (widget.onPressed != null && !widget.isLoading) {
          widget.onPressed!();
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? const Color(0xFF2563EB).withOpacity(0.6)
                : const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  widget.text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

class PremiumActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const PremiumActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = const Color(0xFF2563EB),
  });

  @override
  State<PremiumActionTile> createState() => _PremiumActionTileState();
}

class _PremiumActionTileState extends State<PremiumActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          color: Colors.transparent, // Ensure gesture detection on full area
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class PremiumPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final String? Function(String?)? validator;

  const PremiumPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.validator,
  });

  @override
  State<PremiumPasswordField> createState() => _PremiumPasswordFieldState();
}

class _PremiumPasswordFieldState extends State<PremiumPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          validator: widget.validator,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(
              widget.prefixIcon,
              color: const Color(0xFF2563EB),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            hintText: "Enter ${widget.label}",
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 15,
            ),
          ),
        ),
      ],

    );
  }
}
