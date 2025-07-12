class MedicalSlip {
  final String id;
  final String patientName;
  final String prescribedMedicine;
  final int prescribedMedicineQuantity;
  final String test;
  final String treatment;
  final String patientId;
  final String patientAge;
  final String patientType;
  final String doctor;
  final String diagnosis;
  final String medication;
  final String date;
  final String validTill;

  MedicalSlip({
    required this.id,
    required this.patientName,
    required this.prescribedMedicine,
    required this.prescribedMedicineQuantity,
    required this.test,
    required this.treatment,
    required this.patientId,
    required this.patientAge,
    required this.patientType,
    required this.doctor,
    required this.diagnosis,
    required this.medication,
    required this.date,
    required this.validTill,
  });

  factory MedicalSlip.fromMap(String id, Map<String, dynamic> data) {
    return MedicalSlip(
      id: id,
      patientName: data['patientName'] ?? '',
      patientId: data['patientId'] ?? '',
      prescribedMedicine: data['prescribedMedicine'] ?? '',
      prescribedMedicineQuantity: data['prescribedMedicineQuantity'] ?? 0,
      test: data['test'] ?? '',
      treatment: data['treatment'] ?? '',
      patientAge: data['patientAge'] ?? '',
      patientType: data['patientType'] ?? '',
      doctor: data['doctor'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      medication: data['medication'] ?? '',
      date: data['date'] ?? '',
      validTill: data['validTill'] ?? '',
    );
  }
}
