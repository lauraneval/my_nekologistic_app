import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_nekologistic_app/features/proof_of_delivery/pages/pod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../data/pod_service.dart';
import '../domain/courier_task.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.task,
    required this.apiClient,
  });

  final CourierTask task;
  final ApiClient apiClient;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late final PodService _podService;
  bool _isSubmitting = false;
  String _progressMessage = '';
  double _progressValue = 0;

  @override
  void initState() {
    super.initState();
    _podService = PodService(apiClient: widget.apiClient);
  }

  Future<void> _openMaps() async {
    final query = widget.task.hasCoordinates
        ? '${widget.task.latitude},${widget.task.longitude}'
        : widget.task.address;

    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Google Maps.')),
      );
    }
  }

  Future<void> _submitPod() async {
    File? preparedPhoto;

    setState(() {
      _isSubmitting = true;
      _progressMessage = 'Menyiapkan kamera...';
      _progressValue = 0.1;
    });

    try {
      preparedPhoto = await _podService.captureCompressedPhoto(
        onProgress: _onProgress,
      );
      if (!mounted) {
        return;
      }

      final shouldContinue = await _confirmPhoto(preparedPhoto);
      if (shouldContinue != true) {
        return;
      }

      _onProgress(PodProgressStep.lockingLocation);

      final result = await _podService.submitProofOfDelivery(
        task: widget.task,
        preparedImageFile: preparedPhoto,
        onProgress: _onProgress,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengiriman berhasil diselesaikan. Lokasi terkunci di '
            '${result.courierLatitude.toStringAsFixed(6)}, '
            '${result.courierLongitude.toStringAsFixed(6)}',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal submit POD: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }

      if (preparedPhoto != null && await preparedPhoto.exists()) {
        await preparedPhoto.delete();
      }
    }
  }

  void _onProgress(
    PodProgressStep step, {
    int attempt = 1,
    int maxAttempt = 1,
  }) {
    if (!mounted) {
      return;
    }

    final attemptSuffix = maxAttempt > 1 && attempt > 1
        ? ' (percobaan $attempt/$maxAttempt)'
        : '';

    setState(() {
      switch (step) {
        case PodProgressStep.openingCamera:
          _progressValue = 0.1;
          _progressMessage = 'Membuka kamera...';
          break;
        case PodProgressStep.compressingPhoto:
          _progressValue = 0.2;
          _progressMessage = 'Mengompresi foto POD...';
          break;
        case PodProgressStep.lockingLocation:
          _progressValue = 0.4;
          _progressMessage = 'Mengunci lokasi kurir...';
          break;
        case PodProgressStep.validatingDistance:
          _progressValue = 0.55;
          _progressMessage = 'Memvalidasi jarak ke tujuan...';
          break;
        case PodProgressStep.uploadingPhoto:
          _progressValue = 0.75;
          _progressMessage = 'Mengupload foto POD$attemptSuffix...';
          break;
        case PodProgressStep.updatingStatus:
          _progressValue = 0.9;
          _progressMessage =
              'Mengirim update status DELIVERED$attemptSuffix...';
          break;
        case PodProgressStep.completed:
          _progressValue = 1;
          _progressMessage = 'POD selesai diproses.';
          break;
      }
    });
  }

  Future<bool?> _confirmPhoto(File imageFile) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Foto POD'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pastikan foto bukti pengiriman sudah jelas sebelum dikirim.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ambil Ulang'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Gunakan Foto Ini'),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengiriman')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resi: ${task.resi}'),
                  const SizedBox(height: 8),
                  Text('Penerima: ${task.recipientName}'),
                  const SizedBox(height: 8),
                  Text('Alamat: ${task.address}'),
                  const SizedBox(height: 8),
                  Text('Status: ${task.status}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _openMaps,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Arahkan'),
          ),
          const SizedBox(height: 12),
          if (_isSubmitting) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _progressMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _progressValue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            // Navigate to POD Page for this task
            onPressed: () { Navigator.push(
                context, MaterialPageRoute(builder: (context) => ProofOfDeliveryPage(task: task, apiClient: widget.apiClient))
            );},
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_outlined),
            label: Text(
              _isSubmitting ? 'Memproses POD...' : 'Selesaikan Pengiriman',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saat tombol ditekan, aplikasi akan membuka kamera untuk foto POD, '
            'menampilkan preview konfirmasi, lalu mengunci lokasi GPS, '
            'upload foto ke Supabase Storage, dan mengirim status DELIVERED ke backend.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
