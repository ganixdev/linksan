import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class UrlManipulator {
  // Cache for rules to avoid repeated JSON parsing
  static Map<String, dynamic>? _cachedRules;
  static List<String>? _cachedTrackingParams;

  // Helper method to load and cache rules
  static Future<Map<String, dynamic>> _loadRules() async {
    if (_cachedRules == null) {
      final rulesString = await rootBundle.loadString('assets/rules.json');
      _cachedRules = json.decode(rulesString) as Map<String, dynamic>;
      _cachedTrackingParams = List<String>.from(_cachedRules!['tracking_parameters'] as List);
    }
    return _cachedRules!;
  }

  static Future<Map<String, dynamic>> sanitizeUrl(String url) async {
    try {
      // Load and cache rules - optimized with caching
      final rules = await _loadRules();
      final trackingParams = _cachedTrackingParams!;
      final domainRules = rules['domain_specific_rules'] as Map<String, dynamic>;

      // Parse the URL - optimized
      final uri = Uri.parse(url);

      // Extract initial domain - optimized
      String domain = _extractDomain(uri.host);

      // Handle Google redirect URLs
      String actualUrl = url;
      if (domain == 'google.com' && uri.path == '/url' && uri.queryParameters.containsKey('url')) {
        // Extract the actual URL from the 'url' parameter
        final encodedUrl = uri.queryParameters['url'];
        if (encodedUrl != null) {
          try {
            actualUrl = Uri.decodeFull(encodedUrl);
            // Re-parse the actual URL for further processing
            final actualUri = Uri.parse(actualUrl);
            final destinationDomain = _extractDomain(actualUri.host);

            // First, remove trackers from the Google redirect URL itself
            final googleQueryParams = Map<String, String>.from(uri.queryParameters);
            int totalRemovedCount = 0;
            List<String> allRemovedTrackers = [];

            // Remove Google-specific tracking parameters
            if (domainRules.containsKey(domain)) {
              final domainRule = domainRules[domain] as Map<String, dynamic>;
              final keepParams = List<String>.from(domainRule['keep'] ?? []);
              final removeParams = List<String>.from(domainRule['remove'] ?? []);

              // Remove domain-specific parameters from Google URL - optimized
              for (final param in removeParams) {
                if (googleQueryParams.containsKey(param)) {
                  googleQueryParams.remove(param);
                  allRemovedTrackers.add(param);
                  totalRemovedCount++;
                }
              }

              // Remove general tracking parameters from Google URL (except those to keep) - optimized
              for (final param in trackingParams) {
                if (!keepParams.contains(param) && googleQueryParams.containsKey(param)) {
                  googleQueryParams.remove(param);
                  allRemovedTrackers.add(param);
                  totalRemovedCount++;
                }
              }
            }

            // Now process the destination URL
            final destinationQueryParams = Map<String, String>.from(actualUri.queryParameters);

            // Apply rules based on the destination domain
            if (domainRules.containsKey(destinationDomain)) {
              final domainRule = domainRules[destinationDomain] as Map<String, dynamic>;
              final keepParams = List<String>.from(domainRule['keep'] ?? []);
              final removeParams = List<String>.from(domainRule['remove'] ?? []);

              // Remove domain-specific parameters from destination URL
              for (final param in removeParams) {
                if (destinationQueryParams.containsKey(param)) {
                  destinationQueryParams.remove(param);
                  allRemovedTrackers.add(param);
                  totalRemovedCount++;
                }
              }

              // Remove general tracking parameters from destination URL (except those to keep)
              for (final param in trackingParams) {
                if (!keepParams.contains(param) && destinationQueryParams.containsKey(param)) {
                  destinationQueryParams.remove(param);
                  allRemovedTrackers.add(param);
                  totalRemovedCount++;
                }
              }
            } else {
              // No domain-specific rules for destination, remove all tracking parameters
              for (final param in trackingParams) {
                if (destinationQueryParams.containsKey(param)) {
                  destinationQueryParams.remove(param);
                  allRemovedTrackers.add(param);
                  totalRemovedCount++;
                }
              }
            }

            // Rebuild the destination URL with cleaned parameters
            final sanitizedUri = actualUri.replace(queryParameters: destinationQueryParams);
            final sanitizedUrl = sanitizedUri.toString();

            return {
              'sanitizedUrl': sanitizedUrl,
              'removedCount': totalRemovedCount,
              'removedTrackers': allRemovedTrackers,
              'domain': destinationDomain,
            };
          } catch (e) {
            // If decoding fails, continue with original URL
            actualUrl = url;
          }
        }
      }

      // Continue with normal processing using the actual URL
      final processingUri = Uri.parse(actualUrl);

      // Get current query parameters
      final queryParams = Map<String, String>.from(processingUri.queryParameters);
      int removedCount = 0;
      List<String> removedTrackers = [];

      // Check if domain has specific rules
      if (domainRules.containsKey(domain)) {
        final domainRule = domainRules[domain] as Map<String, dynamic>;
        final keepParams = List<String>.from(domainRule['keep'] ?? []);
        final removeParams = List<String>.from(domainRule['remove'] ?? []);

        // Remove domain-specific parameters
        for (final param in removeParams) {
          if (queryParams.containsKey(param)) {
            queryParams.remove(param);
            removedTrackers.add(param);
            removedCount++;
          }
        }

        // Remove all tracking parameters except those to keep
        for (final param in trackingParams) {
          if (!keepParams.contains(param) && queryParams.containsKey(param)) {
            queryParams.remove(param);
            removedTrackers.add(param);
            removedCount++;
          }
        }
      } else {
        // No domain-specific rules, remove all tracking parameters
        for (final param in trackingParams) {
          if (queryParams.containsKey(param)) {
            queryParams.remove(param);
            removedTrackers.add(param);
            removedCount++;
          }
        }
      }

      // Rebuild the URL
      final sanitizedUri = processingUri.replace(queryParameters: queryParams);
      final sanitizedUrl = sanitizedUri.toString();

      return {
        'sanitizedUrl': sanitizedUrl,
        'removedCount': removedCount,
        'removedTrackers': removedTrackers,
        'domain': domain,
      };
    } catch (e) {
      // Return original URL with error info - optimized
      return {
        'sanitizedUrl': url,
        'removedCount': 0,
        'removedTrackers': const [], // Use const for empty lists
        'domain': 'unknown',
      };
    }
  }

  static String _extractDomain(String host) {
    // Handle subdomains by taking the main domain - optimized
    final parts = host.split('.');
    final length = parts.length;

    if (length >= 2) {
      // For domains like www.example.com, return example.com
      if (length == 3 && parts[0] == 'www') {
        return '${parts[1]}.${parts[2]}';
      }
      // For domains like sub.example.com, return example.com
      if (length > 2) {
        return '${parts[length - 2]}.${parts[length - 1]}';
      }
      // For simple domains like example.com
      return host;
    }
    return host;
  }
}
