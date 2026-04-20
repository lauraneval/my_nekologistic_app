class CourierTask {
  CourierTask({
    required this.id,
    required this.resi,
    required this.recipientName,
    required this.address,
    required this.status,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String resi;
  final String recipientName;
  final String address;
  final double? latitude;
  final double? longitude;
  final String status;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory CourierTask.fromJson(Map<String, dynamic> json) {
    final rawLat = json['latitude'] ?? json['destination_latitude'];
    final rawLng = json['longitude'] ?? json['destination_longitude'];

    return CourierTask(
      id: (json['id'] ?? '').toString(),
      resi: (json['resi'] ?? '').toString(),
      recipientName: (json['receiver_name'] ?? json['recipient_name'] ?? '-')
          .toString(),
      address: (json['receiver_address'] ?? json['address'] ?? '-').toString(),
      latitude: rawLat is num ? rawLat.toDouble() : null,
      longitude: rawLng is num ? rawLng.toDouble() : null,
      status: (json['status'] ?? '').toString(),
    );
  }
}
