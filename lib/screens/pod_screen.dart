import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/mobile/domain/mobile_models.dart';
import '../providers/task_provider.dart';
import '../services/api_service.dart';
import '../services/delivery_service.dart';

class PodScreen extends StatefulWidget {
  const PodScreen({super.key, required this.taskId, this.task});

  final String taskId;
  final MobileTaskItem? task;

  @override
  State<PodScreen> createState() => _PodScreenState();
}

class _PodScreenState extends State<PodScreen> {
  File? _photo;
  Position? _position;
  String _addressLabel = 'Getting location...';
  bool _isUploading = false;
  String _submittingStatus = '';
  String? _error;

  // Geofence state
  _GeofenceStatus _geofenceStatus = _GeofenceStatus.checking;
  double? _distanceMeters;
  bool _isSuspiciousLocation = false;
  static const double _maxDistanceMeters = 100.0;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _geofenceStatus = _GeofenceStatus.checking;
      _addressLabel = 'Getting location...';
      _isSuspiciousLocation = false;
    });

    try {
      // Ensure permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _addressLabel = 'GPS service is off';
            _geofenceStatus = _GeofenceStatus.error;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _addressLabel = 'Location permission denied';
            _geofenceStatus = _GeofenceStatus.error;
          });
        }
        return;
      }

      // On Android, try to bypass Fused Location Provider cache by using the
      // raw LocationManager. FLP may return a stale or mock-injected position.
      // If the hardware GPS can't get a fix in time (common on first open / MIUI),
      // fall back to FLP — but flag accuracy == 0.0 as suspicious (mock indicator).
      Position pos;
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.best,
              timeLimit: const Duration(seconds: 15),
              forceLocationManager: true,
            ),
          );
        } catch (_) {
          // Hardware GPS timed out — fall back to FLP for a faster reading.
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              timeLimit: Duration(seconds: 20),
            ),
          );
        }
      } else {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 20),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _position = pos;
        // accuracy == 0.0 is a common fingerprint of mock location providers.
        _isSuspiciousLocation = pos.accuracy == 0.0;
      });

      // Reverse geocode
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final p = placemarks.first;
          final street = p.street ?? '';
          final city = p.locality ?? '';
          setState(() {
            _addressLabel = [
              street,
              city,
            ].where((s) => s.isNotEmpty).join(', ');
            if (_addressLabel.isEmpty) _addressLabel = 'Location found';
          });
        }
      } catch (_) {
        if (mounted) setState(() => _addressLabel = 'Location found');
      }

      // Geofence check
      _checkGeofence(pos);
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressLabel = 'Failed to get location';
          _geofenceStatus = _GeofenceStatus.error;
        });
      }
    }
  }

  void _checkGeofence(Position pos) {
    final task = widget.task ?? context.read<TaskProvider>().currentTask;

    if (task == null || !task.hasCoordinates) {
      // No target coords — allow proceed
      setState(() => _geofenceStatus = _GeofenceStatus.withinRange);
      return;
    }

    final dist = _haversine(
      pos.latitude,
      pos.longitude,
      task.latitude!,
      task.longitude!,
    );

    setState(() {
      _distanceMeters = dist;
      _geofenceStatus = dist <= _maxDistanceMeters
          ? _GeofenceStatus.withinRange
          : _GeofenceStatus.outsideRange;
    });
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dphi = (lat2 - lat1) * pi / 180;
    final dlambda = (lon2 - lon1) * pi / 180;
    final a =
        sin(dphi / 2) * sin(dphi / 2) +
        cos(phi1) * cos(phi2) * sin(dlambda / 2) * sin(dlambda / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _takePicture() async {
    if (_geofenceStatus == _GeofenceStatus.outsideRange) {
      _showOutOfRangeSnackbar();
      return;
    }
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (img != null && mounted) {
      setState(() => _photo = File(img.path));
    }
  }

  void _showOutOfRangeSnackbar() {
    final dist = _distanceMeters;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          dist != null
              ? 'You are ${dist.toStringAsFixed(0)}m from the destination. Must be ≤100m to take a photo.'
              : 'You are outside the delivery range.',
        ),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submit() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Take a photo first'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Re-check geofence before submit
    if (_geofenceStatus == _GeofenceStatus.outsideRange) {
      _showOutOfRangeSnackbar();
      return;
    }

    // Re-validate position at submit time
    if (_position != null) {
      final task = widget.task ?? context.read<TaskProvider>().currentTask;
      if (task != null && task.hasCoordinates) {
        final dist = _haversine(
          _position!.latitude,
          _position!.longitude,
          task.latitude!,
          task.longitude!,
        );
        if (dist > _maxDistanceMeters) {
          setState(() {
            _distanceMeters = dist;
            _geofenceStatus = _GeofenceStatus.outsideRange;
            _error =
                'You are ${dist.toStringAsFixed(0)}m from the destination. '
                'Move within $_maxDistanceMeters meters to complete delivery.';
          });
          return;
        }
      }
    }

    setState(() {
      _isUploading = true;
      _submittingStatus = 'Compressing photo...';
      _error = null;
    });

    try {
      // Capture context-dependent values before any await.
      final api = context.read<ApiService>();
      final task = widget.task ?? context.read<TaskProvider>().currentTask;

      // Compress before upload
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/pod_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        _photo!.path,
        targetPath,
        quality: 70,
      );
      final fileToUpload = compressed != null ? File(compressed.path) : _photo!;

      if (mounted) setState(() => _submittingStatus = 'Uploading photo...');

      // Step 1: upload photo → get proof URL
      final proofUrl = await api.uploadProofPhoto(
        taskId: widget.taskId,
        file: fileToUpload,
      );

      if (mounted) setState(() => _submittingStatus = 'Confirming delivery...');

      // Step 2: confirm delivery with GPS coordinates
      final pos = _position;
      await api.submitDelivery(
        widget.taskId,
        DeliveryPayload(
          podImageUrl: proofUrl,
          courierLatitude: pos?.latitude ?? 0.0,
          courierLongitude: pos?.longitude ?? 0.0,
          targetLatitude: task?.latitude ?? 0.0,
          targetLongitude: task?.longitude ?? 0.0,
          deliveredAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      await context.read<TaskProvider>().loadTasks();
      if (!mounted) return;
      context.go('/tasks');
    } on DeliveryException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _submittingStatus = '';
      });
      if (e.isOutsideRadius) {
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Out of Range'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _fetchLocation();
                },
                child: const Text('Refresh Location'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isUploading = false;
        _submittingStatus = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task ?? context.watch<TaskProvider>().currentTask;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(task),
              const SizedBox(height: 20),
              Text(
                'Proof of Delivery',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.nekoTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Capture a clear photo of the package at the drop-off location.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.nekoTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _buildGeofenceBanner(),
              const SizedBox(height: 12),
              _buildCameraWidget(),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 12),
              _buildArrivalCard(now),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildErrorCard(_error!),
              ],
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MobileTaskItem? task) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.nekoInputFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'ACTIVE ROUTE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.activeOrange,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '#${task?.bagCode ?? task?.title ?? widget.taskId}',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: context.nekoTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGeofenceBanner() {
    switch (_geofenceStatus) {
      case _GeofenceStatus.checking:
        return _infoBanner(
          color: AppColors.inTransitBg,
          borderColor: AppColors.inTransitText,
          icon: Icons.gps_fixed,
          iconColor: AppColors.inTransitText,
          text: 'Checking your location...',
          showSpin: true,
        );
      case _GeofenceStatus.withinRange:
        return _infoBanner(
          color: AppColors.deliveredBg,
          borderColor: AppColors.deliveredText,
          icon: Icons.check_circle_outline,
          iconColor: AppColors.deliveredText,
          text: _distanceMeters != null
              ? 'Within range (${_distanceMeters!.toStringAsFixed(0)}m from destination)'
              : 'Location verified — within delivery range',
        );
      case _GeofenceStatus.outsideRange:
        final dist = _distanceMeters;
        return _infoBanner(
          color: const Color(0xFFFEF2F2),
          borderColor: AppColors.errorRed,
          icon: Icons.location_off_outlined,
          iconColor: AppColors.errorRed,
          text: dist != null
              ? 'Out of range: ${dist.toStringAsFixed(0)}m from destination (max. ${_maxDistanceMeters.toStringAsFixed(0)}m). Please move closer to the delivery location.'
              : 'Outside delivery range.',
          action: TextButton(
            onPressed: _fetchLocation,
            child: Text(
              'Refresh Location',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.errorRed,
              ),
            ),
          ),
        );
      case _GeofenceStatus.error:
        return _infoBanner(
          color: const Color(0xFFFEF2F2),
          borderColor: AppColors.errorRed,
          icon: Icons.gps_off_outlined,
          iconColor: AppColors.errorRed,
          text: _isSuspiciousLocation
              ? 'GPS signal is unreliable. Turn off any mock location app and try again.'
              : 'Failed to get GPS location. Make sure GPS is enabled and location permission is granted.',
          action: TextButton(
            onPressed: _fetchLocation,
            child: Text(
              'Try Again',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.errorRed,
              ),
            ),
          ),
        );
    }
  }

  Widget _infoBanner({
    required Color color,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required String text,
    Widget? action,
    bool showSpin = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          showSpin
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: iconColor,
                    strokeWidth: 2,
                  ),
                )
              : Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: borderColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ?action,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraWidget() {
    final isBlocked =
        _geofenceStatus == _GeofenceStatus.outsideRange ||
        _geofenceStatus == _GeofenceStatus.error;

    return GestureDetector(
      onTap: _isUploading ? null : _takePicture,
      child: Stack(
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Stack(
              children: [
                if (_photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Image.file(
                      _photo!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBlocked ? Icons.block : Icons.camera_alt_outlined,
                          color: isBlocked
                              ? AppColors.errorRed.withValues(alpha: 0.7)
                              : Colors.white54,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isBlocked
                              ? 'Out of range'
                              : 'Tap to take a photo',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isBlocked
                                ? AppColors.errorRed.withValues(alpha: 0.7)
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_photo == null && !isBlocked) ...[
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 6,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE PREVIEW',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: Icon(Icons.bolt, color: Colors.white70, size: 22),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: context.nekoTextPrimary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_photo != null)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: isBlocked ? _showOutOfRangeSnackbar : _takePicture,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Retake',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Geofence lock overlay
          if (isBlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: AppColors.errorRed,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Out of range',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.nekoCardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOCATION TAG',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.nekoTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _addressLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.nekoTextPrimary,
                      ),
                    ),
                    if (_position != null)
                      Text(
                        'GPS Precision: ${_position!.accuracy.toStringAsFixed(1)}m',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.nekoTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _fetchLocation,
                child: Icon(
                  Icons.refresh,
                  size: 18,
                  color: context.nekoTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalCard(DateTime now) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.nekoCardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARRIVAL TIME',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.nekoTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.nekoTextPrimary,
            ),
          ),
          Text(
            _formatDate(now),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.nekoTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isBlocked =
        _geofenceStatus == _GeofenceStatus.outsideRange ||
        _geofenceStatus == _GeofenceStatus.error;
    final disabled = _isUploading || isBlocked || _photo == null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: disabled
            ? (isBlocked ? _showOutOfRangeSnackbar : null)
            : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: isBlocked
              ? context.nekoTextSecondary
              : AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
        ),
        child: _isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _submittingStatus,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isBlocked
                        ? 'Out of Range'
                        : 'Upload & Complete Delivery',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isBlocked ? Icons.lock_outline : Icons.check_circle_outline,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }
}

enum _GeofenceStatus { checking, withinRange, outsideRange, error }
