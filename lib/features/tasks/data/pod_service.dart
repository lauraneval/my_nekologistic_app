import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bootstrap/app_bootstrap.dart';
import '../../../core/config/app_env.dart';
import '../../../core/network/api_client.dart';
import 'activity_log_queue_service.dart';
import '../domain/courier_task.dart';

class PodFailure implements Exception {
  PodFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

enum PodProgressStep {
  openingCamera,
  compressingPhoto,
  lockingLocation,
  validatingDistance,
  uploadingPhoto,
  updatingStatus,
  completed,
}

typedef PodProgressCallback =
    void Function(PodProgressStep step, {int attempt, int maxAttempt});

class PodSubmissionResult {
  PodSubmissionResult({
    required this.photoUrl,
    required this.courierLatitude,
    required this.courierLongitude,
  });

  final String photoUrl;
  final double courierLatitude;
  final double courierLongitude;
}

class PodService {
  PodService({
    required ApiClient apiClient,
    ImagePicker? imagePicker,
    ActivityLogQueueService? activityLogQueueService,
  }) : _apiClient = apiClient,
       _imagePicker = imagePicker ?? ImagePicker(),
       _activityLogQueueService =
           activityLogQueueService ?? ActivityLogQueueService();

  final ApiClient _apiClient;
  final ImagePicker _imagePicker;
  final ActivityLogQueueService _activityLogQueueService;

  Future<File> captureCompressedPhoto({PodProgressCallback? onProgress}) async {
    onProgress?.call(PodProgressStep.openingCamera);
    final rawPhoto = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 100,
    );

    if (rawPhoto == null) {
      throw PodFailure('Foto POD dibatalkan oleh pengguna.');
    }

    onProgress?.call(PodProgressStep.compressingPhoto);
    return _compressPhoto(rawPhoto);
  }

  Future<PodSubmissionResult> submitProofOfDelivery({
    required CourierTask task,
    required File preparedImageFile,
    PodProgressCallback? onProgress,
  }) async {
    if (!AppBootstrap.isSupabaseInitialized) {
      throw PodFailure('Supabase belum dikonfigurasi.');
    }

    try {
      await _flushPendingActivityLogs();
      await _tryLogActivity(action: 'pod_submission_started', task: task);

      onProgress?.call(PodProgressStep.lockingLocation);
      final position = await _lockCourierPosition();
      await _tryLogActivity(
        action: 'pod_location_locked',
        task: task,
        metadata: {
          'courier_latitude': position.latitude,
          'courier_longitude': position.longitude,
        },
      );

      onProgress?.call(PodProgressStep.validatingDistance);
      _validateDistance(position: position, task: task);
      await _tryLogActivity(action: 'pod_distance_validated', task: task);

      final publicUrl = await _withRetry(
        step: PodProgressStep.uploadingPhoto,
        onProgress: onProgress,
        operation: () => _uploadPhoto(task: task, imageFile: preparedImageFile),
      );
      await _tryLogActivity(
        action: 'pod_photo_uploaded',
        task: task,
        metadata: {'pod_image_url': publicUrl},
      );

      await _withRetry(
        step: PodProgressStep.updatingStatus,
        onProgress: onProgress,
        operation: () => _apiClient.put(
          '/courier/tasks/${task.id}/deliver',
          data: {
            'status': 'DELIVERED',
            'pod_image_url': publicUrl,
            'courier_latitude': position.latitude,
            'courier_longitude': position.longitude,
            'target_latitude': task.latitude,
            'target_longitude': task.longitude,
            'delivered_at': DateTime.now().toUtc().toIso8601String(),
          },
        ),
      );
      await _tryLogActivity(
        action: 'pod_status_delivered',
        task: task,
        metadata: {
          'status': 'DELIVERED',
          'courier_latitude': position.latitude,
          'courier_longitude': position.longitude,
        },
      );

      onProgress?.call(PodProgressStep.completed);

      return PodSubmissionResult(
        photoUrl: publicUrl,
        courierLatitude: position.latitude,
        courierLongitude: position.longitude,
      );
    } on PodFailure {
      await _tryLogActivity(
        action: 'pod_submission_failed',
        task: task,
        metadata: {'reason': 'business_validation_failed'},
      );
      rethrow;
    } catch (error) {
      await _tryLogActivity(
        action: 'pod_submission_failed',
        task: task,
        metadata: {
          'reason': _mapErrorMessage(error),
          'error_type': error.runtimeType.toString(),
        },
      );
      throw PodFailure(_mapErrorMessage(error));
    }
  }

  Future<Position> _lockCourierPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw PodFailure('GPS tidak aktif. Aktifkan lokasi terlebih dahulu.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw PodFailure('Izin lokasi dibutuhkan untuk validasi pengiriman.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<File> _compressPhoto(XFile source) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/pod_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      source.path,
      targetPath,
      format: CompressFormat.jpeg,
      quality: 75,
      minWidth: 1280,
      minHeight: 1280,
    );

    if (compressed == null) {
      return File(source.path);
    }

    return File(compressed.path);
  }

  Future<String> _uploadPhoto({
    required CourierTask task,
    required File imageFile,
  }) async {
    final storage = Supabase.instance.client.storage.from(AppEnv.podBucket);
    final fileName = 'pod_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'courier/${task.id}/$fileName';

    await storage.upload(
      path,
      imageFile,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );

    return storage.getPublicUrl(path);
  }

  void _validateDistance({
    required Position position,
    required CourierTask task,
  }) {
    if (!task.hasCoordinates) {
      return;
    }

    final distanceMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      task.latitude!,
      task.longitude!,
    );

    if (distanceMeters > AppEnv.maxDeliveryDistanceMeters) {
      throw PodFailure(
        'Posisi kamu terlalu jauh dari titik tujuan '
        '(${distanceMeters.toStringAsFixed(0)} m). '
        'Batas maksimal ${AppEnv.maxDeliveryDistanceMeters} m.',
      );
    }
  }

  Future<T> _withRetry<T>({
    required PodProgressStep step,
    required Future<T> Function() operation,
    PodProgressCallback? onProgress,
  }) async {
    const maxAttempt = 3;

    for (var attempt = 1; attempt <= maxAttempt; attempt++) {
      try {
        onProgress?.call(step, attempt: attempt, maxAttempt: maxAttempt);
        return await operation();
      } catch (error) {
        if (attempt == maxAttempt) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }

    throw PodFailure('Operasi gagal setelah beberapa percobaan.');
  }

  String _mapErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Koneksi ke server timeout. Coba lagi.';
      }
      if (statusCode == 401 || statusCode == 403) {
        return 'Sesi login tidak valid. Silakan login ulang.';
      }
      if (statusCode != null) {
        return 'Server mengembalikan error ($statusCode).';
      }
      return 'Gagal terhubung ke backend pengiriman.';
    }

    if (error is SocketException) {
      return 'Tidak ada koneksi internet.';
    }

    final message = error.toString();
    if (message.contains('StorageException')) {
      return 'Upload foto ke Supabase Storage gagal.';
    }

    return 'Terjadi kesalahan saat memproses POD.';
  }

  Future<void> _tryLogActivity({
    required String action,
    required CourierTask task,
    Map<String, dynamic>? metadata,
  }) async {
    if (!AppEnv.enableActivityLogs) {
      return;
    }

    final payload = _buildActivityPayload(
      action: action,
      task: task,
      metadata: metadata,
    );

    try {
      await _sendActivityLog(payload);
    } catch (_) {
      try {
        await _activityLogQueueService.enqueue(
          payload,
          maxItems: AppEnv.activityLogQueueMaxItems,
          maxRetry: AppEnv.activityLogQueueMaxRetry,
        );
      } catch (_) {
        // Intentionally ignored to keep POD flow non-blocking.
      }
    }
  }

  Map<String, dynamic> _buildActivityPayload({
    required String action,
    required CourierTask task,
    Map<String, dynamic>? metadata,
  }) {
    final actorId = Supabase.instance.client.auth.currentUser?.id;
    return {
      'actor_id': actorId,
      'action': action,
      'entity': 'package',
      'entity_id': task.id,
      'metadata': {'resi': task.resi, 'status': task.status, ...?metadata},
    };
  }

  Future<void> _sendActivityLog(Map<String, dynamic> payload) async {
    await _apiClient.post(AppEnv.activityLogPath, data: payload);
  }

  Future<void> _flushPendingActivityLogs() async {
    if (!AppEnv.enableActivityLogs) {
      return;
    }

    try {
      await _activityLogQueueService.flush(
        sender: _sendActivityLog,
        maxRetry: AppEnv.activityLogQueueMaxRetry,
      );
    } catch (_) {
      // Intentionally ignored to keep POD flow non-blocking.
    }
  }
}
