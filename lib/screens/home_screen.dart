// 🟢 HOME SCREEN 🟢
import 'package:employeehealthcare/screens/MedicalSlipListScreen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:employeehealthcare/screens/chat_screen.dart';
import 'package:employeehealthcare/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'first_aid_screen.dart';
import 'full_medical_service.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  const HomeScreen({Key? key, required this.role}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? employeeId;
  String? studentUID;
  bool isLoading = true;

  int unreadCount = 0;
  StreamSubscription? unreadSubscription;

  @override
  void initState() {
    super.initState();
    fetchUserId();
    listenToUnreadMessages();
  }

  @override
  void dispose() {
    unreadSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchUserId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (widget.role == "employee") {
      final doc = await FirebaseFirestore.instance.collection('employees').doc(uid).get();
      setState(() {
        employeeId = doc.data()?['employeeId'] ?? uid;
        isLoading = false;
      });
    } else {
      // ✅ For students, just use the UID directly
      setState(() {
        studentUID = uid;
        isLoading = false;
      });
    }
  }

  void listenToUnreadMessages() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    unreadSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unread = (data['unreadCount'] ?? {}) as Map;
        final unreadMap = Map<String, dynamic>.from(unread);

        final count = unreadMap[uid] ?? 0;
        total += count is int ? count : (count as num).toInt();
      }
      setState(() {
        unreadCount = total;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final List<Widget> pages = [
      widget.role == "student" ? FirstAidScreen() : FullMedical(),
      MedicalSlipListScreen(
        patientId: widget.role == "student" ? studentUID ?? "" : employeeId ?? "",
      ),
      ChatUserList(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Colors.green,
        animationDuration: const Duration(milliseconds: 300),
        height: 60,
        index: _selectedIndex,
        items: [
          const Icon(Icons.home, size: 30, color: Colors.white),
          const Icon(Icons.description_outlined, size: 30, color: Colors.white),
          buildChatIconWithBadge(),
          const Icon(Icons.person_outline, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget buildChatIconWithBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat_bubble_outline_outlined, size: 30, color: Colors.white),
        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
