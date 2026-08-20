import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'bottom_navigation_bar.dart';
import 'admin.dart';
import 'pdf_user.dart';


class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  String selectedFilter = "All";
  String selectedDepartmentFilter = "All";

  String _formatDepartmentName(String name) {
    String cleaned = name.replaceAll(RegExp(r'^[^\w\s]+'), '').trim();
    if (cleaned.isEmpty) return '';
    return cleaned.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }


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
    if (t.contains("sanit") || t.contains("senit") || t.contains("garbage")) {
      return Icons.cleaning_services;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ComplaintDetailsPage(
                  complaintId: complaint.id,
                  name: data["Name"] ?? "",
                  contact: data["Contact"] ?? "",
                  address: data["Address"] ?? "",
                  problemType: title,
                  complaintDescription: (data["ComplaintDescription"] ?? "").toString(),
                  currentStatus: status,
                  dateText: dateStr,
                  imageUrl: (data["ImageUrl"] ?? data["imageUrl"] ?? data["image"] ?? "").toString(),
                  isAdmin: false,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    if (status == "Pending")
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                'Delete Complaint',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                'Are you sure you want to permanently delete this complaint?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('ComplaintDescription')
                                  .doc(complaint.id)
                                  .delete();

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Complaint Deleted Successfully'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete complaint: $e'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ), // Column
          ), // Expanded

              ],
            ),

          ),
        ),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                    ],
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

                  final allDocs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);

                  // Sort newest first by CreatedAt timestamp
                  allDocs.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    final tA = dataA['CreatedAt'] is Timestamp
                        ? (dataA['CreatedAt'] as Timestamp).toDate()
                        : (dataA['createdAt'] is Timestamp
                            ? (dataA['createdAt'] as Timestamp).toDate()
                            : DateTime.fromMillisecondsSinceEpoch(0));
                    final tB = dataB['CreatedAt'] is Timestamp
                        ? (dataB['CreatedAt'] as Timestamp).toDate()
                        : (dataB['createdAt'] is Timestamp
                            ? (dataB['createdAt'] as Timestamp).toDate()
                            : DateTime.fromMillisecondsSinceEpoch(0));
                    return tB.compareTo(tA);
                  });

                  // Collect distinct department names dynamically from user complaints with case-insensitive deduplication
                  Map<String, String> deptMap = {};
                  for (var doc in allDocs) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String pType = (data['ProblemType'] ?? '').toString();
                    String formatted = _formatDepartmentName(pType);
                    if (formatted.isNotEmpty) {
                      deptMap[formatted.toLowerCase()] = formatted;
                    }
                  }
                  List<String> sortedDepts = deptMap.values.toList()..sort();
                  List<String> allAvailableDepartments = ['All', ...sortedDepts];

                  int countFor(String status) => allDocs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final st = (data["ComplaintStatus"] ?? "").toString();
                    final pType = (data["ProblemType"] ?? "").toString();
                    final formattedType = _formatDepartmentName(pType);

                    bool matchesStatus = st == status;
                    bool matchesDept = selectedDepartmentFilter == "All" ||
                        formattedType.toLowerCase() == selectedDepartmentFilter.toLowerCase() ||
                        pType.toLowerCase().contains(selectedDepartmentFilter.toLowerCase());

                    return matchesStatus && matchesDept;
                  }).length;

                  final filteredDocs = allDocs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final status = (data["ComplaintStatus"] ?? "").toString();
                    final pType = (data["ProblemType"] ?? "").toString();
                    final formattedType = _formatDepartmentName(pType);

                    bool matchesStatus = selectedFilter == "All" || status == selectedFilter;
                    bool matchesDept = selectedDepartmentFilter == "All" ||
                        formattedType.toLowerCase() == selectedDepartmentFilter.toLowerCase() ||
                        pType.toLowerCase().contains(selectedDepartmentFilter.toLowerCase());

                    return matchesStatus && matchesDept;
                  }).toList();

                  return Column(
                    children: [
                      // Department Filter Dropdown
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.business_rounded, size: 18, color: Color(0xFF2563EB)),
                              const SizedBox(width: 10),
                              const Text(
                                "Department:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: allAvailableDepartments.contains(selectedDepartmentFilter)
                                        ? selectedDepartmentFilter
                                        : 'All',
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                    items: allAvailableDepartments.map((dept) {
                                      return DropdownMenuItem<String>(
                                        value: dept,
                                        child: Text(
                                          dept == 'All' ? 'All Departments' : dept,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          selectedDepartmentFilter = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              if (selectedDepartmentFilter != 'All')
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedDepartmentFilter = 'All';
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${filteredDocs.length} complaints found",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: filteredDocs.isEmpty
                                  ? null
                                  : () => generateUserComplaintPdf(filteredDocs),
                              icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                              label: const Text(
                                "Export PDF",
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          filterChip("All", selectedDepartmentFilter == "All" ? allDocs.length : filteredDocs.length, "All"),
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
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}