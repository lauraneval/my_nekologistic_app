class CourierBagTask {
  CourierBagTask({
    required this.id,
    required this.bagCode,
    required this.destinationCity,
    required this.packageCount,
    required this.status,
    required this.assignedCourierId,
    required this.receiverName,
    required this.receiverAddress,
    required this.latitude,
    required this.longitude,
    required this.packages,
  });

  final String id;
  final String bagCode;
  final String destinationCity;
  final int packageCount;
  final String status;
  final String? assignedCourierId;
  final String? receiverName;
  final String? receiverAddress;
  final double? latitude;
  final double? longitude;
  final List<CourierBagPackage> packages;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory CourierBagTask.fromJson(Map<String, dynamic> json) {
    return CourierBagTask(
      id: (json['id'] ?? '').toString(),
      bagCode: (json['bag_code'] ?? '').toString(),
      destinationCity: (json['destination_city'] ?? '').toString(),
      packageCount: _readInt(json['package_count']),
      status: (json['status'] ?? '').toString(),
      assignedCourierId: _readNullableString(json['assigned_courier_id']),
      receiverName: _readNullableString(json['receiver_name']),
      receiverAddress: _readNullableString(json['receiver_address']),
      latitude: _readNullableDouble(json['latitude']),
      longitude: _readNullableDouble(json['longitude']),
      packages: _readList(json['packages'])
          .whereType<Map<String, dynamic>>()
          .map(CourierBagPackage.fromJson)
          .toList(growable: false),
    );
  }
}

class CourierBagSummary {
  CourierBagSummary({
    required this.id,
    required this.bagCode,
    required this.destinationCity,
    required this.status,
    required this.assignedCourierId,
  });

  final String id;
  final String bagCode;
  final String destinationCity;
  final String status;
  final String? assignedCourierId;

  factory CourierBagSummary.fromJson(Map<String, dynamic> json) {
    return CourierBagSummary(
      id: (json['id'] ?? '').toString(),
      bagCode: (json['bag_code'] ?? '').toString(),
      destinationCity: (json['destination_city'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      assignedCourierId: _readNullableString(json['assigned_courier_id']),
    );
  }
}

class CourierBagPackage {
  CourierBagPackage({
    required this.id,
    required this.resi,
    required this.receiverName,
    required this.receiverAddress,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timeline,
  });

  final String id;
  final String resi;
  final String receiverName;
  final String receiverAddress;
  final String status;
  final double? latitude;
  final double? longitude;
  final List<CourierTrackingEvent> timeline;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory CourierBagPackage.fromJson(Map<String, dynamic> json) {
    return CourierBagPackage(
      id: (json['id'] ?? '').toString(),
      resi: (json['resi'] ?? '').toString(),
      receiverName: (json['receiver_name'] ?? '').toString(),
      receiverAddress: (json['receiver_address'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      latitude: _readNullableDouble(json['latitude']),
      longitude: _readNullableDouble(json['longitude']),
      timeline: _readList(json['timeline'])
          .whereType<Map<String, dynamic>>()
          .map(CourierTrackingEvent.fromJson)
          .toList(growable: false),
    );
  }
}

class CourierTrackingEvent {
  CourierTrackingEvent({
    required this.eventCode,
    required this.eventLabel,
    required this.location,
    required this.description,
    required this.createdAt,
  });

  final String eventCode;
  final String eventLabel;
  final String? location;
  final String? description;
  final DateTime createdAt;

  factory CourierTrackingEvent.fromJson(Map<String, dynamic> json) {
    return CourierTrackingEvent(
      eventCode: (json['event_code'] ?? '').toString(),
      eventLabel: (json['event_label'] ?? '').toString(),
      location: _readNullableString(json['location']),
      description: _readNullableString(json['description']),
      createdAt: DateTime.parse((json['created_at'] ?? '').toString()),
    );
  }
}

class CourierBagDetail {
  CourierBagDetail({required this.bag, required this.packages});

  final CourierBagSummary bag;
  final List<CourierBagPackage> packages;

  factory CourierBagDetail.fromJson(Map<String, dynamic> json) {
    return CourierBagDetail(
      bag: CourierBagSummary.fromJson(_readObject(json['bag'])),
      packages: _readList(json['packages'])
          .whereType<Map<String, dynamic>>()
          .map(CourierBagPackage.fromJson)
          .toList(growable: false),
    );
  }
}

class CourierBagTimelineResponse {
  CourierBagTimelineResponse({required this.bag, required this.packages});

  final CourierBagSummary bag;
  final List<CourierBagPackage> packages;

  factory CourierBagTimelineResponse.fromJson(Map<String, dynamic> json) {
    return CourierBagTimelineResponse(
      bag: CourierBagSummary.fromJson(_readObject(json['bag'])),
      packages: _readList(json['packages'])
          .whereType<Map<String, dynamic>>()
          .map(CourierBagPackage.fromJson)
          .toList(growable: false),
    );
  }
}

class CourierDeliveryRequest {
  CourierDeliveryRequest({
    this.status = 'DELIVERED',
    required this.podImageUrl,
    required this.courierLatitude,
    required this.courierLongitude,
    this.targetLatitude,
    this.targetLongitude,
    this.deliveredAt,
  });

  final String status;
  final String podImageUrl;
  final double courierLatitude;
  final double courierLongitude;
  final double? targetLatitude;
  final double? targetLongitude;
  final DateTime? deliveredAt;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'pod_image_url': podImageUrl,
      'courier_latitude': courierLatitude,
      'courier_longitude': courierLongitude,
      'target_latitude': targetLatitude,
      'target_longitude': targetLongitude,
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }
}

int _readInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readNullableDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}

String? _readNullableString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

Map<String, dynamic> _readObject(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}

List<dynamic> _readList(Object? value) {
  if (value is List<dynamic>) {
    return value;
  }
  return const <dynamic>[];
}
