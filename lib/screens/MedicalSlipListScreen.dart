import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MedicalSlipModel.dart';
import 'MedicalSlipDetailScreen.dart';

class MedicalSlipListScreen extends StatelessWidget {
  final String patientId;

  MedicalSlipListScreen({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Medical Slips')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medicalSlips')
            .where('patientId', isEqualTo: patientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final slips = snapshot.data!.docs.map((doc) =>
              MedicalSlip.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();

          if (slips.isEmpty) return const Center(child: Text("No slips found"));

          return ListView.builder(
            itemCount: slips.length,
            itemBuilder: (context, index) {
              final slip = slips[index];
              return ListTile(
                title: Text(slip.doctor),
                subtitle: Text('Date: ${slip.date}'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicalSlipDetailScreen(slip: slip),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
