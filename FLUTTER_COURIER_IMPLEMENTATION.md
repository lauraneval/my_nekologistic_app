# Flutter Courier Implementation Guide

This guide turns the courier API contract into a simple Flutter implementation flow.

## Dependencies

Add these packages in the Flutter app:

```yaml
dependencies:
  http: ^1.2.2
```

## 1. API Client

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class CourierApiClient {
  CourierApiClient({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<List<CourierBagTask>> fetchBagTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/courier/tasks?status=OUT_FOR_DELIVERY'),
      headers: _headers,
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (json['data'] as List<dynamic>? ?? [])
        .map((item) => CourierBagTask.fromJson(item as Map<String, dynamic>))
        .toList();
    return data;
  }

  Future<CourierBagDetail> fetchBagDetail(String bagId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/courier/tasks/$bagId'),
      headers: _headers,
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CourierBagDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<CourierBagTimelineResponse> fetchBagTimeline(String bagId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/courier/tasks/$bagId/timeline'),
      headers: _headers,
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CourierBagTimelineResponse.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deliverPackage(String packageId, CourierDeliveryRequest request) async {
    await http.put(
      Uri.parse('$baseUrl/api/courier/tasks/$packageId/deliver'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );
  }
}
```

## 2. Models

```dart
class CourierBagTask {
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

  factory CourierBagTask.fromJson(Map<String, dynamic> json) => CourierBagTask(
        id: json['id'] as String,
        bagCode: json['bag_code'] as String,
        destinationCity: json['destination_city'] as String,
        packageCount: (json['package_count'] as num).toInt(),
        status: json['status'] as String,
        assignedCourierId: json['assigned_courier_id'] as String?,
        receiverName: json['receiver_name'] as String?,
        receiverAddress: json['receiver_address'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        packages: (json['packages'] as List<dynamic>? ?? [])
            .map((item) => CourierBagPackage.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
```

```dart
class CourierBagPackage {
  final String id;
  final String resi;
  final String receiverName;
  final String receiverAddress;
  final String status;
  final double? latitude;
  final double? longitude;

  CourierBagPackage({
    required this.id,
    required this.resi,
    required this.receiverName,
    required this.receiverAddress,
    required this.status,
    required this.latitude,
    required this.longitude,
  });

  factory CourierBagPackage.fromJson(Map<String, dynamic> json) => CourierBagPackage(
        id: json['id'] as String,
        resi: json['resi'] as String,
        receiverName: json['receiver_name'] as String,
        receiverAddress: json['receiver_address'] as String,
        status: json['status'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
```

```dart
class CourierTrackingEvent {
  final String eventCode;
  final String eventLabel;
  final String? location;
  final String? description;
  final DateTime createdAt;

  CourierTrackingEvent({
    required this.eventCode,
    required this.eventLabel,
    required this.location,
    required this.description,
    required this.createdAt,
  });

  factory CourierTrackingEvent.fromJson(Map<String, dynamic> json) => CourierTrackingEvent(
        eventCode: json['event_code'] as String,
        eventLabel: json['event_label'] as String,
        location: json['location'] as String?,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
```

```dart
class CourierBagDetail {
  final CourierBagSummary bag;
  final List<CourierBagPackage> packages;

  CourierBagDetail({required this.bag, required this.packages});

  factory CourierBagDetail.fromJson(Map<String, dynamic> json) => CourierBagDetail(
        bag: CourierBagSummary.fromJson(json['bag'] as Map<String, dynamic>),
        packages: (json['packages'] as List<dynamic>? ?? [])
            .map((item) => CourierBagPackage.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
```

```dart
class CourierBagSummary {
  final String id;
  final String bagCode;
  final String destinationCity;
  final String status;
  final String? assignedCourierId;

  CourierBagSummary({
    required this.id,
    required this.bagCode,
    required this.destinationCity,
    required this.status,
    required this.assignedCourierId,
  });

  factory CourierBagSummary.fromJson(Map<String, dynamic> json) => CourierBagSummary(
        id: json['id'] as String,
        bagCode: json['bag_code'] as String,
        destinationCity: json['destination_city'] as String,
        status: json['status'] as String,
        assignedCourierId: json['assigned_courier_id'] as String?,
      );
}
```

```dart
class CourierBagTimelineResponse {
  final CourierBagSummary bag;
  final List<CourierPackageTimeline> packages;

  CourierBagTimelineResponse({required this.bag, required this.packages});

  factory CourierBagTimelineResponse.fromJson(Map<String, dynamic> json) => CourierBagTimelineResponse(
        bag: CourierBagSummary.fromJson(json['bag'] as Map<String, dynamic>),
        packages: (json['packages'] as List<dynamic>? ?? [])
            .map((item) => CourierPackageTimeline.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
```

```dart
class CourierPackageTimeline {
  final String id;
  final String resi;
  final String receiverName;
  final String receiverAddress;
  final String status;
  final double? latitude;
  final double? longitude;
  final List<CourierTrackingEvent> timeline;

  CourierPackageTimeline({
    required this.id,
    required this.resi,
    required this.receiverName,
    required this.receiverAddress,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timeline,
  });

  factory CourierPackageTimeline.fromJson(Map<String, dynamic> json) => CourierPackageTimeline(
        id: json['id'] as String,
        resi: json['resi'] as String,
        receiverName: json['receiver_name'] as String,
        receiverAddress: json['receiver_address'] as String,
        status: json['status'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        timeline: (json['timeline'] as List<dynamic>? ?? [])
            .map((item) => CourierTrackingEvent.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}
```

```dart
class CourierDeliveryRequest {
  final String status;
  final String podImageUrl;
  final double courierLatitude;
  final double courierLongitude;
  final double? targetLatitude;
  final double? targetLongitude;
  final DateTime? deliveredAt;

  CourierDeliveryRequest({
    this.status = 'DELIVERED',
    required this.podImageUrl,
    required this.courierLatitude,
    required this.courierLongitude,
    this.targetLatitude,
    this.targetLongitude,
    this.deliveredAt,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        'pod_image_url': podImageUrl,
        'courier_latitude': courierLatitude,
        'courier_longitude': courierLongitude,
        'target_latitude': targetLatitude,
        'target_longitude': targetLongitude,
        'delivered_at': deliveredAt?.toIso8601String(),
      };
}
```

## 3. Suggested Screen Flow

1. Bag Task List Screen
   - Call `fetchBagTasks()`.
   - Render one card per bag.
   - Show destination city, package count, and status.

2. Bag Detail Screen
   - Call `fetchBagDetail(bagId)`.
   - Show bag metadata and package rows.
   - Let the courier tap a package to open the timeline view.

3. Timeline Screen
   - Call `fetchBagTimeline(bagId)`.
   - Render each package with its tracking timeline.
   - Highlight the most recent event.

4. Delivery Action
   - When the courier confirms delivery, call `deliverPackage(packageId, request)`.
   - Refresh bag detail and task list after success.

## 4. Notes

- Keep the bag-level UI as the source of truth.
- Do not treat each package as an independent courier task when the bag is assigned.
- Refresh the bag after any delivery, because the backend may close the bag automatically once all packages are delivered.