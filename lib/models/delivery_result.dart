class DeliveryResult {
  const DeliveryResult({
    required this.id,
    required this.bagCode,
    required this.status,
    required this.deliveredAt,
    required this.distanceMeters,
    required this.proofUrl,
  });

  final String id;
  final String bagCode;
  final String status;
  final String deliveredAt;
  final int distanceMeters;
  final String proofUrl;

  factory DeliveryResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return DeliveryResult(
      id: data['id']?.toString() ?? '',
      bagCode: data['bag_code']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      deliveredAt: data['delivered_at']?.toString() ?? '',
      distanceMeters: (data['distance_meters'] as num?)?.toInt() ?? 0,
      proofUrl: data['proof_url']?.toString() ?? '',
    );
  }
}
