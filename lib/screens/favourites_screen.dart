import 'package:flutter/material.dart';
import '../services/services_repository.dart';
import '../widgets/series_card.dart';
import 'series_detail_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final SeriesRepository _repo = SeriesRepository();

  @override
  Widget build(BuildContext context) {
    final favourites = _repo.getFavourites();

    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: favourites.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              itemCount: favourites.length,
              itemBuilder: (context, index) {
                final series = favourites[index];
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
    );
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
              Icons.favorite_border,
              size: 72,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'No favourites yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart on any series to add it here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}