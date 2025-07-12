import 'dart:io';
import 'dart:convert';
import 'package:employeehealthcare/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userType;
  Map<String, dynamic>? userData;
  File? _imageFile;
  String? profileImageUrl;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final String imgurClientId = 'YOUR_IMGUR_CLIENT_ID'; // <<== PUT your Imgur Client ID here

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot studentDoc = await _firestore.collection('students').doc(user.uid).get();
        DocumentSnapshot employeeDoc = await _firestore.collection('employees').doc(user.uid).get();
        DocumentSnapshot doctorDoc = await _firestore.collection('doctors').doc(user.uid).get();

        if (studentDoc.exists) {
          setState(() {
            userType = "students";
            userData = studentDoc.data() as Map<String, dynamic>;
            profileImageUrl = userData?['profileImage'];
          });
        } else if (employeeDoc.exists) {
          setState(() {
            userType = "employees";
            userData = employeeDoc.data() as Map<String, dynamic>;
            profileImageUrl = userData?['profileImage'];
          });
        } else if (doctorDoc.exists) {
          setState(() {
            userType = "doctors";
            userData = doctorDoc.data() as Map<String, dynamic>;
            profileImageUrl = userData?['profileImage'];
          });
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Widget buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          controller: TextEditingController(text: value),
          readOnly: true,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  void showImagePickerOptions() {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await uploadImageToImgur();
    }
  }

  Future<void> uploadImageToImgur() async {
    User? user = _auth.currentUser;
    if (_imageFile == null || user == null || userType == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await _imageFile!.readAsBytes();
      String base64Image = base64Encode(bytes);

      final url = Uri.parse('https://api.imgur.com/3/image');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Client-ID $imgurClientId',
        },
        body: {
          'image': base64Image,
          'type': 'base64',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['data']['link'];

        await _firestore.collection(userType!).doc(user.uid).update({'profileImage': imageUrl});

        setState(() {
          profileImageUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Image Updated Successfully!")),
        );
      } else {
        debugPrint("Upload failed: ${response.body}");
        throw Exception("Failed to upload image to Imgur");
      }
    } on SocketException catch (e) {
      debugPrint("Socket Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No internet connection: $e")),
      );
    } catch (e) {
      debugPrint("Upload Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    List<Widget> fields = [];

    if (userType == "students") {
      fields = [
        buildReadOnlyField("Name", userData?['name'] ?? "N/A"),
        buildReadOnlyField("Email", userData?['email'] ?? "N/A"),
        buildReadOnlyField("Arid Number", userData?['aridNumber'] ?? "N/A"),
        buildReadOnlyField("Department", userData?['department'] ?? "N/A"),
        buildReadOnlyField("Role", userData?['role'] ?? "N/A"),
        buildReadOnlyField("ID", userData?['id']?.toString() ?? "N/A"),
      ];
    } else if (userType == "employees") {
      fields = [
        buildReadOnlyField("Name", userData?['name'] ?? "N/A"),
        buildReadOnlyField("Email", userData?['email'] ?? "N/A"),
        buildReadOnlyField("Designation", userData?['designation'] ?? "N/A"),
        buildReadOnlyField("Employee ID", userData?['employeeId']?.toString() ?? "N/A"),
        buildReadOnlyField("Role", userData?['role'] ?? "N/A"),
      ];
    } else if (userType == "doctors") {
      fields = [
        buildReadOnlyField("Name", userData?['name'] ?? "N/A"),
        buildReadOnlyField("Email", userData?['email'] ?? "N/A"),
        buildReadOnlyField("Specialization", userData?['specialization'] ?? "N/A"),
        buildReadOnlyField("Doctor ID", userData?['id']?.toString() ?? "N/A"),
        buildReadOnlyField("Role", userData?['role'] ?? "N/A"),
      ];
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // GestureDetector(
              //   onTapDown: (_) => _controller.forward(),
              //   onTapUp: (_) => _controller.reverse(),
              //   onTapCancel: () => _controller.reverse(),
              //   onTap: showImagePickerOptions,
              //   child: ScaleTransition(
              //     scale: _scaleAnimation,
              //     child: CircleAvatar(
              //       radius: 45,
              //       backgroundColor: Colors.green.shade50,
              //       backgroundImage: profileImageUrl != null
              //           ? NetworkImage(profileImageUrl!)
              //           : const AssetImage("assets/images/avatar.png") as ImageProvider,
              //       child: _isLoading
              //           ? const CircularProgressIndicator(color: Colors.green)
              //           : null,
              //     ),
              //   ),
              // ),
              const SizedBox(height: 20),
              const Text(
                "My Profile",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                userData?['email'] ?? "",
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 30),
              ...fields,
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout", style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
