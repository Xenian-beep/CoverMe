import 'package:flutter/material.dart';
import '../models/series.dart';
import '../services/services_repository.dart';
import '../services/scraper_service.dart';

class AddSeriesScreen extends StatefulWidget {
  final Series? existingSeries; // null = adding new, non-null = editing

  const AddSeriesScreen({super.key, this.existingSeries});

  @override
  State<AddSeriesScreen> createState() => _AddSeriesScreenState();
}

class _AddSeriesScreenState extends State<AddSeriesScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _coverController;
  late final TextEditingController _sourceController;
  late final TextEditingController _chapterController;
  late String _category;
  String? _sourceSite;

  final _repo = SeriesRepository();

  bool get _isEditing => widget.existingSeries != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSeries;

    _titleController = TextEditingController(text: existing?.title ?? '');
    _coverController = TextEditingController(text: existing?.coverUrl ?? '');
    _sourceController = TextEditingController(text: existing?.sourceUrl ?? '');
    _chapterController =
        TextEditingController(text: existing?.lastKnownChapter ?? '');
    _category = existing?.category ?? 'Manga';
    _sourceSite =
        (existing?.sourceSite.isNotEmpty ?? false) ? existing!.sourceSite : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _coverController.dispose();
    _sourceController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? v) {
    if (v == null || v.trim().isEmpty) return 'Source URL is required';
    final uri = Uri.tryParse(v.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Enter a full URL including https://';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final sourceUrl = _sourceController.text.trim();

    if (_isEditing) {
      final series = widget.existingSeries!;
      series.title = _titleController.text.trim();
      series.coverUrl = _coverController.text.trim();
      series.sourceUrl = sourceUrl;
      series.category = _category;
      series.lastKnownChapter = _chapterController.text.trim();
      series.sourceSite = _sourceSite ?? '';
      await _repo.updateSeries(series);
    } else {
      if (_repo.findBySourceUrl(sourceUrl) != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('That series is already in your library')),
          );
        }
        return;
      }
      await _repo.addSeries(Series(
        title: _titleController.text.trim(),
        coverUrl: _coverController.text.trim(),
        sourceUrl: sourceUrl,
        category: _category,
        lastKnownChapter: _chapterController.text.trim(),
        sourceSite: _sourceSite ?? '',
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final supportedSites = ScraperService.supportedSites;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Series' : 'Add Series')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source URL (where "Read" opens)',
              ),
              keyboardType: TextInputType.url,
              validator: _validateUrl,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coverController,
              decoration:
                  const InputDecoration(labelText: 'Cover image URL (optional)'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _chapterController,
              decoration: const InputDecoration(
                labelText: 'Last known chapter (optional)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'Manga', child: Text('Manga')),
                DropdownMenuItem(value: 'Manhwa', child: Text('Manhwa')),
                DropdownMenuItem(value: 'Webtoon', child: Text('Webtoon')),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _sourceSite,
              decoration: const InputDecoration(
                labelText: 'Auto-update source (optional)',
                helperText: 'Pick a site to enable "Check for update"',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None — manual only'),
                ),
                ...supportedSites.map(
                  (site) => DropdownMenuItem<String?>(
                    value: site,
                    child: Text(
                      ScraperService.getSiteConfig(site)?['displayName'] ?? site,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _sourceSite = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save Changes' : 'Save Series'),
            ),
          ],
        ),
      ),
    );
  }
}