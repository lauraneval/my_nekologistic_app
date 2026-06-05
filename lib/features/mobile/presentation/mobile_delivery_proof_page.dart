import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../data/mobile_courier_repository.dart';
import '../data/proof_upload_service.dart';
import '../domain/mobile_models.dart';

class MobileDeliveryProofPage extends StatefulWidget {
  const MobileDeliveryProofPage({
    super.key,
    required this.task,
    required this.repository,
    required this.apiClient,
  });

  final MobileTaskItem task;
  final MobileCourierRepository repository;
  final ApiClient apiClient;

  @override
  State<MobileDeliveryProofPage> createState() =>
      _MobileDeliveryProofPageState();
}

class _MobileDeliveryProofPageState extends State<MobileDeliveryProofPage> {
  late final ProofUploadService _proofUploadService;
  File? _selectedImage;
  bool _isSubmitting = false;
  String _errorMessage = '';
  String _statusMessage = 'Pilih foto bukti terlebih dahulu.';

  @override
  void initState() {
    super.initState();
    _proofUploadService = ProofUploadService();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _proofUploadService.pickPhoto(source: source);
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImage = file;
      _errorMessage = '';
      _statusMessage = file == null
          ? 'Tidak ada foto yang dipilih.'
          : 'Foto siap diupload.';
    });
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const MobileLocationDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const MobileLocationPermissionException(
        'Izin lokasi dibutuhkan untuk submit delivery.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _submit() async {
    if (_selectedImage == null) {
      setState(() => _errorMessage = 'Foto proof wajib dipilih.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
      _statusMessage = 'Mengambil lokasi GPS...';
    });

    try {
      final position = await _getCurrentPosition();
      setState(() {
        _statusMessage = 'Mengupload proof ke Supabase Storage...';
      });

      final proofUrl = await _proofUploadService.uploadProofPhoto(
        taskId: widget.task.id,
        file: _selectedImage!,
      );

      setState(() {
        _statusMessage = 'Mengirim delivery ke backend...';
      });

      await widget.repository.deliverTask(
        widget.task.id,
        MobileDeliverRequest(
          latitude: position.latitude,
          longitude: position.longitude,
          proofUrl: proofUrl,
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery berhasil dikirim.')),
      );
      Navigator.of(context).pop(true);
    } on MobileApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } on MobileLocationDisabledException {
      setState(() {
        _errorMessage = 'GPS nonaktif. Aktifkan lokasi terlebih dahulu.';
      });
    } on MobileLocationPermissionException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memproses delivery.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proof of Delivery'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.task.proofUrl != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Proof sudah diupload',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Belum ada bukti pengiriman',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Ambil foto dari kamera atau galeri sebagai bukti pengiriman',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Kamera'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Galeri'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedImage != null)
            Card(
              elevation: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 280,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            const _EmptyPreview(),
          const SizedBox(height: 16),
          if (_errorMessage.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage)),
                  ],
                ),
              ),
            ),
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isSubmitting ? 'Mengirim...' : 'Upload & Complete Delivery',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              minimumSize: const Size.fromHeight(50),
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jika backend mengembalikan 403, aplikasi akan menampilkan pesan delivery radius dari server. Flutter tidak menghitung geofence.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Container(
        height: 280,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Belum ada foto proof',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih foto dari kamera atau galeri',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileLocationDisabledException implements Exception {
  const MobileLocationDisabledException();
}

class MobileLocationPermissionException implements Exception {
  const MobileLocationPermissionException(this.message);

  final String message;
}
