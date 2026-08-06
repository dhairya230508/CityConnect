// ============================================================================
// CityConnect - Municipal Complaint Management System
// Admin Console Settings
// ============================================================================
// Production-quality admin console screen built with Flutter + Firebase.
// Sections: profile header, live dashboard statistics, editable admin
// profile (name / email / hotline only), and console security actions
// (forgot password / logout). Styled to read like a government/SaaS admin
// console (Firebase Console / Stripe Dashboard style) rather than a plain
// CRUD form.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF0F172A); // Navy
  static const Color primaryLight = Color(0xFF1E293B);
  static const Color accent = Color(0xFF3B82F6); // Blue
  static const Color success = Color(0xFF22C55E); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color background = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textFaint = Color(0xFF94A3B8);
  static const Color card = Colors.white;
}

// ---------------------------------------------------------------------------
// AdminSettings - main entry page
// ---------------------------------------------------------------------------
class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  bool isLoading = true;
  bool isUpdating = false;
  bool isSendingResetEmail = false;

  String docId = '';
  String adminUid = '';

  String adminName = '';
  String adminEmail = '';
  String adminContact = '';

  // Dashboard counters
  int totalUsers = 0;
  int totalComplaints = 0;
  int pendingComplaints = 0;
  int resolvedComplaints = 0;
  bool isStatsLoading = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _loadAdminData();
    _loadDashboardStats();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Data loading
  // -------------------------------------------------------------------------
  Future<void> _loadAdminData() async {
    setState(() => isLoading = true);
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        adminUid = user.uid;

        final QuerySnapshot query = await FirebaseFirestore.instance
            .collection('AdminDetails')
            .where('AdminEmail', isEqualTo: user.email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data() as Map<String, dynamic>;
          docId = query.docs.first.id;

          adminName = data['AdminName']?.toString() ?? '';
          adminEmail = data['AdminEmail']?.toString() ?? user.email ?? '';
          adminContact = data['AdminContact']?.toString() ?? '';

          nameController.text = adminName;
          emailController.text = adminEmail;
          contactController.text = adminContact;
        } else {
          adminEmail = user.email ?? '';
          emailController.text = adminEmail;
        }
      }
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        _fadeController.forward();
        _slideController.forward();
      }
    }
  }

  Future<void> _loadDashboardStats() async {
    setState(() => isStatsLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;

      final results = await Future.wait([
        firestore.collection('UserDetails').count().get(),
        firestore.collection('ComplaintDescription').count().get(),
        firestore
            .collection('ComplaintDescription')
            .where('ComplaintStatus', isEqualTo: 'Pending')
            .count()
            .get(),
        firestore
            .collection('ComplaintDescription')
            .where('ComplaintStatus', isEqualTo: 'Resolved')
            .count()
            .get(),
      ]);

      if (mounted) {
        setState(() {
          totalUsers = results[0].count ?? 0;
          totalComplaints = results[1].count ?? 0;
          pendingComplaints = results[2].count ?? 0;
          resolvedComplaints = results[3].count ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      // Never crash on missing/empty data — counters simply stay at 0.
    } finally {
      if (mounted) setState(() => isStatsLoading = false);
    }
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------
  Future<void> _updateAdminProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isUpdating = true);

    try {
      final Map<String, dynamic> updateData = {
        'AdminName': nameController.text.trim(),
        'AdminContact': contactController.text.trim(),
      };

      if (docId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('AdminDetails')
            .doc(docId)
            .update(updateData);
      } else {
        final User? user = FirebaseAuth.instance.currentUser;
        final newDoc =
        await FirebaseFirestore.instance.collection('AdminDetails').add({
          'AdminEmail': user?.email ?? emailController.text.trim(),
          'CreatedAt': FieldValue.serverTimestamp(),
          ...updateData,
        });
        docId = newDoc.id;
      }

      setState(() {
        adminName = nameController.text.trim();
        adminContact = contactController.text.trim();
      });

      _showSnack('Admin profile updated successfully!', AppColors.success);
    } catch (e) {
      _showSnack('Failed to update profile: ${e.toString()}', AppColors.error);
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final confirmed = await _showConfirmDialog(
      icon: Icons.mail_lock_outlined,
      iconColor: AppColors.accent,
      iconBg: const Color(0xFFEFF6FF),
      title: 'Send Reset Link',
      message: 'A password reset link will be sent to $adminEmail. Continue?',
      confirmLabel: 'Send Email',
      confirmColor: AppColors.accent,
    );
    if (confirmed != true) return;

    setState(() => isSendingResetEmail = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: adminEmail);
      _showSnack(
          'Password reset email sent to $adminEmail', AppColors.success);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Failed to send reset email.', AppColors.error);
    } catch (e) {
      _showSnack('Error: ${e.toString()}', AppColors.error);
    } finally {
      if (mounted) setState(() => isSendingResetEmail = false);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF90CAF9),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
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
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await _showConfirmDialog(
      icon: Icons.power_settings_new_rounded,
      iconColor: AppColors.error,
      iconBg: const Color(0xFFFFEAEA),
      title: 'Exit Admin Panel',
      message:
      'Are you sure you want to end your administration session and log out?',
      confirmLabel: 'Logout',
      confirmColor: AppColors.error,
    );
    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Admin Console Settings',
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          await Future.wait([
            _loadAdminData(),
            _loadDashboardStats(),
          ]);
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Dashboard Overview'),
                      const SizedBox(height: 12),
                      _buildDashboardStats(constraints.maxWidth),
                      const SizedBox(height: 24),
                      _buildAdminInfoCard(),
                      const SizedBox(height: 20),
                      _buildUpdateButton(),
                      const SizedBox(height: 32),
                      _buildSectionLabel('Console Security'),
                      const SizedBox(height: 12),
                      _buildSecuritySection(),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------
  Widget _buildProfileHeader() {
    final String displayId = adminUid.length > 8
        ? adminUid.substring(0, 8).toUpperCase()
        : 'ADMIN-CC';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1976D2),
            Color(0xFF1565C0),
            Color(0xFF0D47A1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'admin-avatar',
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2196F3), width: 3),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.accent,
                    size: 50,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_user_rounded,
                      color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            adminName.isEmpty ? 'System Administrator' : adminName,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            adminEmail,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textFaint),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _headerBadge({
    required IconData icon,
    required String label,
    required Color color,
    bool mono = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: mono
                ? GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFCBD5E1))
                : GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Dashboard stats — responsive grid
  //   Desktop (>=1000px):  4 columns, one row
  //   Tablet  (>=620px):   2 columns (2x2)
  //   Mobile  (>=360px):   2 columns
  //   Very small (<360px): 1 column
  // -------------------------------------------------------------------------
  Widget _buildDashboardStats(double maxWidth) {
    final stats = [
      _StatData('Total Users', totalUsers, Icons.groups_rounded,
          AppColors.accent, 'Registered citizens'),
      _StatData('Total Complaints', totalComplaints, Icons.report_rounded,
          const Color(0xFF8B5CF6), 'All time submissions'),
      _StatData('Pending', pendingComplaints, Icons.hourglass_top_rounded,
          AppColors.warning, 'Awaiting action'),
      _StatData('Resolved', resolvedComplaints, Icons.task_alt_rounded,
          AppColors.success, 'Successfully closed'),
    ];

    int crossAxisCount;
    if (maxWidth >= 1000) {
      crossAxisCount = 4;
    } else if (maxWidth >= 620) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    const double targetHeight = 96;
    const double spacing = 12;
    final double cardWidth = (maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
    final double aspectRatio = cardWidth / targetHeight;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, i) => DashboardStatCard(
        data: stats[i],
        isLoading: isStatsLoading,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Admin info card — Full Name, Official Email (read only), Hotline
  // -------------------------------------------------------------------------
  Widget _buildAdminInfoCard() {
    return _PremiumCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(
                Icons.badge_rounded, 'Administrative Officer Details'),
            const Divider(height: 32, color: AppColors.border),
            PremiumTextField(
              controller: nameController,
              label: 'Full Name',
              prefixIcon: Icons.badge_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Admin name cannot be empty';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            PremiumTextField(
              controller: emailController,
              label: 'Official Email Address',
              prefixIcon: Icons.email_outlined,
              readOnly: true,
            ),
            const SizedBox(height: 20),
            PremiumTextField(
              controller: contactController,
              label: 'Authorized Hotline',
              prefixIcon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Hotline contact is required';
                }
                if (!RegExp(r'^[0-9+\-\s]{7,15}$').hasMatch(value.trim())) {
                  return 'Enter a valid contact number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return PremiumButton(
      text: 'Update Profile',
      onPressed: _updateAdminProfile,
      isLoading: isUpdating,
    );
  }

  // -------------------------------------------------------------------------
  // Security section — Forgot Password, Logout
  // -------------------------------------------------------------------------
  Widget _buildSecuritySection() {
    return Column(
      children: [
        PremiumActionCard(
          icon: Icons.mail_lock_outlined,
          title: 'Forgot Password',
          subtitle: 'Send a password reset link to your email',
          trailing: isSendingResetEmail
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.accent),
          )
              : null,
          onTap: isSendingResetEmail ? () {} : _sendPasswordResetEmail,
        ),
        const SizedBox(height: 12),
        PremiumActionCard(
          icon: Icons.logout_rounded,
          title: 'Terminate Console Session',
          subtitle: 'Sign out of the admin console',
          iconColor: AppColors.error,
          onTap: _handleLogout,
        ),
      ],
    );
  }
}

class _StatData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatData(
      this.title, this.value, this.icon, this.color, this.subtitle);
}

// ---------------------------------------------------------------------------
// Shared card container
// ---------------------------------------------------------------------------
class _PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _PremiumCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard stat card — animated counter, hover + press animation
// ---------------------------------------------------------------------------
class DashboardStatCard extends StatefulWidget {
  final _StatData data;
  final bool isLoading;

  const DashboardStatCard({
    super.key,
    required this.data,
    required this.isLoading,
  });

  @override
  State<DashboardStatCard> createState() => _DashboardStatCardState();
}

class _DashboardStatCardState extends State<DashboardStatCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? widget.data.color.withOpacity(0.4)
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.05 : 0.01),
                  blurRadius: _isHovered ? 12 : 6,
                  offset: Offset(0, _isHovered ? 4 : 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.data.icon,
                    color: widget.data.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.data.title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      widget.isLoading
                          ? Container(
                              height: 22,
                              width: 35,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          : TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 0, end: widget.data.value),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => Text(
                                '$value',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                      const SizedBox(height: 1),
                      Text(
                        widget.data.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textFaint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// Reusable text field

class PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool readOnly;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: readOnly ? AppColors.textMuted : AppColors.primary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? AppColors.background : Colors.white,
            prefixIcon: Icon(prefixIcon, color: AppColors.accent, size: 20),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.inter(color: AppColors.textFaint, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable primary button
// ---------------------------------------------------------------------------
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF42A5F5),
            Color(0xFF1E88E5),
            Color(0xFF1565C0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.5),
            blurRadius: 35,
            spreadRadius: 3,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
            key: ValueKey("loading"),
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : Text(
            text,
            key: const ValueKey("label"),
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

// ---------------------------------------------------------------------------
// Reusable action card (icon, title, subtitle, chevron, hover + press)
// ---------------------------------------------------------------------------
class PremiumActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? trailing;

  const PremiumActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor = AppColors.accent,
    this.trailing,
  });

  @override
  State<PremiumActionCard> createState() => _PremiumActionCardState();
}

class _PremiumActionCardState extends State<PremiumActionCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 0.98 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovered
                      ? widget.iconColor.withOpacity(0.35)
                      : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isPressed ? 0.01 : 0.02),
                    blurRadius: _isPressed ? 6 : 10,
                    offset: Offset(0, _isPressed ? 2 : 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 22),
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
                            color: AppColors.primary,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  widget.trailing ??
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}