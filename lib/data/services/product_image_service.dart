import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores up to three catalog photos beside the database, not in SQLite.
class ProductImageService {
  ProductImageService({
    ImagePicker? picker,
    Future<Directory> Function()? directoryProvider,
  }) : _picker = picker ?? ImagePicker(),
       _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const maxImages = 3;
  static const folderName = 'product_images';

  final ImagePicker _picker;
  final Future<Directory> Function() _directoryProvider;
  Directory? _folder;

  Future<Directory> ensureReady() async {
    final existing = _folder;
    if (existing != null) return existing;
    final root = await _directoryProvider();
    final folder = Directory(p.join(root.path, folderName));
    await folder.create(recursive: true);
    _folder = folder;
    return folder;
  }

  File resolve(String relativePath) {
    final folder = _folder;
    if (folder == null) {
      throw StateError('ProductImageService.ensureReady() was not called.');
    }
    return File(p.join(folder.path, relativePath));
  }

  bool existsSync(String relativePath) {
    if (_folder == null) return false;
    return resolve(relativePath).existsSync();
  }

  Future<String?> pickAndStore({
    ImageSource source = ImageSource.gallery,
  }) async {
    final selected = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (selected == null) return null;
    return storeFile(File(selected.path));
  }

  Future<String> storeFile(File source) async {
    final folder = await ensureReady();
    final extension = p.extension(source.path).toLowerCase();
    final suffix = {'.png', '.jpg', '.jpeg', '.webp'}.contains(extension)
        ? extension
        : '.jpg';
    final name = '${DateTime.now().microsecondsSinceEpoch}$suffix';
    await source.copy(p.join(folder.path, name));
    return name;
  }

  Future<void> delete(String relativePath) async {
    await ensureReady();
    final file = resolve(relativePath);
    if (await file.exists()) await file.delete();
  }
}
