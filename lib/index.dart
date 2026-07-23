import 'package:city_connect/alerts.dart';
import 'package:city_connect/complaint.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'profile.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _Index();
}

class _Index extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedDepartment;

  int currentIndex = 0;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("UserDetails")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nameController.text = data["Name"] ?? "";
          phoneController.text = data["Contact"] ?? "";
          addressController.text = data["Address"] ?? "";
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    String? selectedCity;
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      String? imageUrl;
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("complaint_images")
            .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

        if (kIsWeb) {
          await ref.putData(await _selectedImage!.readAsBytes());
        } else {
          await ref.putFile(File(_selectedImage!.path));
        }
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection("ComplaintDescription").add({
        "Name": nameController.text.trim(),
        "Contact": phoneController.text.trim(),
        "Address": addressController.text.trim(),
        "ProblemType": selectedDepartment,
        "ComplaintDescription": descriptionController.text.trim(),
        "ComplaintStatus": "Pending",
        "CreatedAt": FieldValue.serverTimestamp(),
        "UserID": user.uid,
        if (imageUrl != null) "ImageUrl": imageUrl,
      });

      setState(() {
        _selectedImage = null;
        selectedDepartment = null;
        descriptionController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complaint submitted successfully")),
      );

      print("Complaint Saved");
    } catch (e) {
      print("Error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;
    double screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Blue Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: const BoxDecoration(color: Color(0xFF1976D2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SUBMIT ISSUE",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "What problem are you facing?",
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "We will try to resolve your issue as soon as possible.",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF4F6FA),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // PERSONAL INFO CARD
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PERSONAL INFO",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 20),

                              TextFormField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  hintText: "Enter Your Name",
                                  prefixIcon: const Icon(Icons.person_outline),
                                  filled: true,
                                  fillColor: const Color(0xffF7F8FC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: "Enter Contact Number",
                                  prefixIcon: const Icon(Icons.call),
                                  filled: true,
                                  fillColor: const Color(0xffF7F8FC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // COMPLAINT DETAILS CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "COMPLAINT DETAILS",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 20),

                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection("DepartmentDetails")
                                    .orderBy("DepartmentName")
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Text("No Departments Found");
                                  }

                                  return DropdownButtonFormField<String>(
                                    value: selectedDepartment,
                                    decoration: InputDecoration(
                                      labelText: "Select Department",
                                      prefixIcon: const Icon(Icons.business),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    items: snapshot.data!.docs.map((doc) {
                                      return DropdownMenuItem<String>(
                                        value: doc["DepartmentName"],
                                        child: Text(doc["DepartmentName"]),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedDepartment = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return "Please select a department";
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 10),

                              TextFormField(
                                controller: addressController,
                                keyboardType: TextInputType.streetAddress,
                                decoration: InputDecoration(
                                  hintText: "Enter Your Address",
                                  prefixIcon: const Icon(
                                    Icons.pin_drop_outlined,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xffF7F8FC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please Enter Address";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: descriptionController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: "Enter Complaint Description",
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(bottom: 50),
                                    child: Icon(Icons.description_outlined),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xffF7F8FC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please Enter Complaint Description";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              Text(
                                "ATTACH PHOTO",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Center(
                                child: GestureDetector(
                                  onTap: pickImage,
                                  child: DottedBorder(
                                    options: RoundedRectDottedBorderOptions(
                                      color: Colors.blue,
                                      strokeWidth: 2,
                                      dashPattern: const [8, 4],
                                      radius: const Radius.circular(12),
                                      padding: const EdgeInsets.all(6),
                                    ),
                                    child: SizedBox(
                                      height: 200,
                                      width: screenWidth,
                                      child: _selectedImage == null
                                          ? const Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.cloud_upload_outlined,
                                                  size: 50,
                                                  color: Colors.blue,
                                                ),
                                                SizedBox(height: 10),
                                                Text("Tap To Upload a Photo"),
                                              ],
                                            )
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: kIsWeb
                                                  ? Image.network(
                                                      _selectedImage!.path,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    )
                                                  : Image.file(
                                                      File(
                                                        _selectedImage!.path,
                                                      ),
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : submitComplaint,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xff1976D2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Submit Complaint",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                MaterialPageRoute(builder: (context) => const HomeScreen()),
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
                MaterialPageRoute(builder: (context) => const ProfilePage()),
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
