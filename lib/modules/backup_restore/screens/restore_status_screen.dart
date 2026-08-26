import 'dart:io';

import 'package:flutter/material.dart' hide Text;
import 'package:get/get.dart';

import '../../../app/bindings/initial_binding.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/localization/localized_text.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/services/app_storage.dart';
import '../../../data/services/backup_service.dart';

class RestoreStatusScreen extends StatefulWidget {
  const RestoreStatusScreen({
    required this.path,
    this.restoreOperation,
    this.reloadOperation,
    this.onContinue,
    this.startDelay = const Duration(milliseconds: 450),
    super.key,
  });

  final String path;
  final Future<void> Function(String path)? restoreOperation;
  final Future<void> Function()? reloadOperation;
  final VoidCallback? onContinue;
  final Duration startDelay;

  @override
  State<RestoreStatusScreen> createState() => _RestoreStatusScreenState();
}

class _RestoreStatusScreenState extends State<RestoreStatusScreen> {
  _RestoreState state = _RestoreState.working;
  String? error;
  var canContinue = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    // Give GetX one frame to dispose every database-backed route/controller
    // before BackupService closes and replaces the Drift database file.
    await Future<void>.delayed(widget.startDelay);
    try {
      final operation = widget.restoreOperation;
      BackupRestoreResult? restoreResult;
      if (operation != null) {
        await operation(widget.path);
      } else {
        restoreResult = await Get.find<BackupService>().restore(
          File(widget.path),
        );
      }
      await _reloadRuntime();
      if (restoreResult != null) {
        final paths = restoreResult.mediaPaths;
        await Get.find<BusinessRepository>().updateMediaPaths(
          logoPath: paths['logo'],
          paymentQrPath: paths['payment_qr'],
          signaturePath: paths['signature'],
        );
      }
      if (mounted) {
        setState(() {
          state = _RestoreState.complete;
          canContinue = true;
        });
      }
    } catch (exception, stackTrace) {
      debugPrint('Restore failed: $exception\n$stackTrace');
      var runtimeRecovered = false;
      try {
        await _reloadRuntime();
        runtimeRecovered = true;
      } catch (reloadException, reloadStackTrace) {
        debugPrint(
          'Database reload failed: $reloadException\n$reloadStackTrace',
        );
      }
      if (mounted) {
        setState(() {
          state = _RestoreState.failed;
          canContinue = runtimeRecovered;
          error = exception.toString().replaceFirst('Bad state: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Column(
                children: [
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _statusIcon,
                  ),
                  const SizedBox(height: 24),
                  Text(_title, style: AppTextStyles.pageTitle),
                  const SizedBox(height: 10),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (state == _RestoreState.failed && error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (state != _RestoreState.working && canContinue)
                    AppConstrainedAction(
                      child: AppButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _continue,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget get _statusIcon => Container(
    key: ValueKey(state),
    width: 92,
    height: 92,
    decoration: BoxDecoration(
      color: _statusColor.withValues(alpha: .11),
      shape: BoxShape.circle,
    ),
    child: state == _RestoreState.working
        ? Padding(
            padding: const EdgeInsets.all(29),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _statusColor,
            ),
          )
        : Icon(_statusIconData, color: _statusColor, size: 43),
  );

  String get _title => switch (state) {
    _RestoreState.working => 'Restoring your data',
    _RestoreState.complete => 'Restore complete',
    _RestoreState.failed => 'Restore needs attention',
  };

  String get _message => switch (state) {
    _RestoreState.working =>
      'Keep Creovo Billing open while your validated backup is restored.',
    _RestoreState.complete =>
      'Your backup was restored safely and is ready to use.',
    _RestoreState.failed =>
      canContinue
          ? 'Creovo Billing could not finish the restore. Your current data is ready, so you can continue and try again.'
          : 'Creovo Billing could not reload its database. Close and reopen the app before trying again.',
  };

  Color get _statusColor => switch (state) {
    _RestoreState.working => AppColors.primary,
    _RestoreState.complete => AppColors.success,
    _RestoreState.failed => AppColors.error,
  };

  IconData get _statusIconData => switch (state) {
    _RestoreState.working => Icons.restore_rounded,
    _RestoreState.complete => Icons.check_rounded,
    _RestoreState.failed => Icons.error_outline_rounded,
  };

  Future<void> _reloadRuntime() async {
    final operation = widget.reloadOperation;
    if (operation != null) {
      await operation();
    } else if (widget.restoreOperation == null) {
      await InitialBinding.reloadDatabaseRuntime(Get.find<AppStorage>());
    }
  }

  void _continue() {
    final callback = widget.onContinue;
    if (callback != null) {
      callback();
      return;
    }
    Get.offAllNamed<void>(AppRoutes.splash);
  }
}

enum _RestoreState { working, complete, failed }
