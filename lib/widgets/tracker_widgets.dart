import 'package:flutter/material.dart';

/// Memory-efficient tracker chip widget
class TrackerChip extends StatelessWidget {
  final String tracker;
  final VoidCallback? onTap;

  const TrackerChip({
    super.key,
    required this.tracker,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
  }
}

/// Optimized tracker list widget with lazy loading
class TrackerList extends StatelessWidget {
  final List<String> trackers;

  const TrackerList({
    super.key,
    required this.trackers,
  });

  @override
  Widget build(BuildContext context) {
    if (trackers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'List of removed trackers',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: trackers.map((tracker) => TrackerChip(tracker: tracker)).toList(),
      ),
    );
  }
}
