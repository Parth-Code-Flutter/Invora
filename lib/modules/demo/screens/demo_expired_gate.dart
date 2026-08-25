import 'package:flutter/material.dart' hide Text;
import 'package:get/get.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_dialog.dart';
import '../../../data/services/demo_access_service.dart';

/// Blocks the whole navigator when a client demo APK has passed its baked-in
/// calendar expiry. Default builds never arm this overlay.
class DemoExpiredGate extends StatefulWidget {
  const DemoExpiredGate({
    required this.service,
    required this.child,
    super.key,
  });

  final DemoAccessService service;
  final Widget child;

  @override
  State<DemoExpiredGate> createState() => _DemoExpiredGateState();
}

class _DemoExpiredGateState extends State<DemoExpiredGate>
    with WidgetsBindingObserver {
  var _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.service.evaluate();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDialog());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final expired = widget.service.evaluate();
    if (!mounted) return;
    setState(() {});
    if (expired) _maybeShowDialog();
  }

  Future<void> _maybeShowDialog() async {
    if (!widget.service.isExpired || _dialogShown || !mounted) return;
    final navContext = Get.overlayContext;
    if (navContext == null || !navContext.mounted) return;
    _dialogShown = true;
    await showAppNoticeDialog(
      context: navContext,
      title: widget.service.lockTitle,
      message: widget.service.lockMessage,
      actionLabel: 'OK',
      tone: AppDialogTone.warning,
      icon: Icons.lock_clock_outlined,
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.service.isExpired) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        const ModalBarrier(dismissible: false, color: Color(0x99000000)),
        Material(
          color: Colors.transparent,
          child: _DemoExpiredView(service: widget.service),
        ),
      ],
    );
  }
}

class _DemoExpiredView extends StatelessWidget {
  const _DemoExpiredView({required this.service});

  final DemoAccessService service;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          color: AppColors.warningLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_clock_outlined,
                          color: AppColors.warning,
                          size: 29,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        service.lockTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.lockMessage,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
