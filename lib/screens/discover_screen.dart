import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/scraped_manga.dart';
import '../models/series.dart';
import '../services/scraper_service.dart';
import '../services/services_repository.dart';
import '../widgets/cover_image.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _repo = SeriesRepository();
  final _searchController = TextEditingController();

  bool _loading = true;
  List<ScrapedManga> _allResults = [];
  String _searchQuery = '';
  String? _activeGenre;
  final Set<String> _fetchingRead = {};

  @override
  void initState() {
    super.initState();
    _loadAllSites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _availableGenres {
    final genres = <String>{};
    for (final site in ScraperService.supportedSites) {
      final siteGenres = ScraperService.getSiteConfig(site)?['genres'];
      if (siteGenres is List) {
        genres.addAll(siteGenres.map((g) => g.toString()));
      }
    }
    return genres.toList()..sort();
  }

  /// Fetches every site in parallel; sites that don't carry the selected
  /// genre are skipped rather than falling back to their full listing.
  Future<void> _loadAllSites({String? genre}) async {
    setState(() {
      _loading = true;
      _activeGenre = genre;
    });

    final requests = <Future<List<ScrapedManga>>>[];
    for (final site in ScraperService.supportedSites) {
      final listingUrl = ScraperService.listingUrlFor(site, genre: genre);
      if (listingUrl == null) continue;
      requests.add(
        ScraperService.fetchListing(listingUrl: listingUrl, sourceSite: site),
      );
    }

    final responses = await Future.wait(requests);

    if (!mounted) return;
    setState(() {
      _allResults = responses.expand((r) => r).toList();
      _loading = false;
    });
  }

  List<ScrapedManga> get _filteredResults {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _allResults;
    return _allResults
        .where((m) => m.title.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _openUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link')),
      );
    }
  }

  Future<void> _openForLibraryItem(ScrapedManga manga, Series matched) async {
    final url = matched.hasUpdate
        ? (manga.chapterUrl.isNotEmpty ? manga.chapterUrl : manga.sourceUrl)
        : manga.sourceUrl;
    await _openUrl(url);
  }

  Future<void> _openFirstChapter(ScrapedManga manga) async {
    setState(() => _fetchingRead.add(manga.sourceUrl));

    final firstChapterUrl = await ScraperService.fetchFirstChapterUrl(
      seriesUrl: manga.sourceUrl,
      sourceSite: manga.sourceSite,
    );

    if (!mounted) return;
    setState(() => _fetchingRead.remove(manga.sourceUrl));

    if (firstChapterUrl != null) {
      await _openUrl(firstChapterUrl);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not find chapter 1 — opening latest chapter instead'),
      ),
    );
    await _openUrl(manga.chapterUrl.isNotEmpty ? manga.chapterUrl : manga.sourceUrl);
  }

  Future<void> _showJumpToChapterDialog(ScrapedManga manga) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to chapter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Chapter number',
                hintText: 'e.g. 42, or 3-2 for decimal chapters',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This builds the link directly — it isn\'t checked against the site, so it may not exist.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Open'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _openUrl(ScraperService.buildChapterUrl(
        seriesUrl: manga.sourceUrl,
        chapterInput: result,
      ));
    }
  }

  Future<void> _addToLibrary(ScrapedManga manga) async {
    final existing = _repo.findBySourceUrl(manga.sourceUrl);
    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${manga.title} is already in your library')),
        );
      }
      return;
    }

    await _repo.addSeries(Series(
      title: manga.title,
      coverUrl: manga.coverUrl,
      sourceUrl: manga.sourceUrl,
      category: _activeGenre ?? 'Manga',
      lastKnownChapter: manga.latestChapter,
      lastReadChapter: manga.latestChapter,
      sourceSite: manga.sourceSite,
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${manga.title} added to library')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final genres = _availableGenres;
    final results = _filteredResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _loadAllSites(genre: _activeGenre),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search titles...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          if (genres.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _activeGenre == null,
                      onSelected: (_) => _loadAllSites(genre: null),
                    ),
                  ),
                  ...genres.map(
                    (g) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: _activeGenre == g,
                        onSelected: (_) => _loadAllSites(genre: g),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? const Center(child: Text('No manga found'))
                    : ValueListenableBuilder<Box<Series>>(
                        valueListenable: SeriesRepository.listenable(),
                        builder: (context, box, _) {
                          // Built once per rebuild instead of per row.
                          final library = _repo.indexBySourceUrl();

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: results.length,
                            itemBuilder: (context, index) => _buildCard(
                              results[index],
                              library[results[index].sourceUrl],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ScrapedManga manga, Series? matched) {
    final hasNewChapter = matched?.hasUpdate ?? false;
    final isFetchingRead = _fetchingRead.contains(manga.sourceUrl);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverImage(
              url: manga.coverUrl,
              sourceSite: manga.sourceSite,
              width: 64,
              height: 90,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          manga.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (hasNewChapter)
                        Container(
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      Chip(
                        label: Text(manga.sourceDisplayName,
                            style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (_activeGenre != null)
                        Chip(
                          label: Text(_activeGenre!,
                              style: const TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  if (manga.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      manga.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: isFetchingRead
                            ? null
                            : () => matched != null
                                ? _openForLibraryItem(manga, matched)
                                : _openFirstChapter(manga),
                        icon: isFetchingRead
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.open_in_new, size: 16),
                        label: Text(
                          matched != null && !hasNewChapter ? 'Continue' : 'Read',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.playlist_play, size: 20),
                        tooltip: 'Jump to chapter',
                        onPressed: () => _showJumpToChapterDialog(manga),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (matched == null)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Add to library',
                          onPressed: () => _addToLibrary(manga),
                          visualDensity: VisualDensity.compact,
                        )
                      else ...[
                        IconButton(
                          icon: Icon(
                            matched.isFavourite ? Icons.favorite : Icons.favorite_border,
                            color: matched.isFavourite ? Colors.redAccent : null,
                            size: 20,
                          ),
                          onPressed: () => _repo.toggleFavourite(matched),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(
                            matched.isFollowing ? Icons.bookmark : Icons.bookmark_border,
                            size: 20,
                          ),
                          onPressed: () => _repo.toggleFollowing(matched),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}