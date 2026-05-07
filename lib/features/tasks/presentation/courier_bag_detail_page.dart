import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../data/courier_bag_api_client.dart';
import '../data/pod_service.dart';
import '../domain/courier_bag_models.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.task,
    required this.apiClient,
  });

  final CourierBagTask task;
  final ApiClient apiClient;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late final CourierBagApiClient _courierApiClient;
  late final PodService _podService;
  late Future<_BagDetailViewData> _viewFuture;
  bool _isSubmitting = false;
  String _progressMessage = '';
  double _progressValue = 0;

  @override
  void initState() {
    super.initState();
    _courierApiClient = CourierBagApiClient(apiClient: widget.apiClient);
    _podService = PodService(apiClient: widget.apiClient);
    _viewFuture = _loadViewData();
  }

  Future<_BagDetailViewData> _loadViewData() async {
    final detail = await _courierApiClient.fetchBagDetail(widget.task.id);
    final timeline = await _courierApiClient.fetchBagTimeline(widget.task.id);
    return _BagDetailViewData(detail: detail, timeline: timeline);
  }

  Future<_BagDetailViewData> _refreshViewData() async {
    final future = _loadViewData();
    setState(() {
      _viewFuture = future;
    });
    return future;
  }

  Future<void> _openMaps() async {
    final query = widget.task.hasCoordinates
        ? '${widget.task.latitude},${widget.task.longitude}'
        : widget.task.receiverAddress ?? widget.task.destinationCity;

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

  Future<void> _submitPod(CourierBagPackage packageItem) async {
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
        packageItem: packageItem,
        preparedImageFile: preparedPhoto,
        onProgress: _onProgress,
      );

      if (!mounted) {
        return;
      }

      final latestView = await _refreshViewData();
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

      if (latestView.isCompleted) {
        Navigator.of(context).pop(true);
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Bag')),
      body: RefreshIndicator(
        onRefresh: _refreshViewData,
        child: FutureBuilder<_BagDetailViewData>(
          future: _viewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Terjadi error saat memuat detail bag: ${snapshot.error}',
                    ),
                  ),
                ],
              );
            }

            final viewData = snapshot.data;
            if (viewData == null) {
              return const Center(child: Text('Data bag tidak ditemukan.'));
            }

            final bag = viewData.bag;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bag.bagCode,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(bag.destinationCity),
                        const SizedBox(height: 8),
                        Text('Status: ${bag.status}'),
                        const SizedBox(height: 8),
                        Text(
                          'Assigned courier: ${bag.assignedCourierId ?? '-'}',
                        ),
                        const SizedBox(height: 8),
                        Text('Paket di bag: ${viewData.packages.length}'),
                        const SizedBox(height: 12),
                        Text(
                          widget.task.receiverName != null
                              ? 'Penerima: ${widget.task.receiverName}'
                              : 'Penerima: -',
                        ),
                        const SizedBox(height: 4),
                        Text(widget.task.receiverAddress ?? 'Alamat: -'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Arahkan ke Bag'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Paket di Dalam Bag',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...viewData.packages.map(
                  (packageItem) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PackageCard(
                      packageItem: packageItem,
                      isSubmitting: _isSubmitting,
                      progressMessage: _progressMessage,
                      progressValue: _progressValue,
                      onDeliver: () => _submitPod(packageItem),
                    ),
                  ),
                ),
                if (_isSubmitting) ...[
                  const SizedBox(height: 4),
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
                ],
                const SizedBox(height: 8),
                Text(
                  'Setiap kartu paket menampilkan timeline per paket dari endpoint `/timeline`. Saat deliver berhasil, halaman ini memuat ulang data bag agar status terbaru dan penutupan bag otomatis ikut terbaca.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BagDetailViewData {
  _BagDetailViewData({required this.detail, required this.timeline});

  final CourierBagDetail detail;
  final CourierBagTimelineResponse timeline;

  CourierBagSummary get bag => detail.bag;

  List<CourierBagPackage> get packages => timeline.packages;

  bool get isCompleted =>
      bag.status == 'DELIVERED' ||
      packages.isNotEmpty &&
          packages.every((item) => item.status == 'DELIVERED');
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.packageItem,
    required this.isSubmitting,
    required this.progressMessage,
    required this.progressValue,
    required this.onDeliver,
  });

  final CourierBagPackage packageItem;
  final bool isSubmitting;
  final String progressMessage;
  final double progressValue;
  final VoidCallback onDeliver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeline = packageItem.timeline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageItem.resi,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(packageItem.receiverName),
                      const SizedBox(height: 4),
                      Text(packageItem.receiverAddress),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(status: packageItem.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              packageItem.hasCoordinates
                  ? 'Koordinat tujuan: ${packageItem.latitude?.toStringAsFixed(6)}, ${packageItem.longitude?.toStringAsFixed(6)}'
                  : 'Koordinat tujuan tidak tersedia.',
            ),
            const SizedBox(height: 12),
            Text('Timeline Paket', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (timeline.isEmpty)
              const Text('Belum ada event timeline untuk paket ini.')
            else
              Column(
                children: timeline
                    .map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, size: 10),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.eventLabel),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      event.eventCode,
                                      if (event.location != null)
                                        event.location!,
                                      event.createdAt.toLocal().toString(),
                                    ].join(' • '),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (event.description != null) ...[
                                    const SizedBox(height: 2),
                                    Text(event.description!),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isSubmitting || packageItem.status == 'DELIVERED'
                  ? null
                  : onDeliver,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_outlined),
              label: Text(
                packageItem.status == 'DELIVERED'
                    ? 'Sudah Delivered'
                    : isSubmitting
                    ? 'Memproses POD...'
                    : 'Deliver Paket',
              ),
            ),
            if (isSubmitting) ...[
              const SizedBox(height: 8),
              Text(progressMessage),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progressValue),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'DELIVERED' => Colors.green,
      'OUT_FOR_DELIVERY' => Colors.orange,
      'IN_WAREHOUSE' => Colors.blue,
      _ => Colors.grey,
    };

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      labelStyle: TextStyle(color: color),
    );
  }
}
