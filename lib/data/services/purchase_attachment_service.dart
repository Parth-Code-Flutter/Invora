import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PurchaseAttachmentService {
  const PurchaseAttachmentService();

  Future<StoredPurchaseAttachment?> pickAndStore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    final sourcePath = result?.files.single.path;
    if (sourcePath == null) return null;
    final source = File(sourcePath);
    final support = await getApplicationSupportDirectory();
    final folder = Directory(p.join(support.path, 'purchase_attachments'));
    await folder.create(recursive: true);
    final safeName = p
        .basename(source.path)
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storedName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final output = await source.copy(p.join(folder.path, storedName));
    return StoredPurchaseAttachment(
      fileName: p.basename(source.path),
      relativePath: storedName,
      mimeType: _mimeFor(output.path),
      sizeBytes: await output.length(),
    );
  }

  Future<File> resolve(String relativePath) async {
    final support = await getApplicationSupportDirectory();
    return File(p.join(support.path, 'purchase_attachments', relativePath));
  }

  Future<void> share(String relativePath, {required String fileName}) async {
    final file = await resolve(relativePath);
    if (!await file.exists()) {
      throw StateError('The attached bill file is missing from this device.');
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: fileName),
    );
  }

  Future<void> delete(String relativePath) async {
    final file = await resolve(relativePath);
    if (await file.exists()) await file.delete();
  }

  String? _mimeFor(String path) => switch (p.extension(path).toLowerCase()) {
    '.pdf' => 'application/pdf',
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.jpg' || '.jpeg' => 'image/jpeg',
    _ => null,
  };
}

class StoredPurchaseAttachment {
  const StoredPurchaseAttachment({
    required this.fileName,
    required this.relativePath,
    required this.mimeType,
    required this.sizeBytes,
  });
  final String fileName, relativePath;
  final String? mimeType;
  final int sizeBytes;
}
