import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A searchable city picker field that streams cities from Firestore 'CityDetails'.
/// Tapping the field opens a modal bottom sheet with a real-time search field.
class SearchableCityField extends StatefulWidget {
  final TextEditingController cityController;
  final TextEditingController pincodeController;
  final String? label;
  final String hintText;
  final IconData prefixIcon;
  final Color primaryColor;
  final double borderRadius;
  final String? Function(String?)? validator;
  final bool isProfileStyle;

  const SearchableCityField({
    super.key,
    required this.cityController,
    required this.pincodeController,
    this.label,
    this.hintText = "Select City",
    this.prefixIcon = Icons.location_city,
    this.primaryColor = const Color(0xFF2563EB),
    this.borderRadius = 12,
    this.validator,
    this.isProfileStyle = false,
  });

  @override
  State<SearchableCityField> createState() => _SearchableCityFieldState();
}

class _SearchableCityFieldState extends State<SearchableCityField> {
  void _openCitySearchBottomSheet(
    BuildContext context,
    List<QueryDocumentSnapshot> cityDocs,
    FormFieldState<String> fieldState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredDocs = cityDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data["CityName"] ?? "").toString().toLowerCase();
              return name.contains(searchQuery.trim().toLowerCase());
            }).toList();

            final currentCity = widget.cityController.text.trim();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(bottomSheetContext).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Top Handle Indicator
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

                    // Header Title & Close Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Select City",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
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

                    // Search Input Box
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
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search, color: widget.primaryColor),
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
                          fillColor: const Color(0xFFF8FAFC),
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
                            borderSide:
                                BorderSide(color: widget.primaryColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),

                    // Filtered List of Cities
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No cities found matching \"$searchQuery\"",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredDocs.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1, indent: 60, endIndent: 20),
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final cityName =
                                    (data["CityName"] ?? "").toString().trim();
                                final cityPincode =
                                    (data["CityPincode"] ?? "").toString().trim();
                                final isSelected = cityName.toLowerCase() ==
                                    currentCity.toLowerCase();

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? widget.primaryColor.withValues(alpha: 0.1)
                                          : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_city_outlined,
                                      color: isSelected
                                          ? widget.primaryColor
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    cityName,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? widget.primaryColor
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                  subtitle: cityPincode.isNotEmpty
                                      ? Text(
                                          "Pincode: $cityPincode",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: widget.primaryColor,
                                          size: 22,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      widget.cityController.text = cityName;
                                      if (cityPincode.isNotEmpty) {
                                        widget.pincodeController.text = cityPincode;
                                      }
                                    });
                                    fieldState.didChange(cityName);
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("CityDetails")
          .orderBy("CityName")
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.isProfileStyle
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.label != null) ...[
                      Text(
                        widget.label!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
        }

        final cityDocs = snapshot.data?.docs ?? [];

        return FormField<String>(
          initialValue: widget.cityController.text,
          validator: widget.validator ??
              (val) {
                if (widget.cityController.text.trim().isEmpty) {
                  return "Please select your city";
                }
                return null;
              },
          builder: (fieldState) {
            final displayValue = widget.cityController.text.trim();

            Widget inputField = InkWell(
              onTap: cityDocs.isEmpty
                  ? null
                  : () => _openCitySearchBottomSheet(context, cityDocs, fieldState),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: widget.isProfileStyle
                      ? GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14)
                      : null,
                  filled: widget.isProfileStyle,
                  fillColor: widget.isProfileStyle ? Colors.white : null,
                  prefixIcon: Icon(
                    widget.prefixIcon,
                    color: widget.isProfileStyle
                        ? widget.primaryColor
                        : Colors.grey.shade700,
                    size: widget.isProfileStyle ? 20 : 24,
                  ),
                  suffixIcon: Icon(
                    Icons.search_rounded,
                    color: widget.primaryColor,
                    size: 22,
                  ),
                  contentPadding: widget.isProfileStyle
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                  enabledBorder: widget.isProfileStyle
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB), width: 1.5),
                        )
                      : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                        ),
                  focusedBorder: widget.isProfileStyle
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          borderSide:
                              BorderSide(color: widget.primaryColor, width: 2),
                        )
                      : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                        ),
                  errorBorder: widget.isProfileStyle
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          borderSide: const BorderSide(
                              color: Color(0xFFEF4444), width: 1.5),
                        )
                      : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                  errorText: fieldState.errorText,
                ),
                child: Text(
                  displayValue.isNotEmpty ? displayValue : widget.hintText,
                  style: widget.isProfileStyle
                      ? GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: displayValue.isNotEmpty
                              ? const Color(0xFF111827)
                              : const Color(0xFF9CA3AF),
                        )
                      : TextStyle(
                          fontSize: 16,
                          color: displayValue.isNotEmpty
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                ),
              ),
            );

            if (widget.isProfileStyle && widget.label != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  inputField,
                ],
              );
            }

            return inputField;
          },
        );
      },
    );
  }
}
