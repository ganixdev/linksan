import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/services.dart';
import 'utils/url_manipulator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

const platform = MethodChannel('com.ganixdev.linksan/url');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkSan',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // Performance optimizations
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _urlController = TextEditingController();
  String _sanitizedUrl = '';
  Color _trackersColor = Colors.green;
  List<String> _removedTrackers = [];
  bool _hasProcessedUrl = false;
  bool _isProcessing = false;
  bool _rulesPreloaded = false;

  // Performance: Keep state alive to avoid rebuilds
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Performance: Add listener efficiently
    _urlController.addListener(_onTextChanged);
    
    // Preload rules in background for faster first sanitization
    _preloadRulesAsync();
    
    // Handle shared URLs from iOS share extension
    platform.setMethodCallHandler(_handleMethodCall);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _preloadRulesAsync() async {
    try {
      await UrlManipulator.preloadRules();
      if (mounted) {
        setState(() => _rulesPreloaded = true);
      }
    } catch (e) {
      // Silently handle preload errors
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      if (call.method == 'handleSharedUrl') {
        final String url = call.arguments as String;
        if (url.isNotEmpty && mounted) {
          await _sanitizeUrl(url, fromShare: true);
        }
      }
    } catch (e) {
      // Error handling for shared URL
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onTextChanged);
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _sanitizeUrl(String url, {bool fromShare = false}) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final result = await UrlManipulator.sanitizeUrl(url);
      final sanitizedUrl = result['sanitizedUrl'] as String;
      final removedCount = result['removedCount'] as int;
      final removedTrackers = result['removedTrackers'] as List<String>;
      final domain = result['domain'] as String;

      if (mounted) {
        setState(() {
          _sanitizedUrl = sanitizedUrl;
          _removedTrackers = removedTrackers;
          _hasProcessedUrl = true;
          _isProcessing = false;
          _trackersColor = removedCount > 0 ? Colors.red : Colors.green;
        });

        final toastMessage = removedCount > 0
            ? '$removedCount tracker${removedCount == 1 ? '' : 's'} removed from $domain'
            : 'No trackers found';
        Fluttertoast.showToast(msg: toastMessage);

        if (fromShare) {
          final shareMessage = removedCount > 0
              ? '$removedCount tracker${removedCount == 1 ? '' : 's'} removed from shared URL'
              : 'Shared URL is clean - no trackers found';
          Fluttertoast.showToast(msg: shareMessage, toastLength: Toast.LENGTH_LONG);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        Fluttertoast.showToast(msg: 'Error processing URL: ${e.toString()}');
      }
    }
  }

  Future<void> _onSanitizePressed() async {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
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
        setState(() {
          _sanitizedUrl = '';
          _removedTrackers = [];
          _hasProcessedUrl = false;
          _trackersColor = Colors.green;
        });
      }
    }
  }

  // Optimized URL validation - early returns for performance
  bool _isValidUrl(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || trimmedText.length < 10) return false;
    if (!trimmedText.startsWith('http://') && !trimmedText.startsWith('https://')) return false;

    try {
      final uri = Uri.parse(trimmedText);
      final host = uri.host;
      if (host.isEmpty || host.length < 4) return false;
      if (host == 'localhost' || host == '127.0.0.1' || host.startsWith('192.168.') || 
          host.startsWith('10.') || host.startsWith('172.')) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkSan'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(), // iOS-style scrolling
          child: Column(
            children: [
              // Header Card - Simplified for performance
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.link_off,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'URL Sanitizer',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Remove tracking parameters from URLs',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      // Show preload status
                      if (!_rulesPreloaded) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading rules...',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Input Section - Optimized
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter URL:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/...',
                          border: const OutlineInputBorder(),
                          suffixIcon: _urlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _urlController.clear(),
                                )
                              : null,
                        ),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _onSanitizePressed(),
                        // Performance: Limit rebuilds
                        enableSuggestions: false,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: (_isProcessing || !_rulesPreloaded) ? null : _onSanitizePressed,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cleaning_services),
                          label: Text(_isProcessing 
                              ? 'Processing...' 
                              : !_rulesPreloaded 
                                  ? 'Loading...' 
                                  : 'Sanitize URL'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Results Section - Conditionally rendered for performance
              if (_hasProcessedUrl) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _trackersColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _trackersColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _removedTrackers.isEmpty ? Icons.shield : Icons.warning,
                                size: 16,
                                color: _trackersColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _removedTrackers.isEmpty 
                                    ? 'Clean URL' 
                                    : '${_removedTrackers.length} tracker${_removedTrackers.length == 1 ? '' : 's'} removed',
                                style: TextStyle(
                                  color: _trackersColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sanitized URL
                        Text(
                          'Sanitized URL:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: SelectableText(
                            _sanitizedUrl,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _copyUrl,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _shareUrl,
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                              ),
                            ),
                          ],
                        ),

                        // Removed Trackers - Only if any exist
                        if (_removedTrackers.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Removed trackers:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _removedTrackers.map((tracker) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  tracker,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Footer
              Text(
                'Made with ❤️ by ganixdev',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}