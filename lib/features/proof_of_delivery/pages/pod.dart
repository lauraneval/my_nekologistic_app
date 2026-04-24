import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_nekologistic_app/core/network/api_client.dart';
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
  CameraController? _cameraController;
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
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
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1
                    ),
                  ),
                ),
                Text(
                  "Proof Of Delivery",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Capture a clear photo of the package at the drop off location.",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45
                  ),
                ),
                Padding(
                    padding: EdgeInsetsGeometry.only(top: 32, bottom: 8),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _imageFile != null
                                ? Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                                : (_cameraController != null && _cameraController!.value.isInitialized
                                ? CameraPreview(_cameraController!)
                                : Container(color: Colors.indigo[50])),
                          ),
                          if (_cameraController?.value.isInitialized == true || _imageFile != null)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ),
                          Positioned.fill(
                            child: ElevatedButton(
                              onPressed: _openCamera,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: (_cameraController?.value.isInitialized == true || _imageFile != null)
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
                                    color: (_cameraController?.value.isInitialized == true || _imageFile != null)
                                        ? Colors.white
                                        : Colors.blue[900],
                                  ),
                                  Text(
                                    _imageFile != null ? "Change Evidence" : "Attach Evidence",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w300,
                                      color: (_cameraController?.value.isInitialized == true || _imageFile != null)
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
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.indigo,
                            size: 16,
                          ),
                          Text(
                            "42nd West Ave, NYC",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                      Text(
                        "Estimated Precision : 2.4m",
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
                        "${arrivedAt.hour}:${arrivedAt.minute}",
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue[900]
                        ),
                      ),
                      Text(
                        DateFormat("LLL dd, yyyy").format(arrivedAt),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87
                        ),
                      )
                    ]
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50], // Light blue background
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Recipient Signature',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Required for High Value',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // The "Add Now" Button
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue[900], // Navy blue text
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Add Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900]
                    ),
                    child: Padding(
                      padding: EdgeInsetsGeometry.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              "Upload & Complete Delivery",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                              )
                          ),
                          Padding(padding: EdgeInsets.only(left: 8)),
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          )
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