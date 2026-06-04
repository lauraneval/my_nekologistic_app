import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/config/app_env.dart';

class ProofUploadService {
  ProofUploadService({ImagePicker? imagePicker}) : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<File?> pickPhoto({required ImageSource source}) async {
    final image = await _imagePicker.pickImage(source: source, imageQuality: 100);
    if (image == null) {
      return null;
    }
    return _compress(image);
  }

  Future<String> uploadProofPhoto({required String taskId, required File file}) async {
    final bucket = Supabase.instance.client.storage.from(AppEnv.podBucket);
    final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'courier/$taskId/$fileName';

    await bucket.upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );

    return bucket.getPublicUrl(path);
  }

  Future<File> _compress(XFile source) async {
    final directory = await getTemporaryDirectory();
    final targetPath = '${directory.path}/proof_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      source.path,
      targetPath,
      format: CompressFormat.jpeg,
      quality: 80,
      minWidth: 1280,
      minHeight: 1280,
    );

    if (compressed == null) {
      return File(source.path);
    }

    return File(compressed.path);
  }
}