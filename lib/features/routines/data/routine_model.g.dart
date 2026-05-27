// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 6;

  @override
  Routine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Routine()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..anchorType = fields[2] as String
      ..fixedTimeMinutes = fields[3] as int?
      ..habitIds = (fields[4] as List).cast<String>()
      ..isActive = fields[5] as bool;
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.anchorType)
      ..writeByte(3)
      ..write(obj.fixedTimeMinutes)
      ..writeByte(4)
      ..write(obj.habitIds)
      ..writeByte(5)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RoutineLogAdapter extends TypeAdapter<RoutineLog> {
  @override
  final int typeId = 7;

  @override
  RoutineLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutineLog()
      ..routineId = fields[0] as String
      ..date = fields[1] as String
      ..completed = fields[2] as bool
      ..completedCount = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, RoutineLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.routineId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.completed)
      ..writeByte(3)
      ..write(obj.completedCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
