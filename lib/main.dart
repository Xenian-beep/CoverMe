import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/series.dart';
import 'screens/main_screen.dart';
import 'services/scraper_service.dart';
import 'theme/app_theme.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(SeriesAdapter());
  await Hive.openBox<Series>('seriesBox');
  await Hive.openBox('configBox');
  await ScraperService.initRules();
  runApp(const MangaTrackerApp());
}

class MangaTrackerApp extends StatelessWidget {
  const MangaTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Manga Tracker',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const MainScreen(),
        );
      },
    );
  }
}