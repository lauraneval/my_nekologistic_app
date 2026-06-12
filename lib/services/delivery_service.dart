import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../core/network/api_client.dart';
import '../models/delivery_result.dart';

class DeliveryException implements Exception {
  const DeliveryException(this.message, {this.isOutsideRadius = false});

  final String message;
  final bool isOutsideRadius;

  @override
  String toString() => message;
}

/// Handles the two-step POD flow via the backend REST API.
///
/// Step 1 — POST /api/mobile/tasks/{bagId}/deliver (multipart, returns pod_image_url)
/// Step 2 — PUT  /api/mobile/tasks/{bagId}/deliver (JSON confirm, returns DeliveryResult)
class DeliveryService {
  DeliveryService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Step 1: upload the POD photo and return the public image URL.
  /// Throws [DeliveryException] if the file exceeds 2 MB or the request fails.
  Future<String> uploadPodPhoto(String bagId, File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      throw const DeliveryException(
        'Photo size exceeds 2 MB. Try retaking with lower quality.',
      );
    }

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'pod_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _api.post(
        '/mobile/tasks/$bagId/deliver',
        data: formData,
      );

      final data = _extractData(response.data);
      final url = data['pod_image_url']?.toString();
      if (url == null || url.isEmpty) {
        throw const DeliveryException(
          'Upload succeeded but photo URL was not received from server.',
        );
      }
      return url;
    } on DeliveryException {
      rethrow;
    } on DioException catch (e) {
      throw DeliveryException(_mapUploadError(e));
    } catch (e) {
      throw DeliveryException('Photo upload failed: $e');
    }
  }

  /// Step 2: confirm the delivery with photo URL + GPS coordinates.
  /// Throws [DeliveryException] with [isOutsideRadius] = true when server
  /// returns 403 "Outside delivery radius / Unauthorized Zone".
  Future<DeliveryResult> confirmDelivery({
    required String bagId,
    required String podImageUrl,
    required double latitude,
    required double longitude,
    DateTime? deliveredAt,
  }) async {
    try {
      final response = await _api.put(
        '/mobile/tasks/$bagId/deliver',
        data: {
          'proof_url': podImageUrl,
          'latitude': latitude,
          'longitude': longitude,
          if (deliveredAt != null)
            'delivered_at': deliveredAt.toUtc().toIso8601String(),
        },
      );
      return DeliveryResult.fromJson(_extractData(response.data));
    } on DeliveryException {
      rethrow;
    } on DioException catch (e) {
      final outside = _isOutsideRadius(e);
      throw DeliveryException(
        outside
            ? 'You are outside the delivery radius. '
                'Please move closer to the destination before confirming delivery.'
            : _mapConfirmError(e),
        isOutsideRadius: outside,
      );
    } catch (e) {
      throw DeliveryException('Delivery confirmation failed: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) return data;
      return responseData;
    }
    return {};
  }

  bool _isOutsideRadius(DioException e) {
    if (e.response?.statusCode != 403) return false;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = (data['message'] ?? data['error'] ?? '').toString().toLowerCase();
      return msg.contains('radius') || msg.contains('zone');
    }
    return false;
  }

  String _mapUploadError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Check your internet connection.';
    }
    final code = e.response?.statusCode;
    final data = e.response?.data;
    final msg = data is Map<String, dynamic>
        ? (data['message'] ?? data['error'] ?? '').toString()
        : '';

    switch (code) {
      case 400:
        if (msg.contains('2 MB')) return 'Photo size exceeds 2 MB.';
        if (msg.contains('image')) return 'File must be an image.';
        if (msg.contains('required')) return 'Photo file not found.';
        return msg.isNotEmpty ? msg : 'Invalid request (400).';
      case 403:
        return 'Access denied — make sure you are the assigned courier.';
      case 404:
        return 'Delivery task not found.';
      case 500:
        return 'Server failed to process photo. Please try again.';
      default:
        return 'Photo upload failed (${code ?? 'no response'}).';
    }
  }

  String _mapConfirmError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Check your internet connection.';
    }
    final code = e.response?.statusCode;
    final data = e.response?.data;
    final msg = data is Map<String, dynamic>
        ? (data['message'] ?? data['error'] ?? '').toString()
        : '';

    switch (code) {
      case 400:
        return msg.isNotEmpty ? msg : 'Invalid delivery data.';
      case 403:
        return 'Access denied (403).';
      case 404:
        return 'Delivery task not found.';
      default:
        return 'Delivery confirmation failed (${code ?? 'no response'}).';
    }
  }
}
