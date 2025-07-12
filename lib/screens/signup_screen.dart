import 'dart:math';
import 'package:employeehealthcare/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aridNumberController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();

  String selectedRole = "student";
  bool _isPasswordVisible = false;

  Future<void> signUpUser(BuildContext context) async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String aridNumber = aridNumberController.text.trim();
    String department = departmentController.text.trim();
    String designation = designationController.text.trim();
    String employeeId = employeeIdController.text.trim();
    String specialization = specializationController.text.trim();

    // Validate fields
    if (name.isEmpty || email.isEmpty || password.isEmpty ||
        (selectedRole == "student" && (aridNumber.isEmpty || department.isEmpty)) ||
        (selectedRole == "employee" && (designation.isEmpty || employeeId.isEmpty)) ||
        (selectedRole == "doctor" && (designation.isEmpty || specialization.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (selectedRole == "employee") {
      QuerySnapshot existing = await FirebaseFirestore.instance
          .collection("employees")
          .where("employeeId", isEqualTo: employeeId)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Employee ID already exists"),
            backgroundColor: Colors.red,
          ),
        );
        return; // Stop signup
      }
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String userId = userCredential.user!.uid;
      CollectionReference usersCollection = FirebaseFirestore.instance.collection(selectedRole == "student"
          ? "students"
          : selectedRole == "employee"
          ? "employees"
          : "doctors");

      int uniqueId = Random().nextInt(900) + 100;

      Map<String, dynamic> userData = {
        "id": uniqueId,
        "name": name,
        "email": email,
        "role": selectedRole,
      };

      if (selectedRole == "student") {
        userData["aridNumber"] = aridNumber;
        userData["department"] = department;
      } else if (selectedRole == "employee") {
        userData["designation"] = designation;
        userData["employeeId"] = employeeId;
      } else if (selectedRole == "doctor") {
        userData["designation"] = designation;
        userData["specialization"] = specialization;
      }

      await usersCollection.doc(userId).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Signup Successful"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Clear fields
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      aridNumberController.clear();
      departmentController.clear();
      designationController.clear();
      employeeIdController.clear();
      specializationController.clear();

      // Navigate to login
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred";

      if (e.code == 'weak-password') {
        errorMessage = "The password is too weak.";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already in use.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.35,
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Image.asset(
                  "assets/images/splash_logo.png",
                  height: screenHeight * 0.25,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.30,
            left: 20,
            right: 20,
            child: SizedBox(
              height: screenHeight * 0.65,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Create new account",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildUserSelectionButtons(),
                      const SizedBox(height: 25),
                      _buildTextField("Name", nameController, false, Icons.person),
                      const SizedBox(height: 15),
                      _buildTextField("Email", emailController, false, Icons.email),
                      if (selectedRole == "student") ...[
                        const SizedBox(height: 15),
                        _buildTextField("Arid Number", aridNumberController, false, Icons.badge),
                        const SizedBox(height: 15),
                        _buildTextField("Department", departmentController, false, Icons.school),
                      ],
                      if (selectedRole == "employee") ...[
                        const SizedBox(height: 15),
                        _buildTextField("Designation", designationController, false, Icons.work),
                        const SizedBox(height: 15),
                        _buildTextField("Employee ID", employeeIdController, false, Icons.card_membership),
                      ],
                      if (selectedRole == "doctor") ...[
                        const SizedBox(height: 15),
                        _buildTextField("Designation", designationController, false, Icons.medical_services),
                        const SizedBox(height: 15),
                        _buildTextField("Specialization", specializationController, false, Icons.local_hospital),
                      ],
                      const SizedBox(height: 15),
                      _buildTextField("Password", passwordController, true, Icons.lock),
                      const SizedBox(height: 25),
                      _buildRegisterButton(screenWidth),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? ", style: TextStyle(color: Colors.green)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
    );
  }

  Widget _buildUserSelectionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildUserTypeButton("Student", "student"),
        _buildUserTypeButton("Employee", "employee"),
        _buildUserTypeButton("Doctor", "doctor"),
      ],
    );
  }

  Widget _buildUserTypeButton(String text, String role) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => setState(() => selectedRole = role),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selectedRole == role ? Colors.green : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: selectedRole == role ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isPassword, IconData icon) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: Icon(icon, color: Colors.green),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.green,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        )
            : null,
      ),
    );
  }

  Widget _buildRegisterButton(double screenWidth) {
    return ElevatedButton(
      onPressed: () {
        signUpUser(context);
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(screenWidth * 0.85, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.green,
        elevation: 8,
      ),
      child: const Text(
        "Register",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
