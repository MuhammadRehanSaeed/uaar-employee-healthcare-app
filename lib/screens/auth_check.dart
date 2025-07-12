import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'first_aid_screen.dart';
import 'full_medical_service.dart';
import 'login_screen.dart';

class AuthCheck extends StatefulWidget {
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    checkUserStatus();
  }

  void checkUserStatus() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Check in students collection
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection("students")
          .doc(user.uid)
          .get();

      if (studentDoc.exists) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FirstAidScreen()),
          );
        });
        return;
      }

      // Check in employees collection
      DocumentSnapshot employeeDoc = await FirebaseFirestore.instance
          .collection("employees")
          .doc(user.uid)
          .get();

      if (employeeDoc.exists) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FullMedical()),
          );
        });
        return;
      }

      // Check in doctors collection
      DocumentSnapshot doctorDoc = await FirebaseFirestore.instance
          .collection("doctors")
          .doc(user.uid)
          .get();

      if (doctorDoc.exists) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FullMedical()), // Navigate to the Doctor Dashboard
          );
        });
        return;
      }
    }

    // If no user is logged in, navigate to Login Page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
