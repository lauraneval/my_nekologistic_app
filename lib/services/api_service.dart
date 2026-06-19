import 'dart:io';

import '../features/mobile/data/mobile_courier_repository.dart';
import '../features/mobile/domain/mobile_models.dart';
import 'delivery_service.dart';

class ApiService {
  ApiService({
    required MobileCourierRepository repository,
    required DeliveryService deliveryService,
  })  : _repository = repository,
        _delivery = deliveryService;

  final MobileCourierRepository _repository;
  final DeliveryService _delivery;

  Future<MobileTaskBoardResponse> getTasks() => _repository.fetchTaskBoard();

  Future<MobileTaskItem> getTaskDetail(String id) async {
    final response = await _repository.fetchTaskDetail(id);
    return response.task;
  }

  Future<void> submitDelivery(String id, DeliveryPayload payload) =>
      _delivery.confirmDelivery(
        bagId: id,
        packageId: payload.packageId,
        podImageUrl: payload.podImageUrl,
        latitude: payload.courierLatitude,
        longitude: payload.courierLongitude,
        deliveredAt: payload.deliveredAt,
      );

  Future<MobileHistoryResponse> getHistory() => _repository.fetchHistory();

  Future<MobileProfileResponse> getProfile() => _repository.fetchProfile();

  Future<void> updateProfile({String? name, String? phone, String? email}) {
    final data = <String, dynamic>{
      'name': name,
      'phone': phone,
      'email': email,
    }..removeWhere((_, v) => v == null);
    return _repository.updateProfile(data);
  }

  Future<void> acceptTask(String id) => _repository.acceptTask(id);

  Future<String> uploadProofPhoto({required String taskId, required File file}) =>
      _delivery.uploadPodPhoto(taskId, file);
}

class DeliveryPayload {
  DeliveryPayload({
    required this.podImageUrl,
    required this.courierLatitude,
    required this.courierLongitude,
    required this.targetLatitude,
    required this.targetLongitude,
    required this.deliveredAt,
    this.packageId,
  });

  final String podImageUrl;
  final double courierLatitude;
  final double courierLongitude;
  final double targetLatitude;
  final double targetLongitude;
  final DateTime deliveredAt;
  /// ID of the individual package inside a multi-package bag. When set, the
  /// server should mark only this package as delivered instead of the whole bag.
  final String? packageId;

  Map<String, dynamic> toJson() => {
        'proof_url': podImageUrl,
        'latitude': courierLatitude,
        'longitude': courierLongitude,
        'delivered_at': deliveredAt.toUtc().toIso8601String(),
      };
}
