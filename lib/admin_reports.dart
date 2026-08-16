import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'pdf_admin.dart';
import 'admin.dart';

/// Standalone Reports Page Widget featuring a searchable city dropdown modal,
/// date range filtering, PDF export, and complaint history.
class AdminReportsPage extends StatefulWidget {
  final Map<String, String>? userCities;
  final List<String>? citiesList;

  const AdminReportsPage({
    super.key,
    this.userCities,
    this.citiesList,
  });

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  DateTime? reportFromDate;
  DateTime? reportToDate;
  String reportSelectedCity = 'All Cities';

  Map<String, String> _userCities = {};
  List<String> _citiesList = [];

  @override
  void initState() {
    super.initState();
    if (widget.userCities != null) {
      _userCities = widget.userCities!;
    } else {
      _loadUserCities();
    }

    if (widget.citiesList != null) {
      _citiesList = widget.citiesList!;
    } else {
      _loadCities();
    }
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
          _userCities = tempMap;
        });
      }
    } catch (e) {
      debugPrint('Error loading user cities in reports: $e');
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
          _citiesList = list;
        });
      }
    } catch (e) {
      debugPrint('Error loading cities in reports: $e');
    }
  }

  /// Opens the Searchable City Selection Modal Bottom Sheet
  void _openCitySearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredCities = _citiesList.where((cityName) {
              return cityName.toLowerCase().contains(searchQuery.trim().toLowerCase());
            }).toList();

            final options = ['All Cities', ...filteredCities];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(bottomSheetContext).size.height * 0.70,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle Bar
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Header Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Select City",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                            onPressed: () => Navigator.pop(bottomSheetContext),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Search Field in Bottom Sheet
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: TextField(
                        autofocus: true,
                        onChanged: (val) {
                          setSheetState(() {
                            searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search city name...",
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setSheetState(() {
                                      searchQuery = "";
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),

                    // Filtered List of Cities
                    Expanded(
                      child: options.isEmpty
                          ? Center(
                              child: Text(
                                "No cities found matching \"$searchQuery\"",
                                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: options.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1, indent: 60, endIndent: 20),
                              itemBuilder: (context, index) {
                                final cityName = options[index];
                                final isSelected = cityName.toLowerCase() == reportSelectedCity.toLowerCase();

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                                          : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      cityName == 'All Cities'
                                          ? Icons.location_off_outlined
                                          : Icons.location_city_outlined,
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    cityName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF2563EB),
                                          size: 22,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      reportSelectedCity = cityName;
                                    });
                                    Navigator.pop(bottomSheetContext);
                                  },
                                );
                              },
                            ),
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

  Future<void> _exportToPdf(List<QueryDocumentSnapshot> docs) async {
    await generateAdminComplaintPdf(
      docs: docs,
      userCities: _userCities,
      reportFromDate: reportFromDate,
      reportToDate: reportToDate,
      reportSelectedCity: reportSelectedCity,
    );
  }

  @override
  Widget build(BuildContext context) {
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

        List<QueryDocumentSnapshot> filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          DateTime? createdAt;
          if (data['CreatedAt'] != null && data['CreatedAt'] is Timestamp) {
            createdAt = (data['CreatedAt'] as Timestamp).toDate();
          }

          if (reportFromDate != null && createdAt != null) {
            final startOfFrom = DateTime(reportFromDate!.year, reportFromDate!.month, reportFromDate!.day);
            if (createdAt.isBefore(startOfFrom)) return false;
          }
          if (reportToDate != null && createdAt != null) {
            final endOfTo = DateTime(reportToDate!.year, reportToDate!.month, reportToDate!.day, 23, 59, 59, 999);
            if (createdAt.isAfter(endOfTo)) return false;
          }

          // City Filter via Searchable Dropdown Selection
          if (reportSelectedCity != 'All Cities') {
            final userId = (data['UserID'] ?? '').toString();
            final userCity = (_userCities[userId] ?? data['City'] ?? '').toString();
            final address = (data['Address'] ?? '').toString();

            final queryCity = reportSelectedCity.toLowerCase().trim();
            final matchesUserCity = userCity.toLowerCase().trim() == queryCity;
            final matchesAddress = address.toLowerCase().contains(queryCity);

            if (!matchesUserCity && !matchesAddress) return false;
          }

          return true;
        }).toList();

        // Sort newest-first
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
            // Filter card
            Padding(
              padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FILTER COMPLAINTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Searchable City Dropdown Field
                    Text(
                      'Select City',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _openCitySearchBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_city_rounded, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reportSelectedCity,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date range pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: reportFromDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  reportFromDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      reportFromDate == null
                                          ? 'From Date'
                                          : DateFormat('dd/MM/yyyy').format(reportFromDate!),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: reportFromDate == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
                                        fontWeight: reportFromDate == null ? FontWeight.normal : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: reportToDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  reportToDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      reportToDate == null
                                          ? 'To Date'
                                          : DateFormat('dd/MM/yyyy').format(reportToDate!),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: reportToDate == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
                                        fontWeight: reportToDate == null ? FontWeight.normal : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (reportFromDate != null || reportToDate != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              reportFromDate = null;
                              reportToDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear, size: 14, color: Color(0xFFEF4444)),
                          label: const Text(
                            'Clear Dates',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredDocs.length} complaints found',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: filteredDocs.isEmpty
                        ? null
                        : () => _exportToPdf(filteredDocs),
                    icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                    label: const Text(
                      'Export PDF',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Complaints list
            Expanded(
              child: filteredDocs.isEmpty
                  ? const Center(
                      child: Text(
                        'No complaints match the filters',
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
                        String userId = (data['UserID'] ?? '').toString();
                        String city = _userCities[userId] ?? (data['City'] ?? 'N/A').toString();

                        String dateText = '';
                        if (data['CreatedAt'] != null && data['CreatedAt'] is Timestamp) {
                          DateTime date = (data['CreatedAt'] as Timestamp).toDate();
                          dateText = DateFormat('dd/MM/yyyy').format(date);
                        }

                        Color statusColor = const Color(0xFFF59E0B);
                        if (status == 'In Progress') {
                          statusColor = const Color(0xFF3B82F6);
                        } else if (status == 'Resolved') {
                          statusColor = const Color(0xFF22C55E);
                        }

                        String imageUrl = (data['ImageUrl'] ?? data['Image'] ?? '').toString();
                        String complaintDesc = (data['ComplaintDescription'] ?? '').toString();

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
                                      complaintDescription: complaintDesc,
                                      currentStatus: status,
                                      dateText: dateText,
                                      imageUrl: imageUrl,
                                      isAdmin: true,
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
                                            'Citizen: $name ($contact)',
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'City: $city',
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF111827), fontWeight: FontWeight.w500),
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
}
