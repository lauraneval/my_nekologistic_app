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
      handlingInstruction: _readNullableString(raw, ['handling_instruction', 'handling', 'notes']),
      expectedArrival: _readDateTime(raw, ['expected_arrival', 'expected_arrival_at', 'eta', 'arrival_at']),
      latitude: _readDouble(raw, ['latitude', 'destination_latitude', 'lat']),
      longitude: _readDouble(raw, ['longitude', 'destination_longitude', 'lng']),
      queueType: _readNullableString(raw, ['queue_type', 'task_queue', 'priority']),
      recipientName: _readNullableString(raw, ['recipient_name', 'receiver_name', 'customer_name']),
      recipientAddress: _readNullableString(raw, ['recipient_address', 'receiver_address', 'address', 'destination_address']),
      proofUrl: _readNullableString(raw, ['proof_url', 'proofUrl', 'proof_image_url']),
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

  int get activeTasks => _readInt(raw, ['active_tasks', 'active_count', 'activeTaskCount']);
  int get queueTasks => _readInt(raw, ['queue_tasks', 'queue_count', 'queueTaskCount']);
  int get deliveredToday => _readInt(raw, ['delivered_today', 'today_delivered', 'todayDelivered']);
  int get totalPackages => _readInt(raw, ['total_packages', 'package_total', 'totalPackages']);
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
    return MobileTaskBoardResponse(
      summary: MobileDashboardSummary.fromJson(_readObject(payload, ['summary', 'daily_summary', 'dailySummary', 'stats'])),
      activeTasks: _readTasks(payload, ['active_tasks', 'activeTasks', 'active']),
      queueTasks: _readTasks(payload, ['queue_tasks', 'queueTasks', 'queued_tasks', 'pending_tasks']),
    );
  }
}

class MobileTaskDetailResponse {
  MobileTaskDetailResponse({required this.task});

  final MobileTaskItem task;

  factory MobileTaskDetailResponse.fromJson(Map<String, dynamic> json) {
    return MobileTaskDetailResponse(task: MobileTaskItem.fromJson(_readObject(json, ['data', 'task', 'item'])));
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
    final yesterday = _readItems(payload, ['yesterday', 'yesterday_items', 'yesterdayItems']);
    final last7Days = _readItems(payload, ['last7Days', 'last_7_days', 'seven_days']);

    if (today.isEmpty && yesterday.isEmpty && last7Days.isEmpty) {
      final fallback = _readItems(payload, ['items', 'data', 'history']);
      return MobileHistoryResponse(today: fallback, yesterday: const [], last7Days: const []);
    }

    return MobileHistoryResponse(today: today, yesterday: yesterday, last7Days: last7Days);
  }
}

class MobileProfileResponse {
  MobileProfileResponse({required this.raw});

  final Map<String, dynamic> raw;

  factory MobileProfileResponse.fromJson(Map<String, dynamic> json) {
    return MobileProfileResponse(raw: _readObject(json, ['data', 'result']));
  }

  String get name => _readString(raw, ['name', 'full_name', 'courier_name']);
  String get email => _readString(raw, ['email']);
  double get efficiencyScore => _readDouble(raw, ['efficiency_score', 'efficiencyScore']) ?? 0;
  int get totalPackages => _readInt(raw, ['total_packages', 'totalPackages']);
  int get deliveredPackages => _readInt(raw, ['delivered_packages', 'deliveredPackages']);
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
      return value.whereType<Map<String, dynamic>>().map(MobileTaskItem.fromJson).toList(growable: false);
    }
  }
  return const <MobileTaskItem>[];
}

List<MobileTaskItem> _readItems(Map<String, dynamic> json, List<String> keys) {
  return _readTasks(json, keys);
}
