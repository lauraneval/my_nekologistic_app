import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../features/mobile/data/mobile_courier_repository.dart';
import '../features/mobile/data/proof_upload_service.dart';
import '../features/mobile/domain/mobile_models.dart';

class ApiService {
  ApiService({
    required MobileCourierRepository repository,
    required ProofUploadService proofUploadService,
  })  : _repository = repository,
        _proofUpload = proofUploadService;

  final MobileCourierRepository _repository;
  final ProofUploadService _proofUpload;

  Future<MobileTaskBoardResponse> getTasks() => _repository.fetchTaskBoard();

  Future<MobileTaskItem> getTaskDetail(String id) async {
    final response = await _repository.fetchTaskDetail(id);
    return response.task;
  }

  Future<void> submitDelivery(String id, DeliveryPayload payload) async {
    await _repository.deliverTask(
      id,
      MobileDeliverRequest(
        latitude: payload.courierLatitude,
        longitude: payload.courierLongitude,
        proofUrl: payload.podImageUrl,
      ),
    );
  }

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

  Future<File?> pickProofPhoto() =>
      _proofUpload.pickPhoto(source: ImageSource.camera);

  Future<String> uploadProofPhoto({required String taskId, required File file}) =>
      _proofUpload.uploadProofPhoto(taskId: taskId, file: file);
}

class DeliveryPayload {
  DeliveryPayload({
    required this.podImageUrl,
    required this.courierLatitude,
    required this.courierLongitude,
    required this.targetLatitude,
    required this.targetLongitude,
    required this.deliveredAt,
  });

  final String podImageUrl;
  final double courierLatitude;
  final double courierLongitude;
  final double targetLatitude;
  final double targetLongitude;
  final DateTime deliveredAt;

  Map<String, dynamic> toJson() => {
        'status': 'DELIVERED',
        'pod_image_url': podImageUrl,
        'courier_latitude': courierLatitude,
        'courier_longitude': courierLongitude,
        'target_latitude': targetLatitude,
        'target_longitude': targetLongitude,
        'delivered_at': deliveredAt.toIso8601String(),
      };
}
