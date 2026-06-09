import '../../../core/network/api_client.dart';
import '../domain/mobile_models.dart';

class MobileCourierApiClient {
  MobileCourierApiClient({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<MobileTaskBoardResponse> fetchTaskBoard() async {
    final response = await _apiClient.get('/mobile/tasks');
    return MobileTaskBoardResponse.fromJson(_extractObject(response.data));
  }

  Future<MobileTaskDetailResponse> fetchTaskDetail(String id) async {
    final response = await _apiClient.get('/mobile/tasks/$id');
    return MobileTaskDetailResponse.fromJson(_extractObject(response.data));
  }

  Future<void> deliverTask(String id, MobileDeliverRequest request) async {
    await _apiClient.put('/mobile/tasks/$id/deliver', data: request.toJson());
  }

  Future<MobileHistoryResponse> fetchHistory() async {
    final response = await _apiClient.get('/mobile/history');
    return MobileHistoryResponse.fromJson(_extractObject(response.data));
  }

  Future<MobileProfileResponse> fetchProfile() async {
    final response = await _apiClient.get('/mobile/profile');
    return MobileProfileResponse.fromJson(_extractObject(response.data));
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _apiClient.patch('/mobile/profile', data: data);
  }

  Future<void> acceptTask(String id) async {
    await _apiClient.patch('/mobile/tasks/$id/accept', data: {'status': 'IN_TRANSIT'});
  }

  Map<String, dynamic> _extractObject(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return payload;
    }
    return <String, dynamic>{};
  }
}
