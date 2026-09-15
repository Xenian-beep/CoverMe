import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:manga_tracker/models/series.dart';
import 'package:manga_tracker/screens/home_screen.dart';

void main() {
  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive');
    Hive.registerAdapter(SeriesAdapter());
  });

  setUp(() async {
    await Hive.openBox<Series>('seriesBox');
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('seriesBox');
  });

  testWidgets('shows the empty state when the library has no series',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.text('Add your first series'), findsOneWidget);
  });

  testWidgets('lists a saved series and flags unread chapters',
      (tester) async {
    await Hive.box<Series>('seriesBox').add(Series(
      title: 'Test Series',
      coverUrl: '',
      sourceUrl: 'https://example.com/series/test',
      category: 'Manhwa',
      lastKnownChapter: '42',
      lastReadChapter: '41',
    ));

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    expect(find.text('Test Series'), findsOneWidget);
    expect(find.text('Manhwa • Ch. 42'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
  });

  test('hasUpdate is false once the read chapter catches up', () {
    final series = Series(
      title: 'X',
      coverUrl: '',
      sourceUrl: 'https://example.com/x',
      category: 'Manga',
      lastKnownChapter: '10',
      lastReadChapter: '10',
    );

    expect(series.hasUpdate, isFalse);
  });
}