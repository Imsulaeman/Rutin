// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepSettingsAdapter extends TypeAdapter<SleepSettings> {
  @override
  final int typeId = 9;

  @override
  SleepSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepSettings()
      ..sleepModeStartMinutes = fields[0] as int
      ..wakeWindowStartMinutes = fields[1] as int
      ..wakeWindowEndMinutes = fields[2] as int
      ..sleepModeEnabled = fields[3] as bool
      ..accessibilityGranted = fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, SleepSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.sleepModeStartMinutes)
      ..writeByte(1)
      ..write(obj.wakeWindowStartMinutes)
      ..writeByte(2)
      ..write(obj.wakeWindowEndMinutes)
      ..writeByte(3)
      ..write(obj.sleepModeEnabled)
      ..writeByte(4)
      ..write(obj.accessibilityGranted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
