import '../../../core/network/api_client.dart';
import '../domain/courier_bag_models.dart';

class CourierBagApiClient {
  CourierBagApiClient({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<CourierBagTask>> fetchBagTasks() async {
    final response = await _apiClient.get(
      '/courier/tasks',
      queryParameters: {'status': 'OUT_FOR_DELIVERY'},
    );

    final rawItems = _extractList(response.data);
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(CourierBagTask.fromJson)
        .toList(growable: false);
  }

  Future<CourierBagDetail> fetchBagDetail(String bagId) async {
    final response = await _apiClient.get('/courier/tasks/$bagId');
    return CourierBagDetail.fromJson(_extractObject(response.data));
  }

  Future<CourierBagTimelineResponse> fetchBagTimeline(String bagId) async {
    final response = await _apiClient.get('/courier/tasks/$bagId/timeline');
    return CourierBagTimelineResponse.fromJson(_extractObject(response.data));
  }

  Future<void> deliverPackage({
    required String packageId,
    required CourierDeliveryRequest request,
  }) async {
    await _apiClient.put(
      '/courier/tasks/$packageId/deliver',
      data: request.toJson(),
    );
  }

  List<dynamic> _extractList(Object? payload) {
    if (payload is List<dynamic>) {
      return payload;
    }
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      final items = payload['items'];
      if (data is List<dynamic>) {
        return data;
      }
      if (items is List<dynamic>) {
        return items;
      }
    }
    return const <dynamic>[];
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
