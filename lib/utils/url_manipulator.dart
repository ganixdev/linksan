import 'dart:convert';
import 'package:flutter/services.dart';

class UrlManipulator {
  static Future<Map<String, dynamic>> sanitizeUrl(String url) async {
    try {
      // Load rules from assets
      final rulesString = await rootBundle.loadString('assets/rules.json');
      final rules = json.decode(rulesString);

      // Extract tracking parameters and domain-specific rules
      final trackingParams = List<String>.from(rules['tracking_parameters']);
      final domainRules = rules['domain_specific_rules'] as Map<String, dynamic>;

      // Parse the URL
      final uri = Uri.parse(url);

      // Extract domain for toast and domain-specific processing
      final domain = _extractDomain(uri.host);

      // Get current query parameters
      final queryParams = Map<String, String>.from(uri.queryParameters);
      int removedCount = 0;

      // Check if domain has specific rules
      if (domainRules.containsKey(domain)) {
        final domainRule = domainRules[domain] as Map<String, dynamic>;
        final keepParams = List<String>.from(domainRule['keep'] ?? []);
        final removeParams = List<String>.from(domainRule['remove'] ?? []);

        // Remove domain-specific parameters
        for (final param in removeParams) {
          if (queryParams.containsKey(param)) {
            queryParams.remove(param);
            removedCount++;
          }
        }

        // Remove all tracking parameters except those to keep
        for (final param in trackingParams) {
          if (!keepParams.contains(param) && queryParams.containsKey(param)) {
            queryParams.remove(param);
            removedCount++;
          }
        }
      } else {
        // No domain-specific rules, remove all tracking parameters
        for (final param in trackingParams) {
          if (queryParams.containsKey(param)) {
            queryParams.remove(param);
            removedCount++;
          }
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

  static String _extractDomain(String host) {
    // Handle subdomains by taking the main domain
    final parts = host.split('.');
    if (parts.length >= 2) {
      // For domains like www.example.com, return example.com
      if (parts.length == 3 && parts[0] == 'www') {
        return '${parts[1]}.${parts[2]}';
      }
      // For domains like sub.example.com, return example.com
      if (parts.length > 2) {
        return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
      }
      // For simple domains like example.com
      return host;
    }
    return host;
  }
}
