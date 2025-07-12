import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'MedicalSlipModel.dart';

class MedicalSlipDetailScreen extends StatelessWidget {
  final MedicalSlip slip;

  MedicalSlipDetailScreen({required this.slip});

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('UAAR Healthcare Center', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Medical Slip', style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey600)),
              pw.Divider(),

              pw.Text("Patient Name: ${slip.patientName}"),
              pw.Text("Patient ID: ${slip.patientId}"),
              pw.Text("Age: ${slip.patientAge}"),
              pw.Text("Type: ${slip.patientType}"),
              pw.Text("Date: ${slip.date}"),
              pw.Text("Valid Till: ${slip.validTill}"),
              pw.Text("Doctor: ${slip.doctor}"),
              pw.SizedBox(height: 20),
              pw.Text("Treatment:",style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(slip.treatment),
              pw.SizedBox(height: 20),
              pw.Text("Test: ",style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(slip.test),
              pw.SizedBox(height: 20),
              pw.Text("prescribed Medicine:",style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(slip.prescribedMedicine),
              pw.SizedBox(height: 20),
              pw.Text("prescribed Medicine Quantity:",style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${slip.prescribedMedicineQuantity}'),


              pw.SizedBox(height: 20),
              pw.Text("Diagnosis", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(slip.diagnosis),

              pw.SizedBox(height: 20),
              pw.Text("Medication & Instructions", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(slip.medication),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slip Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Doctor: ${slip.doctor}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Date: ${slip.date}"),
            Text("Valid Till: ${slip.validTill}"),
            const SizedBox(height: 16),
            const Text("Diagnosis", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(slip.diagnosis),
            const SizedBox(height: 16),
            const Text("Medication & Instructions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(slip.medication),
            const SizedBox(height: 16),
            const Text("Test", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(slip.test),
            const SizedBox(height: 16),
            const Text("Treatment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(slip.treatment),
            const SizedBox(height: 16),
            const Text("prescribed Medicine", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(slip.prescribedMedicine),
            const SizedBox(height: 16),
            const Text("prescribed Medicine Quantity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${slip.prescribedMedicineQuantity}'),

          ],
        ),
      ),
    );
  }
}
