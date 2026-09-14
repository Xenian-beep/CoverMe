# Manga Tracker

Flutter app for tracking manga/manhwa/webtoons across multiple source
sites — browse, favourite, follow updates, and read via the source site.

## Features

- **Home** — your library, sortable by title or date added
- **Favourites** — a separate tab for series you've marked as favourite
- **Discover** — auto-loads manga from configured source sites, with genre
  filters and title search; shows description, latest chapter, and lets you
  add straight to your library
- **Follow updates** — tracks the latest known chapter vs. what you've read,
  showing a "NEW" badge when a series has unread chapters
- **Web scraping** — pulls listings and chapter info directly from source
  sites using site-specific CSS selector rules
- **Remote config** — scraper rules (selectors, genres, listing URLs) are
  loaded from a hosted JSON file, so sites can be added/fixed without an app
  update
- **Light/dark theme** — Material 3 theming with a toggle
- **Local persistence** — everything (library, favourites, read progress)
  is stored on-device with Hive; no account or server required

## Tech stack

- Flutter / Dart
- [Hive](https://pub.dev/packages/hive) — local storage
- [http](https://pub.dev/packages/http) + [html](https://pub.dev/packages/html) — web scraping
- [url_launcher](https://pub.dev/packages/url_launcher) — opens source sites in the browser
- [google_fonts](https://pub.dev/packages/google_fonts) — typography
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) — app icon generation

## Project structure

```
lib/
  models/       # Series, ScrapedManga (Hive-backed and plain data models)
  screens/      # Home, Favourites, Discover, Add/Edit, Detail, Main shell
  services/     # SeriesRepository (Hive CRUD), ScraperService, remote config
  theme/        # App-wide light/dark theming
  widgets/      # Reusable UI pieces (series card, etc.)
```

## Setting up scraper rules

Source site rules (CSS selectors, genre lists, listing URLs) live in a
remote JSON file, not in the app code. Point `configUrl` in
`lib/services/scraper_config_service.dart` at your own hosted JSON (e.g. a
GitHub Gist raw URL) and shape it like:

```json
{
  "your-site-key": {
    "displayName": "Site Name",
    "defaultListingUrl": "https://example.com/all-manga",
    "genreUrlTemplate": "https://example.com/genre/{genre}",
    "genres": ["action", "fantasy", "romance"],
    "mode": "linkText",
    "matchText": "Newest Chapter",
    "firstChapterMatchText": "Start Reading",
    "hrefPattern": "chapter-([\\w\\-\\.]+)",
    "listing": {
      "itemSelector": ".manga-item",
      "titleSelector": "h3 a",
      "coverSelector": "img",
      "chapterLinkSelector": ".latest-chapter",
      "descriptionSelector": "p"
    }
  }
}
```

Selectors are found by inspecting a real listing/series page in browser
DevTools. Scraping only pulls what's in the server-rendered HTML — content
loaded via JavaScript after page load isn't visible to this approach.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Status

Personal learning project — 3rd Flutter app, built incrementally with
persistence, theming, and a working scraper pipeline.
