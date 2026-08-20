import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Active', 'Blocked'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleUserBlockStatus({
    required String docId,
    required String userName,
    required bool currentlyBlocked,
  }) async {
    final bool newBlockedState = !currentlyBlocked;
    final String actionText = newBlockedState ? 'Block' : 'Unblock';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '$actionText User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to $actionText "$userName"? ${newBlockedState ? "They will be restricted from accessing the application." : "They will regain full access to the application."}',
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
            child: Text(
              actionText,
              style: TextStyle(
                color: newBlockedState ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('UserDetails').doc(docId).update({
          'IsBlocked': newBlockedState,
          'isBlocked': newBlockedState,
          'Status': newBlockedState ? 'Blocked' : 'Active',
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User "$userName" has been ${newBlockedState ? "blocked" : "unblocked"} successfully.',
            ),
            backgroundColor: newBlockedState ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user status: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Registered Users',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search & Filter Header Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase().trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name, email, contact, or city...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status Filter Chips Row
                Row(
                  children: [
                    _buildFilterChip('All Users', 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Active Users', 'Active'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Blocked Users', 'Blocked'),
                  ],
                ),
              ],
            ),
          ),

          // User Stream & List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('UserDetails').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading users: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No registered users found.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                // Filter docs based on search query and status filter
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name = (data['Name'] ?? data['FullName'] ?? data['username'] ?? '').toString();
                  final email = (data['Email'] ?? data['email'] ?? '').toString();
                  final contact = (data['Contact'] ?? data['ContactNo'] ?? data['Phone'] ?? data['phone'] ?? '').toString();
                  final city = (data['City'] ?? data['city'] ?? '').toString();
                  final address = (data['Address'] ?? '').toString();

                  final bool isBlocked = (data['IsBlocked'] == true ||
                      data['isBlocked'] == true ||
                      data['Status'] == 'Blocked');

                  // Filter by Search Query
                  bool matchesQuery = _searchQuery.isEmpty ||
                      name.toLowerCase().contains(_searchQuery) ||
                      email.toLowerCase().contains(_searchQuery) ||
                      contact.toLowerCase().contains(_searchQuery) ||
                      city.toLowerCase().contains(_searchQuery) ||
                      address.toLowerCase().contains(_searchQuery);

                  // Filter by Status Tab
                  bool matchesStatus = true;
                  if (_statusFilter == 'Active') {
                    matchesStatus = !isBlocked;
                  } else if (_statusFilter == 'Blocked') {
                    matchesStatus = isBlocked;
                  }

                  return matchesQuery && matchesStatus;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users match your criteria.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = (data['Name'] ?? data['FullName'] ?? data['username'] ?? 'No Name').toString();
                    final email = (data['Email'] ?? data['email'] ?? 'No Email').toString();
                    final contact = (data['Contact'] ?? data['ContactNo'] ?? data['Phone'] ?? data['phone'] ?? 'N/A').toString();
                    final city = (data['City'] ?? data['city'] ?? 'N/A').toString();
                    final address = (data['Address'] ?? '').toString();

                    final bool isBlocked = (data['IsBlocked'] == true ||
                        data['isBlocked'] == true ||
                        data['Status'] == 'Blocked');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isBlocked
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Avatar circle with online/status indicator
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isBlocked
                                        ? const Color(0xFFFEE2E2)
                                        : const Color(0xFFEFF6FF),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: isBlocked
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF2563EB),
                                      size: 24,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: isBlocked
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isBlocked
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isBlocked ? 'BLOCKED' : 'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isBlocked
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          // Details Grid / List
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  contact,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                ),
                              ),
                              const Icon(Icons.location_city_outlined, size: 15, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                city,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.home_outlined, size: 15, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          // Action Button: Block or Unblock User
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _toggleUserBlockStatus(
                                docId: doc.id,
                                userName: name,
                                currentlyBlocked: isBlocked,
                              ),
                              icon: Icon(
                                isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                                size: 16,
                                color: isBlocked ? Colors.white : const Color(0xFFEF4444),
                              ),
                              label: Text(
                                isBlocked ? 'Unblock Account' : 'Block Account',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isBlocked ? Colors.white : const Color(0xFFEF4444),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBlocked ? const Color(0xFF2563EB) : const Color(0xFFFEF2F2),
                                elevation: 0,
                                side: BorderSide(
                                  color: isBlocked ? const Color(0xFF2563EB) : const Color(0xFFFCA5A5),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final bool isSelected = _statusFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _statusFilter = key;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
