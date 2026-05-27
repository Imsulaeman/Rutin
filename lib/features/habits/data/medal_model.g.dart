// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedalAdapter extends TypeAdapter<Medal> {
  @override
  final int typeId = 10;

  @override
  Medal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medal()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..emoji = fields[2] as String
      ..peakStreak = fields[3] as int
      ..awardedAt = fields[4] as DateTime
      ..type = fields[5] as String;
  }

  @override
  void write(BinaryWriter writer, Medal obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.peakStreak)
      ..writeByte(4)
      ..write(obj.awardedAt)
      ..writeByte(5)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
