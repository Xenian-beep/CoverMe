import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/series.dart';

class SeriesRepository {
  static Box<Series> get box => Hive.box<Series>('seriesBox');

  /// Notifies whenever the box changes, so screens rebuild automatically.
  static ValueListenable<Box<Series>> listenable() => box.listenable();

  List<Series> getAll() => box.values.toList();

  List<Series> getFavourites() =>
      box.values.where((s) => s.isFavourite).toList();

  List<Series> getFollowing() =>
      box.values.where((s) => s.isFollowing).toList();

  /// Source URL is the de-facto identity of a series across sites.
  Series? findBySourceUrl(String sourceUrl) {
    for (final s in box.values) {
      if (s.sourceUrl == sourceUrl) return s;
    }
    return null;
  }

  /// Single-pass index for screens that check many titles at once.
  Map<String, Series> indexBySourceUrl() {
    return {for (final s in box.values) s.sourceUrl: s};
  }

  /// Returns the existing entry if it's already saved, otherwise adds it.
  Future<Series> addIfAbsent(Series series) async {
    final existing = findBySourceUrl(series.sourceUrl);
    if (existing != null) return existing;
    await box.add(series);
    return series;
  }

  Future<void> addSeries(Series series) async => box.add(series);

  Future<void> updateSeries(Series series) async => series.save();

  Future<void> deleteSeries(Series series) async => series.delete();

  Future<void> toggleFavourite(Series series) async {
    series.isFavourite = !series.isFavourite;
    await series.save();
  }

  Future<void> toggleFollowing(Series series) async {
    series.isFollowing = !series.isFollowing;
    await series.save();
  }
}