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
  State<MobileDeliveryProofPage> createState() => _MobileDeliveryProofPageState();
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
      _statusMessage = file == null ? 'Tidak ada foto yang dipilih.' : 'Foto siap diupload.';
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

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const MobileLocationPermissionException('Izin lokasi dibutuhkan untuk submit delivery.');
    }

    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
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
      appBar: AppBar(title: const Text('Proof of Delivery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.task.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Proof URL currently: ${widget.task.proofUrl ?? '-'}'),
                  const SizedBox(height: 8),
                  Text('GPS saat submit dikirim sebagai latitude dan longitude.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isSubmitting ? null : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Upload Foto'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_selectedImage!, height: 260, fit: BoxFit.cover),
            )
          else
            const _EmptyPreview(),
          const SizedBox(height: 16),
          if (_errorMessage.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_errorMessage),
              ),
            ),
          const SizedBox(height: 8),
          Text(_statusMessage),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_isSubmitting ? 'Mengirim...' : 'Submit Delivery'),
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
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Text('Belum ada foto proof.'),
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