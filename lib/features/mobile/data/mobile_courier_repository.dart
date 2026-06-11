import 'package:dio/dio.dart';

import 'mobile_courier_api_client.dart';
import '../domain/mobile_models.dart';

class MobileApiException implements Exception {
  MobileApiException({required this.statusCode, required this.message});

  final int? statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode == 500;

  @override
  String toString() => message;

  factory MobileApiException.fromDio(DioException error, {String? operation}) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final backendMessage = _extractBackendMessage(data);

    if (statusCode == 401) {
      return MobileApiException(
        statusCode: 401,
        message: backendMessage ?? 'Login session is invalid. Please log in again.',
      );
    }

    if (statusCode == 403) {
      final message = operation == 'deliver'
          ? 'Courier is outside the delivery radius.'
          : backendMessage ?? 'Access denied by server.';
      return MobileApiException(statusCode: 403, message: message);
    }

    if (statusCode == 404) {
      return MobileApiException(
        statusCode: 404,
        message: backendMessage ?? 'Data not found.',
      );
    }

    if (statusCode == 500) {
      return MobileApiException(
        statusCode: 500,
        message: backendMessage ?? 'Server error occurred.',
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return MobileApiException(statusCode: statusCode, message: 'Server connection timed out.');
    }

    return MobileApiException(
      statusCode: statusCode,
      message: backendMessage ?? 'Failed to connect to backend.',
    );
  }

  static String? _extractBackendMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      final text = message?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }
}

class MobileCourierRepository {
  MobileCourierRepository({required MobileCourierApiClient apiClient}) : _apiClient = apiClient;

  final MobileCourierApiClient _apiClient;

  Future<MobileTaskBoardResponse> fetchTaskBoard() {
    return _handle(() => _apiClient.fetchTaskBoard());
  }

  Future<MobileTaskDetailResponse> fetchTaskDetail(String id) {
    return _handle(() => _apiClient.fetchTaskDetail(id));
  }

  Future<void> deliverTask(String id, MobileDeliverRequest request) {
    return _handle(() => _apiClient.deliverTask(id, request), operation: 'deliver');
  }

  Future<MobileHistoryResponse> fetchHistory() {
    return _handle(() => _apiClient.fetchHistory());
  }

  Future<MobileProfileResponse> fetchProfile() {
    return _handle(() => _apiClient.fetchProfile());
  }

  Future<void> updateProfile(Map<String, dynamic> data) {
    return _handle(() => _apiClient.updateProfile(data));
  }

  Future<void> acceptTask(String id) {
    return _handle(() => _apiClient.acceptTask(id));
  }

  Future<T> _handle<T>(Future<T> Function() action, {String? operation}) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw MobileApiException.fromDio(error, operation: operation);
    }
  }
}