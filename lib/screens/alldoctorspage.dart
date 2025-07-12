// keep your imports
import 'package:employeehealthcare/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Doctor_Detail_Page.dart';
import 'doctor_data.dart';

class AllDoctorsPage extends StatelessWidget {
  const AllDoctorsPage({super.key});

  Widget buildDoctorTile(Map<String, dynamic> doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.teal.shade50,
          ),
          child: ClipOval(
            child: Image.asset(doctor['image'], fit: BoxFit.cover),
          ),
        ),
        title: Text(doctor['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(doctor['type'], style: TextStyle(color: Colors.grey[700])),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text("${doctor['rating']}", style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Doctors", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔥 University Doctors from Firestore
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .where('role', isEqualTo: 'doctor')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox(); // or Text("No university doctors found")
              }

              final universityDocs = snapshot.data!.docs;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("University Doctors",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  const SizedBox(height: 12),
                  ...universityDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal.shade50,
                          ),
                          child: const Icon(Icons.person, color: Colors.teal, size: 30),
                        ),
                        title: Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['specialization'] ?? 'N/A',
                            style: TextStyle(color: Colors.grey[700])),
                        trailing: const Icon(Icons.email, color: Colors.teal),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatUserList()));
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // 👨‍⚕️ External Doctors from Firestore
          Text("External Doctors",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('externalDoctors')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No external doctors found");
              }

              final externalDocs = snapshot.data!.docs;

              return Column(
                children: externalDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Pick a random image from doctorList
                  final randomDoctor = doctorList[(data['name'].hashCode % doctorList.length)];

                  final doctorWithImage = {
                    'name': data['name'] ?? 'N/A',
                    'type': data['specialization'] ?? 'Specialist',
                    'rating': 4.5, // default rating or fetch if available
                    'image': randomDoctor['image'],
                  };

                  return GestureDetector(
                    onTap: () {
                      final doctorData = doctorList.firstWhere(
                            (docItem) => docItem['name'] == doc['name'],
                        orElse: () => {
                          'image': randomDoctor['image'],
                        },
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailPage(
                            doctorId: doc.id,
                            imagePath: doctorData['image'],
                          ),
                        ),
                      );
                    },
                    child: buildDoctorTile(doctorWithImage),
                  );

                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
