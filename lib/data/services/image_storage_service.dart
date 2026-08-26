import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  ImageStorageService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickAndStore(
    String assetName, {
    ImageSource source = ImageSource.gallery,
  }) async {
    final selected = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (selected == null) return null;
    return _copyIntoBusinessAssets(
      assetName: assetName,
      source: File(selected.path),
      extension: p.extension(selected.path),
    );
  }

  Future<String> storeBytes(
    String assetName,
    Uint8List bytes, {
    String extension = '.png',
  }) async {
    final destination = await _destination(assetName, extension);
    await destination.writeAsBytes(bytes, flush: true);
    return destination.path;
  }

  Future<String> _copyIntoBusinessAssets({
    required String assetName,
    required File source,
    required String extension,
  }) async {
    final destination = await _destination(assetName, extension);
    await source.copy(destination.path);
    return destination.path;
  }

  Future<File> _destination(String assetName, String extension) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'business_assets'));
    await directory.create(recursive: true);
    final suffix = extension.isEmpty ? '.jpg' : extension.toLowerCase();
    return File(
      p.join(
        directory.path,
        '${assetName}_${DateTime.now().millisecondsSinceEpoch}$suffix',
      ),
    );
  }
}
