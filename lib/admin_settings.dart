// ============================================================================
// CityConnect - Municipal Complaint Management System
// Admin Settings / Administration Console
// ============================================================================
// Production-quality admin dashboard page built with Flutter + Firebase.
// Includes: profile header, live dashboard stats, editable admin profile,
// read-only system info, security actions, recent activity feed, and a
// change-password flow. Designed to read like a government/SaaS admin
// console rather than a generic user profile screen.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  String department = '';
  String remarks = '';
  String accountStatus = 'Active';
  String role = 'Super Admin';
  bool emailVerified = false;
  DateTime? registeredAt;
  DateTime? lastLoginAt;

  // Dashboard counters
  int totalUsers = 0;
  int totalComplaints = 0;
  int pendingComplaints = 0;
  int resolvedComplaints = 0;
  bool isStatsLoading = true;

  List<Map<String, dynamic>> recentActivity = [];
  bool isActivityLoading = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController();
  final departmentController = TextEditingController();
  final remarksController = TextEditingController();

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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _loadAdminData();
    _loadDashboardStats();
    _loadRecentActivity();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    departmentController.dispose();
    remarksController.dispose();
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
        emailVerified = user.emailVerified;

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
          department = data['Department']?.toString() ?? '';
          remarks = data['Remarks']?.toString() ?? '';
          accountStatus = data['AccountStatus']?.toString() ?? 'Active';
          role = data['Role']?.toString() ?? 'Super Admin';

          final createdRaw = data['CreatedAt'];
          if (createdRaw is Timestamp) registeredAt = createdRaw.toDate();

          nameController.text = adminName;
          emailController.text = adminEmail;
          contactController.text = adminContact;
          departmentController.text = department;
          remarksController.text = remarks;
        } else {
          adminEmail = user.email ?? '';
          emailController.text = adminEmail;
        }

        lastLoginAt = user.metadata.lastSignInTime;
        registeredAt ??= user.metadata.creationTime;
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
        firestore.collection('Users').count().get(),
        firestore.collection('Complaints').count().get(),
        firestore
            .collection('Complaints')
            .where('Status', isEqualTo: 'Pending')
            .count()
            .get(),
        firestore
            .collection('Complaints')
            .where('Status', isEqualTo: 'Resolved')
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
    } finally {
      if (mounted) setState(() => isStatsLoading = false);
    }
  }

  Future<void> _loadRecentActivity() async {
    setState(() => isActivityLoading = true);
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('ActivityLogs')
          .where('AdminUid', isEqualTo: user.uid)
          .orderBy('Timestamp', descending: true)
          .limit(5)
          .get();

      if (mounted) {
        setState(() {
          recentActivity = snapshot.docs
              .map((d) => d.data())
              .toList()
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading recent activity: $e');
    } finally {
      if (mounted) setState(() => isActivityLoading = false);
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
        'Department': departmentController.text.trim(),
        'Remarks': remarksController.text.trim(),
      };

      if (docId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('AdminDetails')
            .doc(docId)
            .update(updateData);
      } else {
        final User? user = FirebaseAuth.instance.currentUser;
        final newDoc = await FirebaseFirestore.instance
            .collection('AdminDetails')
            .add({
          'AdminEmail': user?.email ?? emailController.text.trim(),
          'AccountStatus': 'Active',
          'Role': 'Super Admin',
          'CreatedAt': FieldValue.serverTimestamp(),
          ...updateData,
        });
        docId = newDoc.id;
      }

      setState(() {
        adminName = nameController.text.trim();
        adminContact = contactController.text.trim();
        department = departmentController.text.trim();
        remarks = remarksController.text.trim();
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
      message:
      'A password reset link will be sent to $adminEmail. Continue?',
      confirmLabel: 'Send Email',
      confirmColor: AppColors.accent,
    );
    if (confirmed != true) return;

    setState(() => isSendingResetEmail = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: adminEmail);
      _showSnack('Password reset email sent to $adminEmail', AppColors.success);
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
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: confirmColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          await Future.wait([
            _loadAdminData(),
            _loadDashboardStats(),
            _loadRecentActivity(),
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
                  final bool isWide = constraints.maxWidth > 720;
                  return Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildDashboardStats(isWide),
                      const SizedBox(height: 24),
                      isWide
                          ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildAdminInfoCard(),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: _buildSystemInfoCard(),
                            ),
                          ],
                        ),
                      )
                          : Column(
                        children: [
                          _buildAdminInfoCard(),
                          const SizedBox(height: 20),
                          _buildSystemInfoCard(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildUpdateButton(),
                      const SizedBox(height: 32),
                      _buildSectionLabel('Console Security'),
                      const SizedBox(height: 12),
                      _buildSecuritySection(),
                      const SizedBox(height: 32),
                      _buildSectionLabel('Recent Activity'),
                      const SizedBox(height: 12),
                      _buildRecentActivityCard(),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
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
    final String displayId =
    adminUid.length > 8 ? adminUid.substring(0, 8).toUpperCase() : 'ADMIN-CC';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Hero(
            tag: 'admin-avatar',
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 3),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.accent,
                    size: 56,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration:
                  const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            adminName.isEmpty ? 'System Administrator' : adminName,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            adminEmail,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textFaint),
          ),
          if (department.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              department,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textFaint),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _headerBadge(
                icon: Icons.shield_rounded,
                label: 'SUPER ADMIN',
                color: AppColors.accent,
              ),
              _headerBadge(
                icon: Icons.badge_outlined,
                label: 'ID: $displayId',
                color: const Color(0xFF64748B),
                mono: true,
              ),
            ],
          ),
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
                fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFCBD5E1))
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
  // Dashboard stats
  // -------------------------------------------------------------------------
  Widget _buildDashboardStats(bool isWide) {
    final stats = [
      _StatData('Total Users', totalUsers, Icons.groups_rounded, AppColors.accent,
          'Registered citizens'),
      _StatData('Total Complaints', totalComplaints, Icons.report_rounded,
          const Color(0xFF8B5CF6), 'All time submissions'),
      _StatData('Pending', pendingComplaints, Icons.hourglass_top_rounded, AppColors.warning,
          'Awaiting action'),
      _StatData('Resolved', resolvedComplaints, Icons.task_alt_rounded, AppColors.success,
          'Successfully closed'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isWide ? 1.35 : 1.25,
      ),
      itemBuilder: (context, i) => DashboardStatCard(
        data: stats[i],
        isLoading: isStatsLoading,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Admin info card
  // -------------------------------------------------------------------------
  Widget _buildAdminInfoCard() {
    return _PremiumCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(Icons.badge_rounded, 'Administrative Officer Details'),
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
            const SizedBox(height: 20),
            PremiumTextField(
              controller: departmentController,
              label: 'Assigned Department',
              prefixIcon: Icons.account_balance_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Department assignment is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            PremiumTextField(
              controller: remarksController,
              label: 'Remarks & Security Notes',
              prefixIcon: Icons.sticky_note_2_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // System info card
  // -------------------------------------------------------------------------
  Widget _buildSystemInfoCard() {
    final String displayId =
    adminUid.length > 8 ? adminUid.substring(0, 8).toUpperCase() : 'ADMIN-CC';
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');

    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.dns_rounded, 'System Information'),
          const Divider(height: 32, color: AppColors.border),
          SystemInfoRow(label: 'Admin ID', value: displayId, mono: true),
          SystemInfoRow(
            label: 'Account Status',
            value: accountStatus,
            valueColor: accountStatus.toLowerCase() == 'active'
                ? AppColors.success
                : AppColors.error,
            badge: true,
          ),
          SystemInfoRow(label: 'Role', value: role),
          SystemInfoRow(
            label: 'Registration Date',
            value: registeredAt != null ? dateFmt.format(registeredAt!) : '—',
          ),
          SystemInfoRow(
            label: 'Last Login',
            value: lastLoginAt != null ? dateFmt.format(lastLoginAt!) : '—',
          ),
          SystemInfoRow(
            label: 'Email Verified',
            value: emailVerified ? 'Verified' : 'Unverified',
            valueColor: emailVerified ? AppColors.success : AppColors.warning,
            badge: true,
            isLast: true,
          ),
        ],
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
              color: AppColors.primary,
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
  // Security section
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
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
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

  // -------------------------------------------------------------------------
  // Recent activity
  // -------------------------------------------------------------------------
  Widget _buildRecentActivityCard() {
    return _PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isActivityLoading
          ? const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
      )
          : recentActivity.isEmpty
          ? Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No recent activity yet',
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          ),
        ),
      )
          : Column(
        children: recentActivity
            .map((activity) => ActivityTile(activity: activity))
            .toList(),
      ),
    );
  }
}

class _StatData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatData(this.title, this.value, this.icon, this.color, this.subtitle);
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
// Dashboard stat card
// ---------------------------------------------------------------------------
class DashboardStatCard extends StatelessWidget {
  final _StatData data;
  final bool isLoading;

  const DashboardStatCard({super.key, required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const Spacer(),
          isLoading
              ? Container(
            height: 22,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(6),
            ),
          )
              : Text(
            '${data.value}',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            data.subtitle,
            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// System info row
// ---------------------------------------------------------------------------
class SystemInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;
  final bool badge;
  final bool isLast;

  const SystemInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
    this.badge = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = valueColor ?? AppColors.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          if (badge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            )
          else
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: mono
                    ? GoogleFonts.jetBrainsMono(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: color)
                    : GoogleFonts.inter(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: color),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity tile
// ---------------------------------------------------------------------------
class ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityTile({super.key, required this.activity});

  IconData _iconFor(String type) {
    switch (type) {
      case 'ComplaintAssigned':
        return Icons.assignment_ind_rounded;
      case 'ComplaintApproved':
        return Icons.check_circle_rounded;
      case 'ComplaintRejected':
        return Icons.cancel_rounded;
      case 'UserAccountCreated':
        return Icons.person_add_alt_1_rounded;
      case 'StaffAdded':
        return Icons.group_add_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'ComplaintAssigned':
        return AppColors.accent;
      case 'ComplaintApproved':
        return AppColors.success;
      case 'ComplaintRejected':
        return AppColors.error;
      case 'UserAccountCreated':
        return const Color(0xFF8B5CF6);
      case 'StaffAdded':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String type = activity['Type']?.toString() ?? 'Unknown';
    final String description = activity['Description']?.toString() ?? type;
    final Timestamp? ts = activity['Timestamp'] as Timestamp?;
    final String timeText = ts != null
        ? DateFormat('MMM d, h:mm a').format(ts.toDate())
        : '';
    final Color color = _colorFor(type);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(_iconFor(type), color: color, size: 18),
      ),
      title: Text(
        description,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      subtitle: timeText.isNotEmpty
          ? Text(timeText, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable text field
// ---------------------------------------------------------------------------
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
        )
            : Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable action card (with subtitle + press animation)
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
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
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              widget.trailing ??
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}