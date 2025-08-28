import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:clipboard/clipboard.dart';
import 'utils/url_manipulator.dart';
import 'constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkSan',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  String _sanitizedUrl = '';
  Color _trackersColor = Colors.green;
  List<String> _removedTrackers = [];
  bool _hasProcessedUrl = false;

  @override
  void initState() {
    super.initState();
    // Seamless sharing is handled by ShareHandlerActivity
    // No need for Flutter-side intent handling
  }

  Future<void> _sanitizeUrl(String url, {bool fromShare = false}) async {
    final result = await UrlManipulator.sanitizeUrl(url);
    final sanitizedUrl = result['sanitizedUrl'] as String;
    final removedCount = result['removedCount'] as int;
    final removedTrackers = result['removedTrackers'] as List<String>;
    final domain = result['domain'] as String;

    setState(() {
      _sanitizedUrl = sanitizedUrl;
      _removedTrackers = removedTrackers;
      _hasProcessedUrl = true;
      if (removedCount > 0) {
        _trackersColor = Colors.red;
      } else {
        _trackersColor = Colors.green;
      }
    });

    // Show toast
    String toastMessage;
    if (removedCount > 0) {
      final trackerWord = removedCount == 1 ? 'tracker' : 'trackers';
      toastMessage = '$removedCount $trackerWord removed from $domain';
    } else {
      toastMessage = 'No trackers found';
    }
    Fluttertoast.showToast(msg: toastMessage);

    if (fromShare) {
      // Re-share the sanitized URL
      // Share.share(sanitizedUrl);
    }
  }

  Future<void> _onSanitizePressed() async {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      // Auto-paste from clipboard
      url = await FlutterClipboard.paste();
      _urlController.text = url;
    }
    if (url.isNotEmpty) {
      await _sanitizeUrl(url);
    }
  }

  void _copyUrl() {
    if (_sanitizedUrl.isNotEmpty) {
      FlutterClipboard.copy(_sanitizedUrl);
      Fluttertoast.showToast(msg: 'URL copied to clipboard');
    }
  }

  void _clearResults() {
    setState(() {
      _sanitizedUrl = '';
      _removedTrackers = [];
      _hasProcessedUrl = false;
      _trackersColor = Colors.green;
    });
    _urlController.clear();
  }

  void _shareUrl() {
    if (_sanitizedUrl.isNotEmpty) {
      Share.share(_sanitizedUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkSan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Press sanitize to auto grab from clipboard',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSanitizePressed,
                    child: const Text('Sanitize'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _hasProcessedUrl ? _clearResults : null,
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Redesigned Trackers Section - Only show when URL has been processed
            if (_hasProcessedUrl) ...[
              Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _trackersColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _trackersColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _removedTrackers.isEmpty ? Icons.shield : Icons.warning,
                        color: _trackersColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _removedTrackers.isEmpty ? 'No Trackers Found' : 'Trackers Detected',
                        style: TextStyle(
                          color: _trackersColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _removedTrackers.isEmpty
                      ? 'Your URL is clean and safe to use!'
                      : '${_removedTrackers.length} tracker${_removedTrackers.length == 1 ? '' : 's'} were removed for your privacy',
                    style: TextStyle(
                      color: _trackersColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (_removedTrackers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _removedTrackers.map((tracker) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.block,
                          size: 16,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tracker,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            ],
            const SizedBox(height: 16),
            if (_sanitizedUrl.isNotEmpty) ...[
              const Text(
                'Sanitized URL:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _sanitizedUrl,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _copyUrl,
                      child: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _shareUrl,
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
