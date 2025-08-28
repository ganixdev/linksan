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
  String _trackersText = 'Trackers: None';
  Color _trackersColor = Colors.green;
  List<String> _removedTrackers = [];

  @override
  void initState() {
    super.initState();
    // _setupSharingIntent(); // Commented out for build
  }

  // void _setupSharingIntent() {
  //   // Listen for shared text
  //   ReceiveSharingIntent.getTextStream().listen((String? value) {
  //     if (value != null && value.isNotEmpty) {
  //       _sanitizeUrl(value, fromShare: true);
  //     }
  //   });

  //   // Handle initial shared text
  //   ReceiveSharingIntent.getInitialText().then((String? value) {
  //     if (value != null && value.isNotEmpty) {
  //       _sanitizeUrl(value, fromShare: true);
  //     }
  //   });
  // }

  Future<void> _sanitizeUrl(String url, {bool fromShare = false}) async {
    final result = await UrlManipulator.sanitizeUrl(url);
    final sanitizedUrl = result['sanitizedUrl'] as String;
    final removedCount = result['removedCount'] as int;
    final removedTrackers = result['removedTrackers'] as List<String>;
    final domain = result['domain'] as String;

    setState(() {
      _sanitizedUrl = sanitizedUrl;
      _removedTrackers = removedTrackers;
      if (removedCount > 0) {
        _trackersText = 'Trackers: $removedCount found';
        _trackersColor = Colors.red;
      } else {
        _trackersText = 'Trackers: None';
        _trackersColor = Colors.green;
      }
    });

    // Show toast
    String toastMessage;
    if (removedCount > 0) {
      toastMessage = '$removedCount trackers removed from $domain';
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
      url = await FlutterClipboard.paste() ?? '';
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
              decoration: const InputDecoration(
                hintText: 'Paste URL here or press Sanitize to auto-grab from clipboard',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onSanitizePressed,
              child: const Text('Sanitize'),
            ),
            const SizedBox(height: 16),
            Text(
              _trackersText,
              style: TextStyle(color: _trackersColor, fontSize: 16),
            ),
            if (_removedTrackers.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Removed Trackers:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _removedTrackers.map((tracker) {
                  return Text(
                    tracker,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
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
