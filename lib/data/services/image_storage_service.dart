import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  ImageStorageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickAndStore(String assetName) async {
    final selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (selected == null) return null;

    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'business_assets'));
    await directory.create(recursive: true);
    final extension = p.extension(selected.path).isEmpty
        ? '.jpg'
        : p.extension(selected.path).toLowerCase();
    final destination = File(
      p.join(
        directory.path,
        '${assetName}_${DateTime.now().millisecondsSinceEpoch}$extension',
      ),
    );
    await File(selected.path).copy(destination.path);
    return destination.path;
  }
}
