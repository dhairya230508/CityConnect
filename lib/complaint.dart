import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'home.dart';
import 'profile.dart';


class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  String selectedFilter = "All";

  int currentIndex = 0;


  Color _statusColor(String status) {
    switch (status) {
      case "Pending":
        return const Color(0xFFFFC107); // amber
      case "In Progress":
        return const Color(0xFF3B82F6); // blue
      case "Resolved":
        return const Color(0xFF22C55E); // green
      default:
        return Colors.grey;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case "Pending":
        return const Color(0xFFFFF3CD);
      case "In Progress":
        return const Color(0xFFDCEBFF);
      case "Resolved":
        return const Color(0xFFDCFCE7);
      default:
        return Colors.grey.shade200;
    }
  }

  IconData _categoryIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains("water")) return Icons.water_drop;
    if (t.contains("electric")) return Icons.bolt;
    if (t.contains("sanitation") || t.contains("garbage")) {
      return Icons.delete_outline;
    }
    if (t.contains("construction") || t.contains("road")) {
      return Icons.construction;
    }
    return Icons.report_outlined;
  }

  // ---- Filter chip (the count boxes, now tappable + filtering) ----

  Widget filterChip(String label, int value, String filterKey) {
    final bool isSelected = selectedFilter == filterKey;

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = filterKey),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(blurRadius: 5, color: Colors.black12),
          ],
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Complaint card ----

  Widget complaintCard(QueryDocumentSnapshot complaint) {
    final data = complaint.data() as Map<String, dynamic>;

    final String title = data["ProblemType"] ?? "Untitled";
    final String status = data["ComplaintStatus"] ?? "Pending";

    // Assumed field names — adjust to match your Firestore schema
    String dateStr = "";
    if (data["CreatedAt"] != null && data["CreatedAt"] is Timestamp) {
      final ts = (data["CreatedAt"] as Timestamp).toDate();
      dateStr = DateFormat("d MMM yyyy").format(ts);
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(_categoryIcon(title), color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBgColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (dateStr.isNotEmpty) ...[
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.black45),
                      const SizedBox(width: 3),
                      Text(dateStr,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "MY ACTIVITY",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "My Complaints",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("ComplaintDescription")
                    .where("UserID", isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No Complaints Found"));
                  }

                  final allDocs = snapshot.data!.docs;

                  int countFor(String status) => allDocs
                      .where((d) => (d["ComplaintStatus"] ?? "") == status)
                      .length;

                  final filteredDocs = selectedFilter == "All"
                      ? allDocs
                      : allDocs
                      .where((d) => (d["ComplaintStatus"] ?? "") == selectedFilter)
                      .toList();

                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          filterChip("All", allDocs.length, "All"),
                          filterChip(
                              "Pending", countFor("Pending"), "Pending"),
                          filterChip("In Progress",
                              countFor("In Progress"), "In Progress"),
                          filterChip(
                              "Resolved", countFor("Resolved"), "Resolved"),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredDocs.isEmpty
                            ? const Center(
                            child: Text("No complaints in this category"))
                            : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            return complaintCard(filteredDocs[index]);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

        ),
      ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,

            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            onTap: (index) {
              if (index == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const home()),
                );
              } else if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ComplaintPage()),
                );
              }
              else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "HOME",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: "COMPLAINTS",
              ),
              // BottomNavigationBarItem(
              //   icon: Icon(Icons.notifications_none),
              //   activeIcon: Icon(Icons.notifications),
              //   label: "ALERTS",
              // ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "PROFILE",
              ),
            ],
          ),
        ),
    );
  }
}