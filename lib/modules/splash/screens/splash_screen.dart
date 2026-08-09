import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ResponsiveUtils.width(context, 72),
              height: ResponsiveUtils.width(context, 72),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.width(context, 22),
                ),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: ResponsiveUtils.width(context, 36),
              ),
            ),
            ResponsiveUtils.verticalGap(context, 20),
            Text(
              AppConstants.appName,
              style: AppTextStyles.pageTitle.copyWith(
                fontSize: ResponsiveUtils.fontSize(context, 24),
              ),
            ),
            ResponsiveUtils.verticalGap(context, 24),
            SizedBox.square(
              dimension: ResponsiveUtils.width(context, 22),
              child: const CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
