import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/business_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/services/invoice_pdf_service.dart';
import '../models/invoice_success_args.dart';

class InvoiceSaveSuccessDialog extends StatefulWidget {
  const InvoiceSaveSuccessDialog({required this.arguments, super.key});

  final InvoiceSaveSuccessArgs arguments;

  @override
  State<InvoiceSaveSuccessDialog> createState() =>
      _InvoiceSaveSuccessDialogState();
}

class _InvoiceSaveSuccessDialogState extends State<InvoiceSaveSuccessDialog> {
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final arguments = widget.arguments;
    final isQuotation = arguments.documentType == DocumentType.quotation;
    final document = isQuotation ? 'Quotation' : 'Invoice';
    final action = arguments.wasUpdate ? 'updated' : 'created';
    final screenHeight = MediaQuery.sizeOf(context).height;
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 430,
            maxHeight: screenHeight * .86,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 34,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Column(
                        children: [
                          _SuccessHero(
                            document: document,
                            invoiceNumber: arguments.invoiceNumber,
                            wasUpdate: arguments.wasUpdate,
                            action: action,
                          ),
                          const SizedBox(height: 20),
                          Text('Quick actions', style: AppTextStyles.listName),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SuccessIconAction(
                                icon: Icons.ios_share_rounded,
                                label: 'Share PDF',
                                loading: _sharing,
                                onTap: _sharing
                                    ? null
                                    : () => _share(arguments),
                              ),
                              const SizedBox(width: 42),
                              _SuccessIconAction(
                                icon: Icons.picture_as_pdf_rounded,
                                label: 'View PDF',
                                emphasized: true,
                                onTap: () => Get.back<InvoiceSaveSuccessAction>(
                                  result: InvoiceSaveSuccessAction.viewPdf,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: AppButton(
                      label: 'Done',
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: () => Get.back<InvoiceSaveSuccessAction>(
                        result: InvoiceSaveSuccessAction.done,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _share(InvoiceSaveSuccessArgs arguments) async {
    setState(() => _sharing = true);
    try {
      final invoice = await Get.find<InvoiceRepository>().getById(
        arguments.invoiceId,
      );
      final business = await Get.find<BusinessRepository>().getProfile();
      if (invoice == null || business == null) {
        AppNotification.warning(
          'Unable to share',
          'The saved document could not be loaded.',
        );
        return;
      }
      await Get.find<InvoicePdfService>().shareInvoice(
        invoice: invoice,
        business: business,
        template: arguments.template,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _SuccessHero extends StatelessWidget {
  const _SuccessHero({
    required this.document,
    required this.invoiceNumber,
    required this.wasUpdate,
    required this.action,
  });

  final String document;
  final String invoiceNumber;
  final bool wasUpdate;
  final String action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$document ready',
                    style: AppTextStyles.listName.copyWith(color: Colors.white),
                  ),
                  Text(
                    invoiceNumber,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                wasUpdate ? 'UPDATED' : 'NEW',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.rotate(angle: -0.04, child: const _InvoiceMockup()),
              const Positioned(
                right: 26,
                bottom: -23,
                child: InvoiceSuccessAnimation(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 27),
        Text(
          '$document $action successfully',
          textAlign: TextAlign.center,
          style: AppTextStyles.listName.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Saved securely on this device',
          style: AppTextStyles.small.copyWith(color: Colors.white70),
        ),
      ],
    ),
  );
}

class _InvoiceMockup extends StatelessWidget {
  const _InvoiceMockup();

  @override
  Widget build(BuildContext context) => Container(
    width: 190,
    height: 128,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 70,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 15),
        const _DocumentLine(width: 142),
        const SizedBox(height: 8),
        const _DocumentLine(width: 108),
        const SizedBox(height: 8),
        const _DocumentLine(width: 126),
        const Spacer(),
        const _DocumentLine(width: 48),
      ],
    ),
  );
}

class InvoiceSuccessAnimation extends StatefulWidget {
  const InvoiceSuccessAnimation({super.key});

  @override
  State<InvoiceSuccessAnimation> createState() =>
      _InvoiceSuccessAnimationState();
}

class _InvoiceSuccessAnimationState extends State<InvoiceSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(vsync: this);
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 78,
    height: 78,
    child: Lottie.asset(
      'assets/animations/invoice_success.json',
      controller: _animation,
      repeat: false,
      fit: BoxFit.contain,
      onLoaded: (composition) {
        _animation.duration = composition.duration;
        if (_reduceMotion) {
          _animation.value = 1;
        } else {
          _animation.forward(from: 0);
        }
      },
    ),
  );
}

class _DocumentLine extends StatelessWidget {
  const _DocumentLine({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 6,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

class _SuccessIconAction extends StatelessWidget {
  const _SuccessIconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool emphasized;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    enabled: onTap != null,
    child: Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: emphasized
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: emphasized ? null : AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                  border: emphasized
                      ? null
                      : Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (emphasized
                                  ? AppColors.secondary
                                  : AppColors.textTertiary)
                              .withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        icon,
                        size: 22,
                        color: emphasized ? Colors.white : AppColors.secondary,
                      ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
