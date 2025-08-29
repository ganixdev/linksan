import 'dart:async';
import 'dart:developer' as developer;

/// Performance monitoring utility for LinkSan
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<int>> _performanceMetrics = {};

  /// Start timing an operation
  void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
  }

  /// Stop timing and record the operation
  void stopTimer(String operation) {
    final timer = _timers.remove(operation);
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;

      // Record metric
      _performanceMetrics.putIfAbsent(operation, () => []).add(duration);

      // Keep only last 100 measurements to prevent memory bloat
      if (_performanceMetrics[operation]!.length > 100) {
        _performanceMetrics[operation]!.removeAt(0);
      }

      // Log performance in debug mode
      developer.log('Performance: $operation took ${duration}ms', name: 'LinkSan.Performance');
    }
  }

  /// Get average performance for an operation
  double getAverageTime(String operation) {
    final metrics = _performanceMetrics[operation];
    if (metrics == null || metrics.isEmpty) return 0.0;

    final sum = metrics.reduce((a, b) => a + b);
    return sum / metrics.length;
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};

    for (final entry in _performanceMetrics.entries) {
      final metrics = entry.value;
      if (metrics.isNotEmpty) {
        final sum = metrics.reduce((a, b) => a + b);
        final avg = sum / metrics.length;
        final min = metrics.reduce((a, b) => a < b ? a : b);
        final max = metrics.reduce((a, b) => a > b ? a : b);

        stats[entry.key] = {
          'average': avg,
          'min': min,
          'max': max,
          'count': metrics.length,
        };
      }
    }

    return stats;
  }

  /// Clear all performance data
  void clearMetrics() {
    _performanceMetrics.clear();
    _timers.clear();
  }
}

/// Performance monitoring mixin for widgets
mixin PerformanceMixin {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  /// Execute operation with performance monitoring
  Future<T> monitorAsync<T>(String operation, Future<T> Function() action) async {
    _monitor.startTimer(operation);
    try {
      final result = await action();
      return result;
    } finally {
      _monitor.stopTimer(operation);
    }
  }

  /// Execute synchronous operation with performance monitoring
  T monitorSync<T>(String operation, T Function() action) {
    _monitor.startTimer(operation);
    try {
      return action();
    } finally {
      _monitor.stopTimer(operation);
    }
  }

  /// Get performance monitor instance
  PerformanceMonitor get performanceMonitor => _monitor;
}
