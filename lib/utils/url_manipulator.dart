import 'dart:convert';
import 'package:flutter/services.dart';

class UrlManipulator {
  static Future<Map<String, dynamic>> sanitizeUrl(String url) async {
    try {
      // Load rules from assets
      final rulesString = await rootBundle.loadString('assets/rules.json');
      final rules = json.decode(rulesString);
      final trackers = List<String>.from(rules['trackers']);

      // Parse the URL
      final uri = Uri.parse(url);

      // Extract domain for toast
      final domain = uri.host;

      // Remove tracking parameters
      final queryParams = Map<String, String>.from(uri.queryParameters);
      int removedCount = 0;

      for (final tracker in trackers) {
        if (queryParams.containsKey(tracker)) {
          queryParams.remove(tracker);
          removedCount++;
        }
      }

      // Rebuild the URL
      final sanitizedUri = uri.replace(queryParameters: queryParams);
      final sanitizedUrl = sanitizedUri.toString();

      return {
        'sanitizedUrl': sanitizedUrl,
        'removedCount': removedCount,
        'domain': domain,
      };
    } catch (e) {
      // If parsing fails, return original
      return {
        'sanitizedUrl': url,
        'removedCount': 0,
        'domain': 'unknown',
      };
    }
  }
}
