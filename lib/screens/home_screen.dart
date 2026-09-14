import 'package:flutter/material.dart';
import '../main.dart';
import '../models/series.dart';
import '../services/services_repository.dart';
import '../widgets/series_card.dart';
import 'add_series_screen.dart';
import 'series_detail_screen.dart';

enum SortOption { titleAsc, dateAddedNewest, dateAddedOldest }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SeriesRepository _repo = SeriesRepository();
  SortOption _sortOption = SortOption.dateAddedNewest;

  List<Series> _getSortedList() {
    List<Series> list = _repo.getAll();

    switch (_sortOption) {
      case SortOption.titleAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.dateAddedNewest:
        list.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
      case SortOption.dateAddedOldest:
        list.sort((a, b) => a.addedDate.compareTo(b.addedDate));
        break;
    }
    return list;
  }

  Future<void> _goToAddScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSeriesScreen()),
    );
    setState(() {});
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 72,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Your library is empty',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add manga, manhwa, or webtoons you follow\nand jump straight to their source to read',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _goToAddScreen,
              icon: const Icon(Icons.add),
              label: const Text('Add your first series'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seriesList = _getSortedList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga Tracker'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (_) => const [
              PopupMenuItem(value: SortOption.titleAsc, child: Text('Title (A–Z)')),
              PopupMenuItem(value: SortOption.dateAddedNewest, child: Text('Newest added')),
              PopupMenuItem(value: SortOption.dateAddedOldest, child: Text('Oldest added')),
            ],
          ),
          IconButton(
            icon: Icon(
              themeModeNotifier.value == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle theme',
            onPressed: () {
              setState(() {
                themeModeNotifier.value =
                    themeModeNotifier.value == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark;
              });
            },
          ),
        ],
      ),
      body: seriesList.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              itemCount: seriesList.length,
              itemBuilder: (context, index) {
                final series = seriesList[index];
                return SeriesCard(
                  series: series,
                  onFavouriteToggle: () {
                    setState(() {
                      series.isFavourite = !series.isFavourite;
                      series.save();
                    });
                  },
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SeriesDetailScreen(series: series)),
                    );
                    setState(() {});
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}