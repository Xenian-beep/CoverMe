import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/scraper_service.dart';

/// Cached cover art. Sends the site's Referer so hotlink-protected hosts
/// don't reject the request.
class CoverImage extends StatelessWidget {
  final String url;
  final String sourceSite;
  final double width;
  final double height;
  final double radius;

  const CoverImage({
    super.key,
    required this.url,
    required this.sourceSite,
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? _placeholder(placeholderColor)
          : CachedNetworkImage(
              imageUrl: url,
              httpHeaders: ScraperService.coverHeaders(sourceSite),
              width: width,
              height: height,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (_, _) => _placeholder(placeholderColor),
              errorWidget: (_, _, _) => _placeholder(placeholderColor),
            ),
    );
  }

  Widget _placeholder(Color color) {
    return Container(
      width: width,
      height: height,
      color: color,
      child: Icon(Icons.image_outlined, size: width * 0.35, color: Colors.grey),
    );
  }
}