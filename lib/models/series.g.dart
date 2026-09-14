// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SeriesAdapter extends TypeAdapter<Series> {
  @override
  final int typeId = 0;

  @override
  Series read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Series(
      title: fields[0] as String,
      coverUrl: fields[1] as String,
      sourceUrl: fields[2] as String,
      category: fields[3] as String,
      isFavourite: fields[4] as bool,
      isFollowing: fields[5] as bool,
      lastKnownChapter: fields[6] as String,
      lastReadChapter: fields[8] == null ? '' : fields[8] as String,
      sourceSite: fields[9] == null ? '' : fields[9] as String,
      addedDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Series obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.coverUrl)
      ..writeByte(2)
      ..write(obj.sourceUrl)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.isFavourite)
      ..writeByte(5)
      ..write(obj.isFollowing)
      ..writeByte(6)
      ..write(obj.lastKnownChapter)
      ..writeByte(7)
      ..write(obj.addedDate)
      ..writeByte(8)
      ..write(obj.lastReadChapter)
      ..writeByte(9)
      ..write(obj.sourceSite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeriesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
