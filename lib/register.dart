import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'package:city_connect/index.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Index;

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isShow = true;
  bool agree = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController wardController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  String? selectedCity;

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully"),
        ),
      );
      await FirebaseFirestore.instance
          .collection("UserDetails")
          .doc(uid)
          .set({
        "Name": nameController.text.trim(),
        "Email": emailController.text.trim(),
        "Contact": phoneController.text.trim(),
        "Address": addressController.text.trim(),
        "City": cityController.text.trim(),
        "Ward": wardController.text.trim(),
        "Pincode": pincodeController.text.trim(),
        "Remarks": "",
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Registration failed"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.sizeOf(context).width;
    double screenHeight = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "JOIN CITYCONNECT",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Create Account",
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Fill in the details to get started",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    hintText: "Full Name",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter your full name";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: "Email address",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter your email";
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return "Enter Valid Email";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: passwordController,
                                  obscureText: isShow,
                                  decoration: InputDecoration(
                                    hintText: "Password",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isShow
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isShow = !isShow;
                                        });
                                      },
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_sharp,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter a password";
                                    }
                                    if (!RegExp(
                                      r'^.{6,}$',
                                    ).hasMatch(value)) {
                                      return "Enter a Strong Password";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: "Contact Number",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.phone_outlined,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter your contact number";
                                    }
                                    if (!RegExp(
                                      r'^[0-9]{10}$',
                                    ).hasMatch(value)) {
                                      return "Enter a valid 10-digit number";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection("CityDetails")
                                        .orderBy("CityName")
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      }

                                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                        return const Text("No Cities Found");
                                      }

                                      return DropdownButtonFormField<String>(
                                        value: selectedCity,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          hintText: "Select City",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          prefixIcon: const Icon(Icons.location_city),
                                        ),
                                        items: snapshot.data!.docs.map((doc) {
                                          return DropdownMenuItem<String>(
                                            value: doc["CityName"],
                                            child: Text(doc["CityName"]),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedCity = value;
                                            cityController.text = value!;


                                            var cityDoc = snapshot.data!.docs.firstWhere(
                                                  (doc) => doc["CityName"] == value,
                                            );

                                            pincodeController.text = cityDoc["CityPincode"];
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null) {
                                            return "Please select your city";
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                  ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: wardController,
                                  keyboardType: TextInputType.number,

                                  decoration: InputDecoration(
                                    hintText: "Enter Ward No.",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.maps_home_work_outlined,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter Ward Number";
                                    }
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                      return "Ward number must contain only digits";
                                    }
                                    final ward = int.tryParse(value);
                                    if (ward == null || ward < 1 || ward > 13) {
                                      return "Ward number must be between 1 and 13";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: addressController,
                                  keyboardType: TextInputType.streetAddress,
                                  decoration: InputDecoration(
                                    hintText: "Enter Address",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.location_city_outlined,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter Address";
                                    }
                                    if (!RegExp(
                                      r'^[a-zA-Z0-9\s.,#-]{3,100}$',
                                    ).hasMatch(value)) {
                                      return "Enter Valid Address";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                //   pincode
                                TextFormField(
                                  controller: pincodeController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "Enter Pincode",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.pin_drop),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter Pincode";
                                    }
                                    if (!RegExp(
                                      r'^[1-9][0-9]{5}$',
                                    ).hasMatch(value)) {
                                      return "Enter Valid Pincode";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Checkbox(
                              value: agree,
                              onChanged: (value) {
                                setState(() {
                                  agree = value!;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: "I agree to the ",
                                  children: [
                                    TextSpan(
                                      text: "Terms and Services",
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                    TextSpan(text: " and "),
                                    TextSpan(
                                      text: "Privacy & Policy",
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) return;

                                if (!agree) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please accept Terms & Conditions"),
                                    ),
                                  );
                                  return;
                                }
                                await registerUser();
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 55),
                                backgroundColor: const Color(0xFF2B7FD8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                "Register",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: const [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text("or"),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account?",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Login",
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}
