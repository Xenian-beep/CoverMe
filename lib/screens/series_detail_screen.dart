import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/series.dart';
import '../services/scraper_service.dart';
import 'add_series_screen.dart';

class SeriesDetailScreen extends StatefulWidget {
  final Series series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  bool _checkingUpdate = false;
  bool _wasDeleted = false;

  Future<void> _openSource() async {
    final url = widget.series.sourceUrl;
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link')),
      );
    }
  }

  Future<void> _editLatestChapter() async {
    final controller = TextEditingController(text: widget.series.lastKnownChapter);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update latest chapter'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(labelText: 'Chapter number'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        widget.series.lastKnownChapter = result;
        widget.series.save();
      });
    }
  }

  Future<void> _checkForUpdate() async {
    if (widget.series.sourceSite.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This series has no source site configured for auto-check')),
      );
      return;
    }

    setState(() => _checkingUpdate = true);

    final latest = await ScraperService.fetchLatestChapter(
      url: widget.series.sourceUrl,
      sourceSite: widget.series.sourceSite,
    );

    setState(() => _checkingUpdate = false);

    if (!mounted) return;

    if (latest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check for updates — site may be unreachable')),
      );
      return;
    }

    setState(() {
      widget.series.lastKnownChapter = latest;
      widget.series.save();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Latest chapter: $latest')),
    );
  }

  void _markAsRead() {
    setState(() {
      widget.series.lastReadChapter = widget.series.lastKnownChapter;
      widget.series.save();
    });
  }

  Future<void> _goToEditScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddSeriesScreen(existingSeries: widget.series)),
    );
    if (mounted) setState(() {}); // refresh displayed values after editing
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete series?'),
        content: Text('This will remove "${widget.series.title}" from your library. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.series.delete();
      _wasDeleted = true;
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;

    // If the series was deleted, avoid rendering with a stale/invalid object.
    if (_wasDeleted) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(series.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit series',
            onPressed: _goToEditScreen,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete series',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (series.coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  series.coverUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
            const SizedBox(height: 16),
            Text(series.category, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    series.lastKnownChapter.isNotEmpty
                        ? 'Latest chapter: ${series.lastKnownChapter}'
                        : 'Latest chapter: not set',
                  ),
                ),
                TextButton(
                  onPressed: _editLatestChapter,
                  child: const Text('Edit'),
                ),
              ],
            ),
            Text(
              series.lastReadChapter.isNotEmpty
                  ? 'You\'ve read up to: ${series.lastReadChapter}'
                  : 'You haven\'t marked any chapter as read',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _checkingUpdate ? null : _checkForUpdate,
              icon: _checkingUpdate
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_checkingUpdate ? 'Checking...' : 'Check for update'),
            ),
            if (series.hasUpdate) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _markAsRead,
                icon: const Icon(Icons.check),
                label: const Text('Mark as read'),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openSource,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Read'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    series.isFavourite ? Icons.favorite : Icons.favorite_border,
                    color: series.isFavourite ? Colors.redAccent : null,
                  ),
                  onPressed: () {
                    setState(() {
                      series.isFavourite = !series.isFavourite;
                      series.save();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    series.isFollowing ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  onPressed: () {
                    setState(() {
                      series.isFollowing = !series.isFollowing;
                      series.save();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}