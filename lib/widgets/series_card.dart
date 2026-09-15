import 'package:flutter/material.dart';
import '../models/series.dart';
import 'cover_image.dart';

class SeriesCard extends StatelessWidget {
  final Series series;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onTap;

  const SeriesCard({
    super.key,
    required this.series,
    required this.onFavouriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CoverImage(
              url: series.coverUrl,
              sourceSite: series.sourceSite,
              width: 48,
              height: 64,
            ),
            if (series.hasUpdate)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          series.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${series.category}${series.lastKnownChapter.isNotEmpty ? ' • Ch. ${series.lastKnownChapter}' : ''}',
        ),
        trailing: IconButton(
          icon: Icon(
            series.isFavourite ? Icons.favorite : Icons.favorite_border,
            color: series.isFavourite ? Colors.redAccent : null,
          ),
          onPressed: onFavouriteToggle,
        ),
      ),
    );
  }
}