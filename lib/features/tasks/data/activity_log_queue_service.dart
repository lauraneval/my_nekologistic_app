import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ActivityLogQueueService {
  ActivityLogQueueService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _queueKey = 'pending_activity_logs';

  final FlutterSecureStorage _storage;
  bool _isFlushing = false;

  Future<void> enqueue(
    Map<String, dynamic> payload, {
    required int maxItems,
    required int maxRetry,
  }) async {
    final queue = await _readQueue();
    queue.add({
      'payload': payload,
      'attempts': 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    final trimmed = queue
        .where((item) => (item['attempts'] as int? ?? 0) <= maxRetry)
        .toList(growable: true);

    while (trimmed.length > maxItems) {
      trimmed.removeAt(0);
    }

    await _writeQueue(trimmed);
  }

  Future<void> flush({
    required Future<void> Function(Map<String, dynamic>) sender,
    required int maxRetry,
  }) async {
    if (_isFlushing) {
      return;
    }

    _isFlushing = true;
    try {
      final queue = await _readQueue();
      if (queue.isEmpty) {
        return;
      }

      final pending = <Map<String, dynamic>>[];

      for (final item in queue) {
        final attempts = (item['attempts'] as int? ?? 0) + 1;
        final payload = item['payload'];

        if (payload is! Map<String, dynamic>) {
          continue;
        }

        try {
          await sender(payload);
        } catch (_) {
          if (attempts <= maxRetry) {
            pending.add({...item, 'attempts': attempts});
          }
        }
      }

      await _writeQueue(pending);
    } finally {
      _isFlushing = false;
    }
  }

  Future<List<Map<String, dynamic>>> _readQueue() async {
    final raw = await _storage.read(key: _queueKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <Map<String, dynamic>>[];
    }

    return decoded.whereType<Map<String, dynamic>>().toList(growable: true);
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> queue) async {
    await _storage.write(key: _queueKey, value: jsonEncode(queue));
  }
}
