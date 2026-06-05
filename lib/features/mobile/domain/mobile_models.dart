class MobileTaskItem {
  MobileTaskItem({
    required this.id,
    required this.title,
    required this.status,
    required this.weightKg,
    required this.handlingInstruction,
    required this.expectedArrival,
    required this.latitude,
    required this.longitude,
    required this.queueType,
    required this.recipientName,
    required this.recipientAddress,
    required this.proofUrl,
    required this.deliveredAt,
    required this.raw,
  });

  final String id;
  final String title;
  final String status;
  final double? weightKg;
  final String? handlingInstruction;
  final DateTime? expectedArrival;
  final double? latitude;
  final double? longitude;
  final String? queueType;
  final String? recipientName;
  final String? recipientAddress;
  final String? proofUrl;
  final DateTime? deliveredAt;
  final Map<String, dynamic> raw;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get summaryLabel {
    if (title.isNotEmpty) {
      return title;
    }
    if (recipientName != null && recipientName!.isNotEmpty) {
      return recipientName!;
    }
    return id;
  }

  factory MobileTaskItem.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json);
    return MobileTaskItem(
      id: _readString(raw, ['id', 'task_id', 'uuid']),
      title: _readString(raw, ['title', 'task_name', 'resi', 'reference']),
      status: _readString(raw, ['status', 'task_status', 'delivery_status']),
      weightKg: _readDouble(raw, ['weight', 'weight_kg', 'package_weight']),
      handlingInstruction: _readNullableString(raw, [
        'handling_instruction',
        'handling',
        'notes',
      ]),
      expectedArrival: _readDateTime(raw, [
        'expected_arrival',
        'expected_arrival_at',
        'eta',
        'arrival_at',
      ]),
      latitude: _readDouble(raw, ['latitude', 'destination_latitude', 'lat']),
      longitude: _readDouble(raw, [
        'longitude',
        'destination_longitude',
        'lng',
      ]),
      queueType: _readNullableString(raw, [
        'queue_type',
        'task_queue',
        'priority',
      ]),
      recipientName: _readNullableString(raw, [
        'recipient_name',
        'receiver_name',
        'customer_name',
      ]),
      recipientAddress: _readNullableString(raw, [
        'recipient_address',
        'receiver_address',
        'address',
        'destination_address',
      ]),
      proofUrl: _readNullableString(raw, [
        'proof_url',
        'proofUrl',
        'proof_image_url',
      ]),
      deliveredAt: _readDateTime(raw, ['delivered_at', 'deliveredAt']),
      raw: raw,
    );
  }
}

class MobileDashboardSummary {
  MobileDashboardSummary({required this.raw});

  final Map<String, dynamic> raw;

  factory MobileDashboardSummary.fromJson(Map<String, dynamic> json) {
    return MobileDashboardSummary(raw: json);
  }

  int get activeTasks =>
      _readInt(raw, ['active_tasks', 'active_count', 'activeTaskCount']);
  int get queueTasks =>
      _readInt(raw, ['queue_tasks', 'queue_count', 'queueTaskCount']);
  int get deliveredToday =>
      _readInt(raw, ['delivered_today', 'today_delivered', 'todayDelivered']);
  int get totalPackages =>
      _readInt(raw, ['total_packages', 'package_total', 'totalPackages']);
  double get totalDistance =>
      _readDouble(raw, ['total_distance', 'distance_total', 'totalDistance']) ??
      0;
  int get remainingDrops =>
      _readInt(raw, ['remaining_drops', 'drops_remaining', 'remainingDrops']);
}

class MobileTaskBoardResponse {
  MobileTaskBoardResponse({
    required this.summary,
    required this.activeTasks,
    required this.queueTasks,
  });

  final MobileDashboardSummary summary;
  final List<MobileTaskItem> activeTasks;
  final List<MobileTaskItem> queueTasks;

  factory MobileTaskBoardResponse.fromJson(Map<String, dynamic> json) {
    final payload = _readObject(json, ['data', 'result']);
    final directTasks = _readAnyTasks(payload);
    return MobileTaskBoardResponse(
      summary: MobileDashboardSummary.fromJson(
        _readObject(payload, [
          'summary',
          'daily_summary',
          'dailySummary',
          'stats',
          'profile',
          'data',
        ]),
      ),
      activeTasks: _readTasks(payload, [
        'active_tasks',
        'activeTasks',
        'active',
      ]).followedBy(directTasks.where(_isActiveLike)).toList(growable: false),
      queueTasks: _readTasks(payload, [
        'queue_tasks',
        'queueTasks',
        'queued_tasks',
        'pending_tasks',
      ]).followedBy(directTasks.where(_isQueueLike)).toList(growable: false),
    );
  }
}

class MobileTaskDetailResponse {
  MobileTaskDetailResponse({required this.task});

  final MobileTaskItem task;

  factory MobileTaskDetailResponse.fromJson(Map<String, dynamic> json) {
    final payload = _readObject(json, [
      'data',
      'task',
      'item',
      'profile',
      'courier',
    ]);
    return MobileTaskDetailResponse(task: MobileTaskItem.fromJson(payload));
  }
}

class MobileDeliverRequest {
  MobileDeliverRequest({
    required this.latitude,
    required this.longitude,
    required this.proofUrl,
  });

  final double latitude;
  final double longitude;
  final String proofUrl;

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'proof_url': proofUrl,
    };
  }
}

class MobileHistoryResponse {
  MobileHistoryResponse({
    required this.today,
    required this.yesterday,
    required this.last7Days,
  });

  final List<MobileTaskItem> today;
  final List<MobileTaskItem> yesterday;
  final List<MobileTaskItem> last7Days;

  factory MobileHistoryResponse.fromJson(Map<String, dynamic> json) {
    final payload = _readObject(json, ['data', 'result']);
    final today = _readItems(payload, ['today', 'today_items', 'todayItems']);
    final yesterday = _readItems(payload, [
      'yesterday',
      'yesterday_items',
      'yesterdayItems',
    ]);
    final last7Days = _readItems(payload, [
      'last7Days',
      'last_7_days',
      'seven_days',
    ]);
    final flatItems = _readAnyTasks(payload);

    if (today.isEmpty && yesterday.isEmpty && last7Days.isEmpty) {
      if (flatItems.isNotEmpty) {
        return MobileHistoryResponse(
          today: flatItems.where(_isDeliveredTodayLike).toList(growable: false),
          yesterday: flatItems
              .where(_isDeliveredYesterdayLike)
              .toList(growable: false),
          last7Days: flatItems
              .where(_isDeliveredLast7DaysLike)
              .toList(growable: false),
        );
      }

      final fallback = _readItems(payload, ['items', 'data', 'history']);
      return MobileHistoryResponse(
        today: fallback,
        yesterday: const [],
        last7Days: const [],
      );
    }

    return MobileHistoryResponse(
      today: today,
      yesterday: yesterday,
      last7Days: last7Days,
    );
  }
}

class MobileProfileResponse {
  MobileProfileResponse({required this.raw});

  final Map<String, dynamic> raw;

  factory MobileProfileResponse.fromJson(Map<String, dynamic> json) {
    return MobileProfileResponse(
      raw: _readObject(json, ['data', 'result', 'profile', 'courier', 'user']),
    );
  }

  String get name => _readString(raw, ['name', 'full_name', 'courier_name']);
  String get email => _readString(raw, ['email']);
  double get efficiencyScore =>
      _readDouble(raw, ['efficiency_score', 'efficiencyScore']) ?? 0;
  int get totalPackages => _readInt(raw, ['total_packages', 'totalPackages']);
  int get deliveredPackages =>
      _readInt(raw, ['delivered_packages', 'deliveredPackages']);
  int get activeTasks => _readInt(raw, ['active_tasks', 'activeTasks']);
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  return _readNullableString(json, keys) ?? '-';
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text != 'null') {
      return text;
    }
  }
  return null;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      final parsed = double.tryParse(text);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toInt();
    }
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      final parsed = int.tryParse(text);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return 0;
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return DateTime.tryParse(text);
    }
  }
  return null;
}

Map<String, dynamic> _readObject(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
  }
  return json;
}

List<MobileTaskItem> _readTasks(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List<dynamic>) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(MobileTaskItem.fromJson)
          .toList(growable: false);
    }
  }
  return const <MobileTaskItem>[];
}

List<MobileTaskItem> _readAnyTasks(Map<String, dynamic> json) {
  final nestedCandidates = <List<dynamic>>[
    if (json['data'] is List<dynamic>) json['data'] as List<dynamic>,
    if (json['items'] is List<dynamic>) json['items'] as List<dynamic>,
    if (json['tasks'] is List<dynamic>) json['tasks'] as List<dynamic>,
    if (json['active_tasks'] is List<dynamic>)
      json['active_tasks'] as List<dynamic>,
    if (json['queue_tasks'] is List<dynamic>)
      json['queue_tasks'] as List<dynamic>,
    if (json['history'] is List<dynamic>) json['history'] as List<dynamic>,
  ];

  final items = nestedCandidates
      .expand((candidate) => candidate.whereType<Map<String, dynamic>>())
      .map(MobileTaskItem.fromJson)
      .toList(growable: false);

  return items;
}

bool _isActiveLike(MobileTaskItem task) {
  final status = task.status.toUpperCase();
  final queue = (task.queueType ?? '').toUpperCase();
  return status == 'OUT_FOR_DELIVERY' ||
      status == 'ACTIVE' ||
      status == 'IN_PROGRESS' ||
      queue == 'ACTIVE' ||
      queue == 'OUT_FOR_DELIVERY';
}

bool _isQueueLike(MobileTaskItem task) {
  final status = task.status.toUpperCase();
  final queue = (task.queueType ?? '').toUpperCase();
  return status == 'QUEUED' ||
      status == 'PENDING' ||
      status == 'WAITING' ||
      queue == 'QUEUE' ||
      queue == 'PENDING' ||
      queue == 'WAITING';
}

bool _isDeliveredTodayLike(MobileTaskItem task) {
  if (!_isDeliveredLike(task)) {
    return false;
  }
  final deliveredAt = task.deliveredAt;
  if (deliveredAt == null) {
    return false;
  }
  final now = DateTime.now().toLocal();
  return deliveredAt.toLocal().year == now.year &&
      deliveredAt.toLocal().month == now.month &&
      deliveredAt.toLocal().day == now.day;
}

bool _isDeliveredYesterdayLike(MobileTaskItem task) {
  if (!_isDeliveredLike(task) || task.deliveredAt == null) {
    return false;
  }
  final now = DateTime.now().toLocal().subtract(const Duration(days: 1));
  final delivered = task.deliveredAt!.toLocal();
  return delivered.year == now.year &&
      delivered.month == now.month &&
      delivered.day == now.day;
}

bool _isDeliveredLast7DaysLike(MobileTaskItem task) {
  if (!_isDeliveredLike(task) || task.deliveredAt == null) {
    return false;
  }
  final delivered = task.deliveredAt!.toLocal();
  final now = DateTime.now().toLocal();
  final difference = now.difference(delivered).inDays;
  return difference >= 0 && difference <= 7;
}

bool _isDeliveredLike(MobileTaskItem task) {
  final status = task.status.toUpperCase();
  return status == 'DELIVERED' || status == 'COMPLETED' || status == 'DONE';
}

List<MobileTaskItem> _readItems(Map<String, dynamic> json, List<String> keys) {
  return _readTasks(json, keys);
}
