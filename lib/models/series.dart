import 'package:hive/hive.dart';

part 'series.g.dart';

@HiveType(typeId: 0)
class Series extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String coverUrl;

  @HiveField(2)
  String sourceUrl;

  @HiveField(3)
  String category;

  @HiveField(4)
  bool isFavourite;

  @HiveField(5)
  bool isFollowing;

  @HiveField(6)
  String lastKnownChapter;

  @HiveField(7)
  DateTime addedDate;

  @HiveField(8, defaultValue: '')
  String lastReadChapter;

  @HiveField(9, defaultValue: '')
String sourceSite;

  Series({
  required this.title,
  required this.coverUrl,
  required this.sourceUrl,
  required this.category,
  this.isFavourite = false,
  this.isFollowing = false,
  this.lastKnownChapter = '',
  this.lastReadChapter = '',
  this.sourceSite = '',
  DateTime? addedDate,
}) : addedDate = addedDate ?? DateTime.now();

  bool get hasUpdate =>
      lastKnownChapter.isNotEmpty && lastKnownChapter != lastReadChapter;
}