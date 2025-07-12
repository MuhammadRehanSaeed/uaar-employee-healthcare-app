import 'package:employeehealthcare/screens/forgot_password.dart';
import 'package:employeehealthcare/screens/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = "student"; // student, employee, doctor
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Please fill in all fields.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        String userId = userCredential.user!.uid;

        // Check user role from Firestore collections
        DocumentSnapshot studentDoc = await FirebaseFirestore.instance
            .collection("students")
            .doc(userId)
            .get();

        DocumentSnapshot employeeDoc = await FirebaseFirestore.instance
            .collection("employees")
            .doc(userId)
            .get();

        DocumentSnapshot doctorDoc = await FirebaseFirestore.instance
            .collection("doctors")
            .doc(userId)
            .get();

        String? firestoreRole;

        if (selectedRole == "student" && studentDoc.exists) {
          firestoreRole = studentDoc["role"];
        } else if (selectedRole == "employee" && employeeDoc.exists) {
          firestoreRole = employeeDoc["role"];
        } else if (selectedRole == "doctor" && doctorDoc.exists) {
          firestoreRole = doctorDoc["role"];
        }

        if (firestoreRole == null || firestoreRole != selectedRole) {
          _showErrorDialog("You are not authorized to log in as a $selectedRole.");
          await FirebaseAuth.instance.signOut();
          return;
        }

        // Navigate to HomeScreen with role
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(role: selectedRole),
          ),
        );

      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog("Invalid Credentials");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
                    "Login to your account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildUserSelectionButtons(),
                  const SizedBox(height: 25),
                  _buildTextField("Email", emailController, false, Icons.email),
                  const SizedBox(height: 20),
                  _buildTextField("Password", passwordController, true, Icons.lock),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen()));
                      },
                      child: const Text("Forgot Password?", style: TextStyle(color: Colors.green)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLoginButton(screenWidth),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: Colors.green)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                        },
                        child: const Text(
                          "Register",
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

  Widget _buildUserTypeButton(String label, String roleValue) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () => setState(() => selectedRole = roleValue),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selectedRole == roleValue ? Colors.green : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selectedRole == roleValue ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.green),
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

  Widget _buildLoginButton(double screenWidth) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(screenWidth * 0.85, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.green,
        elevation: 8,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}
