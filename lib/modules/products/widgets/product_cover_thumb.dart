import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/enums/item_type.dart';
import '../../../data/services/product_image_service.dart';

class ProductCoverThumb extends StatelessWidget {
  const ProductCoverThumb({
    required this.imagePaths,
    required this.type,
    this.size = 42,
    this.radius = 13,
    super.key,
  });

  final List<String> imagePaths;
  final ItemType type;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = type == ItemType.product
        ? AppColors.primary
        : AppColors.secondary;
    final cover = imagePaths.isEmpty ? null : imagePaths.first;
    File? file;
    if (cover != null && Get.isRegistered<ProductImageService>()) {
      final images = Get.find<ProductImageService>();
      if (images.existsSync(cover)) file = images.resolve(cover);
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? .16 : .1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: file == null
          ? Icon(
              type == ItemType.product
                  ? Icons.inventory_2_outlined
                  : Icons.design_services_outlined,
              color: accent,
              size: size * 0.48,
            )
          : Image.file(file, fit: BoxFit.cover, width: size, height: size),
    );
  }
}
