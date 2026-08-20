import 'package:city_connect/admin_settings.dart';
import 'admin_reports.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';



class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  TextEditingController reportCitySearchController = TextEditingController();
  String reportCitySearchQuery = '';
  String selectedFilter = 'All';
  int currentIndex = 0;

  DateTime? reportFromDate;
  DateTime? reportToDate;
  String reportSelectedCity = 'All Cities';
  Map<String, String> userCities = {};
  List<String> citiesList = [];

  @override
  void initState() {
    super.initState();
    _loadUserCities();
    _loadCities();
  }

  Future<void> _loadUserCities() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('UserDetails').get();
      final Map<String, String> tempMap = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final city = (data['City'] ?? '').toString();
        tempMap[doc.id] = city;
      }
      if (mounted) {
        setState(() {
          userCities = tempMap;
        });
      }
    } catch (e) {
      debugPrint('Error loading user cities: $e');
    }
  }

  Future<void> _loadCities() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('CityDetails').get();
      final list = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return (data['CityName'] ?? '').toString().trim();
      }).where((name) => name.isNotEmpty).toList();
      
      list.sort();
      
      if (mounted) {
        setState(() {
          citiesList = list;
        });
      }
    } catch (e) {
      debugPrint('Error loading cities: $e');
    }
  }



  IconData _getDepartmentIcon(String title) {
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

  @override
  void dispose() {
    reportCitySearchController.dispose();
    super.dispose();
  }

  Widget _buildReportsBody() {
    return AdminReportsPage(
      userCities: userCities,
      citiesList: citiesList,
    );
  }

  Widget _buildDashboardBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ComplaintDescription')
          .orderBy('CreatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Something went wrong',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          );
        }

        List<QueryDocumentSnapshot> allDocs = snapshot.data!.docs;

        // ------------------ Count totals ------------------
        int totalCount = allDocs.length;
        int pendingCount = 0;
        int inProgressCount = 0;
        int resolvedCount = 0;

        for (var doc in allDocs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String status = (data['ComplaintStatus'] ?? '').toString();

          if (status == 'Pending') {
            pendingCount = pendingCount + 1;
          } else if (status == 'In Progress') {
            inProgressCount = inProgressCount + 1;
          } else if (status == 'Resolved') {
            resolvedCount = resolvedCount + 1;
          }
        }

        // ------------------ Apply status filter ------------------
        List<QueryDocumentSnapshot> filteredDocs = [];
        for (var doc in allDocs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String status = (data['ComplaintStatus'] ?? '').toString();

          // Status Filter
          if (selectedFilter == 'All' || status == selectedFilter) {
            filteredDocs.add(doc);
          }
        }

        // ------------------ Enforce newest-first sorting ------------------
        filteredDocs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final tA = dataA['CreatedAt'] is Timestamp
              ? (dataA['CreatedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final tB = dataB['CreatedAt'] is Timestamp
              ? (dataB['CreatedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return tB.compareTo(tA);
        });

        return Column(
          children: [
            // ================= Dashboard Cards =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      // ---- Total Complaints card ----
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.list_alt_rounded,
                                  color: Color(0xFF2563EB), size: 26),
                              const SizedBox(height: 10),
                              Text(
                                totalCount.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Total Complaints',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ---- Pending card ----
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.hourglass_empty_rounded,
                                  color: Color(0xFFF59E0B), size: 26),
                              const SizedBox(height: 10),
                              Text(
                                pendingCount.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // ---- In Progress card ----
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.autorenew_rounded,
                                  color: Color(0xFF3B82F6), size: 26),
                              const SizedBox(height: 10),
                              Text(
                                inProgressCount.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'In Progress',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ---- Resolved card ----
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  color: Color(0xFF22C55E), size: 26),
                              const SizedBox(height: 10),
                              Text(
                                resolvedCount.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Resolved',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ================= Filter Chips =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  // ---- All chip ----
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilter = 'All';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedFilter == 'All'
                              ? const Color(0xFF2563EB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selectedFilter == 'All'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          'All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selectedFilter == 'All'
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ---- Pending chip ----
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilter = 'Pending';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedFilter == 'Pending'
                              ? const Color(0xFF2563EB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selectedFilter == 'Pending'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selectedFilter == 'Pending'
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ---- In Progress chip ----
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilter = 'In Progress';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedFilter == 'In Progress'
                              ? const Color(0xFF2563EB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selectedFilter == 'In Progress'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          'In Progress',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selectedFilter == 'In Progress'
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ---- Resolved chip ----
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilter = 'Resolved';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedFilter == 'Resolved'
                              ? const Color(0xFF2563EB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selectedFilter == 'Resolved'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          'Resolved',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selectedFilter == 'Resolved'
                                ? Colors.white
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= Complaint List =================
            Expanded(
              child: filteredDocs.isEmpty
                  ? const Center(
                      child: Text(
                        'No complaints found',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        QueryDocumentSnapshot doc = filteredDocs[index];
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                        String name = (data['Name'] ?? '').toString();
                        String contact = (data['Contact'] ?? '').toString();
                        String address = (data['Address'] ?? '').toString();
                        String problemType = (data['ProblemType'] ?? '').toString();
                        String status = (data['ComplaintStatus'] ?? 'Pending').toString();

                        String dateText = '';
                        if (data['CreatedAt'] != null && data['CreatedAt'] is Timestamp) {
                          DateTime date = (data['CreatedAt'] as Timestamp).toDate();
                          dateText = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                        }

                        String imageUrl = (data['ImageUrl'] ?? data['imageUrl'] ?? data['image'] ?? '').toString();

                        Color statusColor = const Color(0xFFF59E0B);
                        if (status == 'In Progress') {
                          statusColor = const Color(0xFF3B82F6);
                        } else if (status == 'Resolved') {
                          statusColor = const Color(0xFF22C55E);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
                                      complaintId: doc.id,
                                      name: name,
                                      contact: contact,
                                      address: address,
                                      problemType: problemType,
                                      complaintDescription: (data['ComplaintDescription'] ?? '').toString(),
                                      currentStatus: status,
                                      dateText: dateText,
                                      imageUrl: imageUrl,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getDepartmentIcon(problemType),
                                        color: Colors.black87,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            problemType,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            name,
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            contact,
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            dateText,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        title: Text(
          currentIndex == 0 ? 'Admin Dashboard' : 'Complaints Reports',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2563EB)),
      ),
      body: currentIndex == 0 ? _buildDashboardBody() : _buildReportsBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2) {
            Navigator.push<int>(
              context,
              MaterialPageRoute(
                builder: (_) => AdminSettings(previousIndex: currentIndex),
              ),
            ).then((returnedIndex) {
              if (returnedIndex != null) {
                setState(() {
                  currentIndex = returnedIndex;
                });
              }
            });
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}


class ComplaintDetailsPage extends StatefulWidget {
  final String complaintId;
  final String name;
  final String contact;
  final String address;
  final String problemType;
  final String complaintDescription;
  final String currentStatus;
  final String dateText;
  final String imageUrl;
  final bool isAdmin;


  const ComplaintDetailsPage({
    super.key,
    required this.complaintId,
    required this.name,
    required this.contact,
    required this.address,
    required this.problemType,
    required this.complaintDescription,
    required this.currentStatus,
    required this.dateText,
    this.imageUrl = '',
    this.isAdmin = true,
  });

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  late String currentStatus;
  late String selectedStatus;
  bool isUpdating = false;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.currentStatus;
    selectedStatus = widget.currentStatus;
  }

  List<DropdownMenuItem<String>> _buildStatusDropdownItems() {
    final List<String> availableStatuses = [];
    // Only allow 'Pending' if current status of this complaint is 'Pending'
    if (currentStatus == 'Pending') {
      availableStatuses.add('Pending');
    }
    // Only allow 'In Progress' if current status is 'Pending' or 'In Progress'
    if (currentStatus == 'Pending' || currentStatus == 'In Progress') {
      availableStatuses.add('In Progress');
    }
    // 'Resolved' is always an available option
    availableStatuses.add('Resolved');

    if (!availableStatuses.contains(selectedStatus)) {
      availableStatuses.insert(0, selectedStatus);
    }

    return availableStatuses.map((status) {
      return DropdownMenuItem<String>(
        value: status,
        child: Text(status),
      );
    }).toList();
  }

  int currentIndex=0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: const Text(
          'Complaint Details',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Citizen Name',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Contact Number',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.contact,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Address',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.address,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Problem Type',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.problemType,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Complaint Description',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.complaintDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF111827),
                      height: 1.4,
                    ),
                  ),
                  if (widget.imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Uploaded Image',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(10),
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  widget.imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: const Color(0xFFF1F5F9),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_outlined,
                                      color: Color(0xFF94A3B8), size: 40),
                                  SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  const Text(
                    'Created Date',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.dateText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Current Status',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentStatus,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.isAdmin) ...[
              const SizedBox(height: 24),

              const Text(
                'Update Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                key: ValueKey('$currentStatus-$selectedStatus'),
                initialValue: selectedStatus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
                items: _buildStatusDropdownItems(),
                onChanged: currentStatus == 'Resolved'
                    ? null
                    : (value) {
                  if (value != null) {
                    setState(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (isUpdating || currentStatus == 'Resolved')
                      ? null
                      : () async {
                    if (currentStatus != 'Pending' && selectedStatus == 'Pending') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot change status back to Pending once in progress or resolved'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }

                    if (currentStatus == 'Resolved' && selectedStatus != 'Resolved') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot change status once complaint is marked as Resolved'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      isUpdating = true;
                    });

                    try {
                      await FirebaseFirestore.instance
                          .collection('ComplaintDescription')
                          .doc(widget.complaintId)
                          .update({
                        'ComplaintStatus': selectedStatus,
                      });

                      if (!mounted) return;

                      setState(() {
                        currentStatus = selectedStatus;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Status Updated Successfully'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF22C55E),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update status'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                    }

                    setState(() {
                      isUpdating = false;
                    });
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isUpdating
                        ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Text(
                      currentStatus == 'Resolved' ? 'Already Resolved' : 'Update Status',
                      key: const ValueKey('label'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: (isUpdating || isDeleting)
                      ? null
                      : () async {
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
                            setState(() {
                              isDeleting = true;
                            });

                            try {
                              await FirebaseFirestore.instance
                                  .collection('ComplaintDescription')
                                  .doc(widget.complaintId)
                                  .delete();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Complaint Deleted Successfully'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );

                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const AdminDashboardPage(),
                                ),
                                (route) => false,
                              );
                            } catch (e) {
                              if (!mounted) return;

                              setState(() {
                                isDeleting = false;
                              });

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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isDeleting
                        ? const SizedBox(
                            key: ValueKey('deleting_loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Row(
                            key: ValueKey('deleting_label'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Delete Complaint',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}