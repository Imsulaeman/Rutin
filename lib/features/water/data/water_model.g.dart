// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterGoalAdapter extends TypeAdapter<WaterGoal> {
  @override
  final int typeId = 2;

  @override
  WaterGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterGoal()
      ..dailyGoalGlasses = fields[0] as int
      ..reminderIntervalMinutes = fields[1] as int
      ..startTimeMinutes = fields[2] as int
      ..endTimeMinutes = fields[3] as int
      ..reminderActive = fields[4] == true;
  }

  @override
  void write(BinaryWriter writer, WaterGoal obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.dailyGoalGlasses)
      ..writeByte(1)
      ..write(obj.reminderIntervalMinutes)
      ..writeByte(2)
      ..write(obj.startTimeMinutes)
      ..writeByte(3)
      ..write(obj.endTimeMinutes)
      ..writeByte(4)
      ..write(obj.reminderActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WaterLogAdapter extends TypeAdapter<WaterLog> {
  @override
  final int typeId = 3;

  @override
  WaterLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterLog()
      ..date = fields[0] as String
      ..glassesLogged = fields[1] as int;
  }

  @override
  void write(BinaryWriter writer, WaterLog obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.glassesLogged);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
