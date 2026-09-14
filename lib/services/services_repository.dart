import 'package:hive/hive.dart';
import '../models/series.dart';

class SeriesRepository {
  final Box<Series> _box = Hive.box<Series>('seriesBox');

  List<Series> getAll() => _box.values.toList();

  List<Series> getFavourites() =>
      _box.values.where((s) => s.isFavourite).toList();

  List<Series> getFollowing() =>
      _box.values.where((s) => s.isFollowing).toList();

  Future<void> addSeries(Series series) async {
    await _box.add(series);
  }

  Future<void> updateSeries(Series series) async {
    await series.save();
  }

  Future<void> deleteSeries(Series series) async {
    await series.delete();
  }

  Future<void> toggleFavourite(Series series) async {
    series.isFavourite = !series.isFavourite;
    await series.save();
  }

  Future<void> toggleFollowing(Series series) async {
    series.isFollowing = !series.isFollowing;
    await series.save();
  }
}