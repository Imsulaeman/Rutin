import 'package:flutter/material.dart';
import '../data/medicine_model.dart';

class MedicineCard extends StatelessWidget {
  const MedicineCard({super.key, required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(medicine.colorValue),
        ),
        title: Text(medicine.name),
        subtitle: medicine.dosage != null ? Text(medicine.dosage!) : null,
      ),
    );
  }
}
