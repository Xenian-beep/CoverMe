import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/scraped_manga.dart';
import 'scraper_config_service.dart';

class ScraperService {
  static Map<String, dynamic>? _rulesCache;

  static const Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
  };

  static Future<void> initRules() async {
    _rulesCache = await ScraperConfigService.loadRules();
  }

  static List<String> get supportedSites => _rulesCache?.keys.toList() ?? [];

  static Map<String, dynamic>? getSiteConfig(String site) {
    final rule = _rulesCache?[site];
    return rule == null ? null : Map<String, dynamic>.from(rule);
  }

  /// Headers needed to load cover images for a site. Many hosts hotlink-block,
  /// so the Referer comes from that site's own rule rather than being global.
  static Map<String, String> coverHeaders(String site) {
    final referer = _rulesCache?[site]?['coverReferer'];
    if (referer is String && referer.isNotEmpty) {
      return {..._defaultHeaders, 'Referer': referer};
    }
    return _defaultHeaders;
  }

  /// True if the site exposes a genre-specific listing URL for this genre.
  static bool siteSupportsGenre(String site, String genre) {
    final rule = _rulesCache?[site];
    if (rule?['genreUrlTemplate'] is! String) return false;
    final genres = rule?['genres'];
    return genres is List && genres.map((g) => g.toString()).contains(genre);
  }

  /// Listing URL for a site, optionally narrowed to a genre.
  static String? listingUrlFor(String site, {String? genre}) {
    final rule = _rulesCache?[site];
    if (rule == null) return null;
    if (genre != null) {
      if (!siteSupportsGenre(site, genre)) return null;
      return (rule['genreUrlTemplate'] as String).replaceAll('{genre}', genre);
    }
    final def = rule['defaultListingUrl'];
    return def is String && def.isNotEmpty ? def : null;
  }

  static Future<String?> fetchLatestChapter({
    required String url,
    required String sourceSite,
  }) async {
    _rulesCache ??= await ScraperConfigService.loadRules();

    final rule = _rulesCache?[sourceSite];
    if (rule == null) return null;

    try {
      final response = await http
          .get(Uri.parse(url), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);
      final String mode = rule['mode'] ?? 'cssSelector';

      if (mode == 'linkText') {
        final matchText = (rule['matchText'] ?? '').toString();
        final pattern = rule['hrefPattern'] ?? r'chapter-([\w\-\.]+)';
        final href = _findHrefByLinkText(document, matchText);
        if (href == null) return null;
        final match = RegExp(pattern).firstMatch(href);
        return match != null && match.groupCount >= 1 ? match.group(1) : null;
      }
      return _extractBySelector(document, rule);
    } catch (_) {
      return null;
    }
  }

  /// Fetches the series page and returns the absolute URL of its first chapter.
  static Future<String?> fetchFirstChapterUrl({
    required String seriesUrl,
    required String sourceSite,
  }) async {
    _rulesCache ??= await ScraperConfigService.loadRules();

    final rule = _rulesCache?[sourceSite];
    final matchText = (rule?['firstChapterMatchText'] ?? '').toString();
    if (matchText.isEmpty) return null;

    try {
      final response = await http
          .get(Uri.parse(seriesUrl), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);
      final href = _findHrefByLinkText(document, matchText);
      return href == null ? null : _absolute(href, seriesUrl);
    } catch (_) {
      return null;
    }
  }

  /// Best-effort chapter URL built by pattern. Not verified against the site.
  static String buildChapterUrl({
    required String seriesUrl,
    required String chapterInput,
  }) {
    final base = seriesUrl.endsWith('/')
        ? seriesUrl.substring(0, seriesUrl.length - 1)
        : seriesUrl;
    return '$base/chapter-$chapterInput';
  }

  static Future<List<ScrapedManga>> fetchListing({
    required String listingUrl,
    required String sourceSite,
  }) async {
    _rulesCache ??= await ScraperConfigService.loadRules();

    final rule = _rulesCache?[sourceSite];
    final listingConfig = rule?['listing'];
    if (listingConfig == null) return [];

    final String itemSelector = listingConfig['itemSelector'] ?? '';
    final String titleSelector = listingConfig['titleSelector'] ?? '';
    final String coverSelector = listingConfig['coverSelector'] ?? '';
    final String chapterLinkSelector = listingConfig['chapterLinkSelector'] ?? '';
    final String descriptionSelector = listingConfig['descriptionSelector'] ?? '';
    final String displayName = rule?['displayName'] ?? sourceSite;

    if (itemSelector.isEmpty || titleSelector.isEmpty) return [];

    try {
      final response = await http
          .get(Uri.parse(listingUrl), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return [];

      final document = html_parser.parse(response.body);
      final items = document.querySelectorAll(itemSelector);
      final results = <ScrapedManga>[];

      for (final item in items) {
        final titleEl = item.querySelector(titleSelector);
        if (titleEl == null) continue;

        final title = titleEl.text.trim();
        final rawSource = titleEl.attributes['href'] ?? '';
        if (title.isEmpty || rawSource.isEmpty) continue;
        final sourceUrl = _absolute(rawSource, listingUrl);

        String coverUrl = '';
        if (coverSelector.isNotEmpty) {
          final coverEl = item.querySelector(coverSelector);
          final rawCover = coverEl?.attributes['data-src'] ??
              coverEl?.attributes['src'] ??
              '';
          if (rawCover.isNotEmpty) coverUrl = _absolute(rawCover, listingUrl);
        }

        String latestChapter = '';
        String chapterUrl = '';
        if (chapterLinkSelector.isNotEmpty) {
          final chapterEl = item.querySelector(chapterLinkSelector);
          latestChapter = chapterEl?.text.trim() ?? '';
          final rawChapter = chapterEl?.attributes['href'] ?? '';
          if (rawChapter.isNotEmpty) {
            chapterUrl = _absolute(rawChapter, listingUrl);
          }
        }

        String description = '';
        if (descriptionSelector.isNotEmpty) {
          description = item.querySelector(descriptionSelector)?.text.trim() ?? '';
        }

        results.add(ScrapedManga(
          title: title,
          coverUrl: coverUrl,
          sourceUrl: sourceUrl,
          chapterUrl: chapterUrl.isNotEmpty ? chapterUrl : sourceUrl,
          latestChapter: latestChapter,
          description: description,
          sourceSite: sourceSite,
          sourceDisplayName: displayName,
        ));
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  /// Turns relative and protocol-relative hrefs into absolute URLs.
  static String _absolute(String href, String baseUrl) {
    try {
      return Uri.parse(baseUrl).resolve(href).toString();
    } catch (_) {
      return href;
    }
  }

  static String? _extractBySelector(Document document, Map rule) {
    final List<dynamic> selectors = rule['selectors'] ?? [];
    for (final selector in selectors) {
      final element = document.querySelector(selector as String);
      final text = element?.text.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static String? _findHrefByLinkText(Document document, String matchText) {
    if (matchText.isEmpty) return null;
    final normalized = matchText.toLowerCase();

    for (final a in document.querySelectorAll('a')) {
      if (a.text.trim().toLowerCase() == normalized) {
        return a.attributes['href'];
      }
    }
    return null;
  }
}