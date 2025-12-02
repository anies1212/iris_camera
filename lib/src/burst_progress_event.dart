import 'package:flutter/foundation.dart';

/// Progress update for a burst capture.
@immutable
class BurstProgressEvent {
  const BurstProgressEvent({
    required this.total,
    required this.completed,
    this.status = BurstProgressStatus.inProgress,
    this.error,
  });

  /// Total number of frames expected in the burst.
  final int total;

  /// Number of frames completed (captured and optionally saved).
  final int completed;

  /// Current status.
  final BurstProgressStatus status;

  /// Optional error message when [status] is [BurstProgressStatus.error].
  final String? error;

  factory BurstProgressEvent.fromMap(Map<String, Object?> map) {
    final total = (map['total'] as num?)?.toInt() ?? 0;
    final completed = (map['completed'] as num?)?.toInt() ?? 0;
    final statusRaw = map['status'] as String? ?? 'inProgress';
    final status = switch (statusRaw) {
      'done' => BurstProgressStatus.done,
      'error' => BurstProgressStatus.error,
      _ => BurstProgressStatus.inProgress,
    };
    final error = map['error'] as String?;
    return BurstProgressEvent(
      total: total,
      completed: completed,
      status: status,
      error: error,
    );
  }
}

enum BurstProgressStatus { inProgress, done, error }
