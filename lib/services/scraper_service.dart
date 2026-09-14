import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/scraped_manga.dart';
import 'scraper_config_service.dart';

class ScraperService {
  static Map<String, dynamic>? _rulesCache;

  static Future<void> initRules() async {
    _rulesCache = await ScraperConfigService.loadRules();
  }

  static List<String> get supportedSites => _rulesCache?.keys.toList() ?? [];

  static Map<String, dynamic>? getSiteConfig(String site) {
    final rule = _rulesCache?[site];
    return rule == null ? null : Map<String, dynamic>.from(rule);
  }

  static Future<String?> fetchLatestChapter({
    required String url,
    required String sourceSite,
  }) async {
    _rulesCache ??= await ScraperConfigService.loadRules();

    final rule = _rulesCache?[sourceSite];
    if (rule == null) return null;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );
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
      } else {
        return _extractBySelector(document, rule);
      }
    } catch (_) {
      return null;
    }
  }

  /// NEW: fetches the series page live and finds the "first chapter" /
  /// "Start Reading" link, returning its full URL (not just a chapter id).
  static Future<String?> fetchFirstChapterUrl({
    required String seriesUrl,
    required String sourceSite,
  }) async {
    _rulesCache ??= await ScraperConfigService.loadRules();

    final rule = _rulesCache?[sourceSite];
    final matchText = (rule?['firstChapterMatchText'] ?? '').toString();
    if (matchText.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse(seriesUrl),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );
      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);
      return _findHrefByLinkText(document, matchText);
    } catch (_) {
      return null;
    }
  }

  /// Builds a best-effort chapter URL by pattern (e.g. ".../chapter-42").
  /// Not verified against the real chapter list — may 404 if the number
  /// doesn't exist on the site.
  static String buildChapterUrl({
    required String seriesUrl,
    required String chapterInput,
  }) {
    final base = seriesUrl.endsWith('/') ? seriesUrl.substring(0, seriesUrl.length - 1) : seriesUrl;
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
      final response = await http.get(
        Uri.parse(listingUrl),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );
      if (response.statusCode != 200) return [];

      final document = html_parser.parse(response.body);
      final items = document.querySelectorAll(itemSelector);

      final results = <ScrapedManga>[];

      for (final item in items) {
        final titleEl = item.querySelector(titleSelector);
        if (titleEl == null) continue;

        final title = titleEl.text.trim();
        final sourceUrl = titleEl.attributes['href'] ?? '';
        if (title.isEmpty || sourceUrl.isEmpty) continue;

        String coverUrl = '';
        if (coverSelector.isNotEmpty) {
          final coverEl = item.querySelector(coverSelector);
          coverUrl = coverEl?.attributes['data-src'] ??
              coverEl?.attributes['src'] ??
              '';
        }

        String latestChapter = '';
        String chapterUrl = '';
        if (chapterLinkSelector.isNotEmpty) {
          final chapterEl = item.querySelector(chapterLinkSelector);
          latestChapter = chapterEl?.text.trim() ?? '';
          chapterUrl = chapterEl?.attributes['href'] ?? '';
        }

        String description = '';
        if (descriptionSelector.isNotEmpty) {
          final descEl = item.querySelector(descriptionSelector);
          description = descEl?.text.trim() ?? '';
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

  static String? _extractBySelector(Document document, Map rule) {
    final List<dynamic> selectors = rule['selectors'] ?? [];
    for (final selector in selectors) {
      final element = document.querySelector(selector as String);
      if (element != null) {
        final text = element.text.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  /// Finds an <a> tag by its exact visible text (case-insensitive) and
  /// returns its href, or null if not found.
  static String? _findHrefByLinkText(Document document, String matchText) {
    if (matchText.isEmpty) return null;
    final normalized = matchText.toLowerCase();

    final anchors = document.querySelectorAll('a');
    for (final a in anchors) {
      if (a.text.trim().toLowerCase() == normalized) {
        return a.attributes['href'];
      }
    }
    return null;
  }
}