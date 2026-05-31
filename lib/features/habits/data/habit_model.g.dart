// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 4;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final reminderTimes = numOfFields > 8
        ? (fields[8] as List?)?.cast<int>() ?? <int>[]
        : <int>[];
    return Habit()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..emoji = fields[2] as String
      ..scheduleDays = (fields[3] as List).cast<int>()
      ..reminderMinutes = fields[4] as int?
      ..colorValue = (fields[5] is int) ? fields[5] as int : 0
      ..groupId = (fields[6] is String) ? fields[6] as String : null
      ..sortIndex = (fields[7] is int) ? fields[7] as int : 0
      ..reminderTimes = reminderTimes;
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.scheduleDays)
      ..writeByte(4)
      ..write(obj.reminderMinutes)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.groupId)
      ..writeByte(7)
      ..write(obj.sortIndex)
      ..writeByte(8)
      ..write(obj.reminderTimes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitLogAdapter extends TypeAdapter<HabitLog> {
  @override
  final int typeId = 5;

  @override
  HabitLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitLog()
      ..habitId = fields[0] as String
      ..date = fields[1] as String;
  }

  @override
  void write(BinaryWriter writer, HabitLog obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.habitId)
      ..writeByte(1)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitGroupAdapter extends TypeAdapter<HabitGroup> {
  @override
  final int typeId = 11;

  @override
  HabitGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitGroup()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..emoji = (fields[2] as String?) ?? '📋'
      ..sortIndex = (fields[3] as int?) ?? 0;
  }

  @override
  void write(BinaryWriter writer, HabitGroup obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.sortIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
