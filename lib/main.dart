import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:clipboard/clipboard.dart';
import 'utils/url_manipulator.dart';
import 'utils/performance_monitor.dart';

void main() {
  // Enable performance monitoring in debug mode
  assert(() {
    PerformanceMonitor();
    return true;
  }());

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
  List<String> _removedTrackers = const []; // Use const for initial empty list
  bool _hasProcessedUrl = false;
  bool _isProcessing = false; // Add processing state to prevent multiple requests

  @override
  void initState() {
    super.initState();
    // Seamless sharing is handled by ShareHandlerActivity
    // No need for Flutter-side intent handling
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _sanitizeUrl(String url, {bool fromShare = false}) async {
    if (_isProcessing) return; // Prevent multiple simultaneous requests

    setState(() => _isProcessing = true);

    final monitor = PerformanceMonitor();
    monitor.startTimer('url_sanitization_ui');

    try {
      final result = await UrlManipulator.sanitizeUrl(url);
      final sanitizedUrl = result['sanitizedUrl'] as String;
      final removedCount = result['removedCount'] as int;
      final removedTrackers = result['removedTrackers'] as List<String>;
      final domain = result['domain'] as String;

      // Batch state updates for better performance
      setState(() {
        _sanitizedUrl = sanitizedUrl;
        _removedTrackers = removedTrackers;
        _hasProcessedUrl = true;
        _isProcessing = false;
        _trackersColor = removedCount > 0 ? Colors.red : Colors.green;
      });

      // Show toast
      final toastMessage = removedCount > 0
          ? '$removedCount tracker${removedCount == 1 ? '' : 's'} removed from $domain'
          : 'No trackers found';
      Fluttertoast.showToast(msg: toastMessage);

      if (fromShare) {
        // Re-share the sanitized URL
        // Share.share(sanitizedUrl);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      Fluttertoast.showToast(msg: 'Error processing URL: ${e.toString()}');
    } finally {
      monitor.stopTimer('url_sanitization_ui');
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
      if (_isValidUrl(url)) {
        await _sanitizeUrl(url);
      } else {
        Fluttertoast.showToast(
          msg: 'Invalid URL format. Please provide a valid web URL.',
          toastLength: Toast.LENGTH_LONG,
        );
        // Clear any previous results
        setState(() {
          _sanitizedUrl = '';
          _removedTrackers = [];
          _hasProcessedUrl = false;
          _trackersColor = Colors.green;
        });
      }
    }
  }

  bool _isValidUrl(String text) {
    final trimmedText = text.trim();

    // Basic checks - optimized
    if (trimmedText.isEmpty || trimmedText.length < 10) {
      return false;
    }

    // Must start with http:// or https:// - optimized check
    if (!trimmedText.startsWith('http://') && !trimmedText.startsWith('https://')) {
      return false;
    }

    // Reject file paths - optimized pattern matching
    if (trimmedText.startsWith('file://') ||
        trimmedText.startsWith('/') ||
        trimmedText.contains(':\\') ||  // Windows paths
        trimmedText.contains('\\\\')) {  // Network paths
      return false;
    }

    // Reject data URLs
    if (trimmedText.startsWith('data:')) {
      return false;
    }

    // Reject URLs that are too short or malformed
    try {
      final uri = Uri.parse(trimmedText);

      // Must have a valid host - optimized
      final host = uri.host;
      if (host.isEmpty || host.length < 4) {
        return false;
      }

      // Reject localhost and private IPs for security - optimized
      if (host == 'localhost' ||
          host == '127.0.0.1' ||
          host.startsWith('192.168.') ||
          host.startsWith('10.') ||
          host.startsWith('172.')) {
        return false;
      }

      // Must have a valid path or be a proper domain - optimized
      final path = uri.path;
      if (path.isNotEmpty && path.length > 1) {
        // Check if path looks like a file extension we don't want - optimized
        final lastSegment = path.split('/').last;
        if (lastSegment.contains('.') &&
            (lastSegment.endsWith('.jpg') ||
             lastSegment.endsWith('.jpeg') ||
             lastSegment.endsWith('.png') ||
             lastSegment.endsWith('.gif') ||
             lastSegment.endsWith('.bmp') ||
             lastSegment.endsWith('.webp') ||
             lastSegment.endsWith('.svg') ||
             lastSegment.endsWith('.ico'))) {
          return false;
        }
      }

      // Check for suspicious patterns - optimized
      if (trimmedText.contains('javascript:') ||
          trimmedText.contains('<script') ||
          trimmedText.contains('eval(') ||
          trimmedText.contains('alert(')) {
        return false;
      }

    } catch (e) {
      return false;
    }

    return true;
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
      _removedTrackers = const []; // Use const for empty lists
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
            Semantics(
              label: 'URL input field',
              hint: 'Enter or paste a URL to sanitize',
              child: TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  hintText: 'Press sanitize to auto grab from clipboard',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Sanitize URL button',
                    hint: 'Process and clean the URL from tracking parameters',
                    child: ElevatedButton(
                      onPressed: _onSanitizePressed,
                      child: const Text('Sanitize'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: 'Clear results button',
                    hint: 'Clear all processed results',
                    child: OutlinedButton(
                      onPressed: _hasProcessedUrl ? _clearResults : null,
                      child: const Text('Clear'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Redesigned Trackers Section - Only show when URL has been processed
            if (_hasProcessedUrl) ...[
              Semantics(
                label: 'Tracker detection results',
                child: Container(
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
              ),
              if (_removedTrackers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Semantics(
                  label: 'List of removed trackers',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _removedTrackers.map((tracker) {
                      return Semantics(
                        label: 'Removed tracker: $tracker',
                        child: Container(
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
                        ),
                      );
                    }).toList(),
                  ),
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
              Semantics(
                label: 'Sanitized URL result',
                child: Text(
                  _sanitizedUrl,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Copy URL button',
                      hint: 'Copy the sanitized URL to clipboard',
                      child: ElevatedButton(
                        onPressed: _copyUrl,
                        child: const Text('Copy'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Semantics(
                      label: 'Share URL button',
                      hint: 'Share the sanitized URL',
                      child: ElevatedButton(
                        onPressed: _shareUrl,
                        child: const Text('Share'),
                      ),
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
