class MobileTaskItem {
  MobileTaskItem({
    required this.id,
    required this.packageId,
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
    required this.recipientPhone,
    required this.recipientEmail,
    required this.packageName,
    required this.accessCode,
    required this.bagCode,
    required this.proofUrl,
    required this.deliveredAt,
    required this.senderName,
    required this.senderPhone,
    required this.senderEmail,
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    required this.raw,
  });

  final String id;
  /// Non-null only when this card represents one package inside a multi-package bag.
  /// The bag's own [id] is kept for navigation; [packageId] is sent to the server
  /// on delivery so only this specific package is marked delivered.
  final String? packageId;
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
  final String? recipientPhone;
  final String? recipientEmail;
  final String? packageName;
  final String? accessCode;
  final String? bagCode;
  final String? proofUrl;
  final DateTime? deliveredAt;
  final String? senderName;
  final String? senderPhone;
  final String? senderEmail;
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
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
      packageId: _readNullableString(raw, ['package_id', 'packageId']),
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
      recipientPhone: _readNullableString(raw, [
        'recipient_phone',
        'receiver_phone',
        'phone',
        'phone_number',
      ]),
      recipientEmail: _readNullableString(raw, [
        'recipient_email',
        'receiver_email',
        'email',
      ]),
      packageName: _readNullableString(raw, [
        'package_name',
        'packageName',
        'item_name',
        'product_name',
      ]),
      accessCode: _readNullableString(raw, [
        'access_code',
        'accessCode',
        'code',
        'pin',
      ]),
      bagCode: _readNullableString(raw, [
        'bag_code',
        'bagCode',
        'tracking_code',
        'resi',
      ]),
      proofUrl: _readNullableString(raw, [
        'proof_url',
        'proofUrl',
        'proof_image_url',
      ]),
      deliveredAt: _readDateTime(raw, ['delivered_at', 'deliveredAt']),
      senderName: _readNullableString(raw, ['sender_name', 'senderName']),
      senderPhone: _readNullableString(raw, ['sender_phone', 'senderPhone']),
      senderEmail: _readNullableString(raw, ['sender_email', 'senderEmail']),
      lengthCm: _readDouble(raw, ['length_cm', 'lengthCm']),
      widthCm: _readDouble(raw, ['width_cm', 'widthCm']),
      heightCm: _readDouble(raw, ['height_cm', 'heightCm']),
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
  double get totalDistanceKm =>
      _readDouble(raw, ['total_distance_km', 'totalDistanceKm', 'distance_km']) ?? 0.0;
  int get remainingDrop =>
      _readInt(raw, ['remaining_drop', 'remainingDrop', 'remaining_drops', 'drops_remaining']);
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
    final explicitActive = _readTasks(payload, ['active_tasks', 'activeTasks', 'active']);
    final explicitQueue = _readTasks(payload, [
      'queue_tasks', 'queueTasks', 'queued_tasks', 'pending_tasks',
    ]);

    final List<MobileTaskItem> activeTasks;
    final List<MobileTaskItem> queueTasks;

    if (explicitActive.isNotEmpty || explicitQueue.isNotEmpty) {
      activeTasks = explicitActive;
      queueTasks = explicitQueue;
    } else {
      final directTasks = _readAnyTasks(payload);
      activeTasks = directTasks.where(_isActiveLike).toList(growable: false);
      queueTasks = directTasks.where(_isQueueLike).toList(growable: false);
    }

    return MobileTaskBoardResponse(
      summary: MobileDashboardSummary.fromJson(
        _readObject(payload, [
          'summary', 'daily_summary', 'dailySummary', 'stats', 'profile', 'data',
        ]),
      ),
      activeTasks: activeTasks,
      queueTasks: queueTasks,
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
    // Merge sub-objects (user, courier, profile) so all fields are accessible
    // regardless of nesting. Top-level keys win over sub-object keys.
    final merged = <String, dynamic>{};
    for (final key in ['user', 'courier', 'profile', 'result', 'data']) {
      final obj = json[key];
      if (obj is Map<String, dynamic>) merged.addAll(obj);
    }
    merged.addAll(json); // top-level wins
    return MobileProfileResponse(raw: merged);
  }

  String get name => _readString(raw, ['name', 'full_name', 'courier_name', 'username']);
  String get email => _readString(raw, ['email', 'email_address', 'courier_email', 'user_email']);
  String get phone => _readString(raw, [
    'phone', 'phone_number', 'mobile', 'contact_phone',
    'no_hp', 'nomor_hp', 'telephone', 'telepon', 'hp', 'no_telepon',
  ]);
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
          .expand(_expandBagPackages)
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

  return nestedCandidates
      .expand((candidate) => candidate.whereType<Map<String, dynamic>>())
      .expand(_expandBagPackages)
      .toList(growable: false);
}

/// If a bag has multiple packages, expand into one MobileTaskItem per package.
/// Package-specific data (receiver, resi, weight, dimensions) overrides bag-level.
/// bag id is kept as [id] so navigation to task detail still works.
/// The individual package's own id is stored as [packageId] so that POD submission
/// can target only that package rather than the whole bag.
Iterable<MobileTaskItem> _expandBagPackages(Map<String, dynamic> bagJson) {
  final packages = bagJson['packages'];
  if (packages is List<dynamic> && packages.length > 1) {
    return packages.whereType<Map<String, dynamic>>().map((pkg) {
      final pkgId = pkg['id']?.toString() ?? pkg['package_id']?.toString();
      final merged = <String, dynamic>{
        ...bagJson,
        ...pkg,
        // Bag-level fields that must not be overridden by per-package values:
        'id': bagJson['id'],           // bag id kept for navigation
        'package_id': pkgId,           // real per-package id for POD targeting
        'bag_code': bagJson['bag_code'] ?? bagJson['bagCode'],
        'status': pkg['status'] ?? bagJson['status'],
        // Delivery coordinates belong to the BAG (all packages in one bag share
        // the same drop-off point). Per-package lat/lng (if present) are typically
        // pickup points and must not replace the bag's delivery destination.
        'latitude': bagJson['latitude'],
        'longitude': bagJson['longitude'],
        'destination_latitude': bagJson['destination_latitude'],
        'destination_longitude': bagJson['destination_longitude'],
        'lat': bagJson['lat'],
        'lng': bagJson['lng'],
      };
      return MobileTaskItem.fromJson(merged);
    });
  }
  return [MobileTaskItem.fromJson(bagJson)];
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
