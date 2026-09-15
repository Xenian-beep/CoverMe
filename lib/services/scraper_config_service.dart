import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class ScraperConfigService {
  
  static const String configUrl =
    'https://gist.githubusercontent.com/Xenian-beep/6845cd754318d18ee5351926dc604645/raw/6a331217025098834364e22afda4e32e12315c90/scraper_rules.json';

  static const String _cacheKey = 'cachedRules';

  /// Fetches the latest rules from the remote URL. On success, caches
  /// them locally. On failure (no internet, bad URL), falls back to
  /// whatever was last cached. Returns an empty map if neither works.
  static Future<Map<String, dynamic>> loadRules() async {
    final box = Hive.box('configBox');

    try {
      final response = await http
          .get(Uri.parse(configUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> parsed = jsonDecode(response.body);
        await box.put(_cacheKey, response.body);
        return parsed;
      }
    } catch (_) {
      // network error, timeout, bad JSON, etc — fall through to cache
    }

    final cached = box.get(_cacheKey);
    if (cached != null) {
      try {
        return jsonDecode(cached as String);
      } catch (_) {
        return {};
      }
    }

    return {};
  }
}