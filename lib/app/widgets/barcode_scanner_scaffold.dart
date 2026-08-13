import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../constants/app_colors.dart';
import '../themes/app_text_styles.dart';
import 'barcode_viewfinder.dart';

/// Full-screen camera chrome shared by one-shot and catalog scanners.
class BarcodeScannerScaffold extends StatelessWidget {
  const BarcodeScannerScaffold({
    required this.controller,
    required this.onDetect,
    required this.hint,
    this.title = 'Scan barcode',
    super.key,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;
  final String hint;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: controller, onDetect: onDetect),
          const IgnorePointer(child: Center(child: BarcodeViewfinder())),
          Positioned(
            right: 14,
            top: 14,
            child: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, _) {
                if (state.torchState == TorchState.unavailable) {
                  return const SizedBox.shrink();
                }
                final on = state.torchState == TorchState.on;
                return Material(
                  color: on
                      ? AppColors.primary
                      : Colors.black.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Torch',
                    onPressed: controller.toggleTorch,
                    icon: Icon(
                      on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
