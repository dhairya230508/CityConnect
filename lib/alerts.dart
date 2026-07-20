import 'package:flutter/material.dart';

enum AlertSeverity { high, medium }

class MunicipalAlert {
  final String title;
  final String description;
  final String ward;
  final String date;
  final AlertSeverity severity;

  const MunicipalAlert({
    required this.title,
    required this.description,
    required this.ward,
    required this.date,
    required this.severity,
  });
}

class AlertsRepository {
  static List<MunicipalAlert> fetchAlerts() {
    return const [
      MunicipalAlert(
        title: 'Water Supply Interruption',
        description: 'Scheduled maintenance — 6AM to 2PM',
        ward: 'Ward 12',
        date: '25 Jun 2026',
        severity: AlertSeverity.high,
      ),
      MunicipalAlert(
        title: 'Road Maintenance Work',
        description: 'Main boulevard closed for resurfacing',
        ward: 'Ward 5',
        date: '26 Jun 2026',
        severity: AlertSeverity.medium,
      ),
      MunicipalAlert(
        title: 'Garbage Collection Delay',
        description: 'Collection postponed by 24 hours',
        ward: 'Ward 8',
        date: '27 Jun 2026',
        severity: AlertSeverity.high,
      ),
      MunicipalAlert(
        title: 'Electricity Maintenance',
        description: 'Grid upgrade — 10AM to 3PM outage',
        ward: 'Ward 3',
        date: '28 Jun 2026',
        severity: AlertSeverity.medium,
      ),
    ];
  }
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedNavIndex = 1;
  late final List<MunicipalAlert> _alerts;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.list_alt_outlined, label: 'Complaints'),
    _NavItem(icon: Icons.notifications_none, label: 'Alerts'),
    _NavItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _alerts = AlertsRepository.fetchAlerts();
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _alerts.isEmpty
                  ? const _EmptyAlertsView()
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  return AlertCard(alert: _alerts[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFF2F6BFF), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF2F6BFF),
                style: BorderStyle.solid,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'MUNICIPAL NOTICES',
              style: TextStyle(
                color: Color(0xFF2F6BFF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Alerts',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Stay informed about your ward',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = index == _selectedNavIndex;
            final color =
            isSelected ? const Color(0xFF2F6BFF) : Colors.grey.shade500;
            return InkWell(
              onTap: () => _onNavTap(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: color, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

class AlertCard extends StatelessWidget {
  final MunicipalAlert alert;

  const AlertCard({super.key, required this.alert});

  Color get _accentColor {
    switch (alert.severity) {
      case AlertSeverity.high:
        return const Color(0xFFE0453B);
      case AlertSeverity.medium:
        return const Color(0xFFE0A62E);
    }
  }

  Color get _iconBackgroundColor {
    switch (alert.severity) {
      case AlertSeverity.high:
        return const Color(0xFFFDEBEA);
      case AlertSeverity.medium:
        return const Color(0xFFFDF3E3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: _accentColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, color: _accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      alert.ward,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      alert.date,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlertsView extends StatelessWidget {
  const _EmptyAlertsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No alerts for your ward right now',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
