// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tb_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TBTreatmentProfileAdapter extends TypeAdapter<TBTreatmentProfile> {
  @override
  final int typeId = 8;

  @override
  TBTreatmentProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TBTreatmentProfile()
      ..startDate = fields[0] as DateTime
      ..durationDays = fields[1] as int
      ..medicineId = fields[2] as String
      ..isActive = fields[3] as bool;
  }

  @override
  void write(BinaryWriter writer, TBTreatmentProfile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.durationDays)
      ..writeByte(2)
      ..write(obj.medicineId)
      ..writeByte(3)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TBTreatmentProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
