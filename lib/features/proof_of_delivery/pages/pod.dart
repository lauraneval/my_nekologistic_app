import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_nekologistic_app/core/network/api_client.dart';
import 'package:path_provider/path_provider.dart';
import '../../tasks/domain/courier_task.dart';
import '../components/pod_cards.dart';
import '../components/secondary_appbar.dart';

class ProofOfDeliveryPage extends StatefulWidget {
  const ProofOfDeliveryPage({
    super.key,
    required this.task,
    required this.apiClient,
  });

  final CourierTask task;
  final ApiClient apiClient;

  @override
  State<ProofOfDeliveryPage> createState() => PODPageState();
}

class PODPageState extends State<ProofOfDeliveryPage> {
  DateTime arrivedAt = DateTime.now();
  XFile? _imageFile;
  bool _isSubmitting = false;
  String _submittingStatus = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85, // Good balance of quality and size
    );
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _submitPod() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach evidence first.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submittingStatus = 'Getting location...';
    });

    try {
      // 1. Get Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // 2. Compress Image
      if (mounted) setState(() => _submittingStatus = 'Compressing image...');
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/pod_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        _imageFile!.path,
        targetPath,
        quality: 70,
      );

      if (compressedFile == null) throw Exception("Failed to compress image");

      // 3. Upload image to API via POST
      if (mounted) setState(() => _submittingStatus = 'Uploading image...');
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressedFile.path,
          filename: 'pod_${widget.task.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final uploadResponse = await widget.apiClient.post(
        '/courier/tasks/${widget.task.id}/deliver',
        data: formData,
      );

      if (uploadResponse.statusCode != 200 && uploadResponse.statusCode != 201) {
        throw Exception('Failed to upload image to server');
      }

      final imageUrl = uploadResponse.data['data']['pod_image_url'];
      if (imageUrl == null) {
        throw Exception('Server did not return image URL');
      }

      // 4. Update delivery status via PUT
      if (mounted) setState(() => _submittingStatus = 'Updating delivery status...');
      await widget.apiClient.put(
        '/courier/tasks/${widget.task.id}/deliver',
        data: {
          'status': 'DELIVERED',
          'pod_image_url': imageUrl,
          'courier_latitude': position.latitude,
          'courier_longitude': position.longitude,
          'target_latitude': widget.task.latitude,
          'target_longitude': widget.task.longitude,
        },
      );

      if (mounted) {
        setState(() => _submittingStatus = 'Success!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery completed successfully!')),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: secondaryAppbar(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                      color: Colors.indigo[100],
                      borderRadius: BorderRadius.circular(16)
                  ),
                  child: Text(
                    "#${widget.task.resi}",
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1
                    ),
                  ),
                ),
                const Text(
                  "Proof Of Delivery",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  "Capture a clear photo of the package at the drop off location.",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 8),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _imageFile != null
                                ? Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                                : Container(color: Colors.indigo[50]),
                          ),
                          if (_imageFile != null)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withAlpha(51),
                              ),
                            ),
                          Positioned.fill(
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _openCamera,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: _imageFile != null
                                    ? Colors.white
                                    : Colors.blue[900],
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ).copyWith(
                                elevation: const WidgetStatePropertyAll(0),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 64,
                                    color: _imageFile != null
                                        ? Colors.white
                                        : Colors.blue[900],
                                  ),
                                  Text(
                                    _imageFile != null ? "Change Evidence" : "Attach Evidence",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w300,
                                      color: _imageFile != null
                                          ? Colors.white
                                          : Colors.blue[900],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                podCards(
                    "location tag",
                    [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.indigo,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.task.address,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                      const Text(
                        "Current Drop-off Location",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87
                        ),
                      )
                    ]
                ),
                podCards(
                    "arrival time",
                    [
                      Text(
                        "${arrivedAt.hour}:${arrivedAt.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue[900]
                        ),
                      ),
                      Text(
                        DateFormat("LLL dd, yyyy").format(arrivedAt),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87
                        ),
                      )
                    ]
                ),
                ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPod,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        disabledBackgroundColor: Colors.blue[900]?.withAlpha(150),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSubmitting) ...[
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _submittingStatus,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ] else ...[
                            const Text(
                                "Upload & Complete Delivery",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white
                                )
                            ),
                            const Padding(padding: EdgeInsets.only(left: 8)),
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            )
                          ],
                        ],
                      ),
                    )
                )
              ],
            )
        ),
      ),
    );
  }
}
