import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/services/product_image_service.dart';

void main() {
  test('copies a catalog photo into product_images', () async {
    final root = await Directory.systemTemp.createTemp('creovo_product_img_');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/source.jpg');
    await source.writeAsBytes(const [1, 2, 3, 4]);

    final images = ProductImageService(directoryProvider: () async => root);
    final stored = await images.storeFile(source);

    expect(stored.endsWith('.jpg'), isTrue);
    expect(images.existsSync(stored), isTrue);
    expect(await images.resolve(stored).readAsBytes(), [1, 2, 3, 4]);
  });

  test('deletes a stored catalog photo', () async {
    final root = await Directory.systemTemp.createTemp('creovo_product_img_');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/source.png');
    await source.writeAsBytes(const [9, 8, 7]);

    final images = ProductImageService(directoryProvider: () async => root);
    final stored = await images.storeFile(source);
    await images.delete(stored);

    expect(images.existsSync(stored), isFalse);
  });
}
