// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 0;

  @override
  Medicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medicine()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..dosage = fields[2] as String?
      ..scheduleTimes = (fields[3] as List).cast<int>()
      ..isActive = fields[4] as bool
      ..colorValue = fields[5] as int;
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dosage)
      ..writeByte(3)
      ..write(obj.scheduleTimes)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedicineLogAdapter extends TypeAdapter<MedicineLog> {
  @override
  final int typeId = 1;

  @override
  MedicineLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicineLog()
      ..medicineId = fields[0] as String
      ..scheduledTime = fields[1] as DateTime
      ..takenAt = fields[2] as DateTime?
      ..status = fields[3] as String;
  }

  @override
  void write(BinaryWriter writer, MedicineLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.medicineId)
      ..writeByte(1)
      ..write(obj.scheduledTime)
      ..writeByte(2)
      ..write(obj.takenAt)
      ..writeByte(3)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
