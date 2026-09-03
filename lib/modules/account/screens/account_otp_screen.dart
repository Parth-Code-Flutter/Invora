import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/responsive_utils.dart';
import '../../../app/widgets/app_bottom_sheet.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_constrained_action.dart';
import '../../../app/widgets/app_dropdown_field.dart';
import '../../../app/widgets/app_text_field.dart';
import '../../../data/services/account_phone.dart';
import '../controllers/account_otp_controller.dart';

class AccountOtpScreen extends GetView<AccountOtpController> {
  const AccountOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: Form(
            key: controller.formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.horizontalPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  Text(
                    'WELCOME TO CREOVO',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your first offline billing app',
                    style: AppTextStyles.pageTitle.copyWith(
                      fontSize: ResponsiveUtils.fontSize(context, 28),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This number is only for your Creovo plan. We never print it on invoices, and your bills stay on this phone.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _PlanInfoCard(),
                  const SizedBox(height: 22),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Obx(() {
                          if (controller.waitingForOtp.value) {
                            return _OtpStep(controller: controller);
                          }
                          return _MobileStep(controller: controller);
                        }),
                        const SizedBox(height: 12),
                        Obx(() {
                          final message = controller.errorMessage.value;
                          if (message.isEmpty) return const SizedBox.shrink();
                          return Text(
                            message,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.error,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            ResponsiveUtils.horizontalPadding(context),
            12,
            ResponsiveUtils.horizontalPadding(context),
            12,
          ),
          child: Obx(
            () => AppConstrainedAction(
              child: AppButton(
                label: controller.waitingForOtp.value
                    ? 'Verify & continue'
                    : 'Send OTP',
                trailingIcon: Icons.arrow_forward_rounded,
                isLoading: controller.isWorking.value,
                onPressed: controller.isWorking.value
                    ? null
                    : controller.waitingForOtp.value
                    ? controller.verifyOtp
                    : controller.sendOtp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanInfoCard extends StatelessWidget {
  const _PlanInfoCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        child: Column(
          children: const [
            _InfoRow(
              icon: Icons.workspace_premium_outlined,
              text: 'Used only to check your trial and subscription.',
            ),
            SizedBox(height: 10),
            _InfoRow(
              icon: Icons.receipt_long_outlined,
              text:
                  'Never shown on invoices. Add a separate Invoice mobile later if you want it on bills.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileStep extends StatelessWidget {
  const _MobileStep({required this.controller});

  final AccountOtpController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => AppTextField(
            controller: controller.mobile,
            label: 'Account mobile *',
            hint: controller.mobileHint,
            prefix: _CountryPrefix(
              country: controller.country.value,
              onTap: () => _pickCountry(context),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofocus: false,
            focusBorderColor: AppColors.secondary,
            autofillHints: const [
              AutofillHints.telephoneNumber,
              AutofillHints.telephoneNumberNational,
              AutofillHints.telephoneNumberDevice,
            ],
            validator: controller.validateMobile,
            onFieldSubmitted: (_) => controller.sendOtp(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                controller.country.value.maxLength,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _openDeviceNumbers(context),
          icon: const Icon(Icons.smartphone_rounded, size: 18),
          label: const Text('Use a number from this phone'),
        ),
      ],
    );
  }

  Future<void> _openDeviceNumbers(BuildContext context) async {
    await controller.loadDeviceNumbers();
    if (!context.mounted) return;
    final numbers = controller.deviceNumbers.toList(growable: false);
    if (numbers.isEmpty) {
      await controller.pickFromThisPhone();
      return;
    }
    final selected = await showAppBottomSheet<DeviceAccountNumber>(
      context: context,
      title: 'Choose a number',
      child: _DeviceNumberSheet(
        numbers: numbers,
        onChooseContacts: controller.pickFromThisPhone,
      ),
    );
    if (selected != null) controller.applyDeviceNumber(selected);
  }

  Future<void> _pickCountry(BuildContext context) async {
    final selected = await showAppDropdownSheet<AccountCountry>(
      context: context,
      title: 'Choose country',
      value: controller.country.value,
      searchable: true,
      heightFactor: 0.75,
      searchHint: 'Search country',
      emptyLabel: 'No matching country',
      options: [
        for (final country in AccountCountry.all)
          AppDropdownOption(value: country, label: country.pickerLabel),
      ],
    );
    if (selected != null) controller.selectCountry(selected);
  }
}

class _DeviceNumberSheet extends StatelessWidget {
  const _DeviceNumberSheet({
    required this.numbers,
    required this.onChooseContacts,
  });

  final List<DeviceAccountNumber> numbers;
  final VoidCallback onChooseContacts;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: numbers.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == numbers.length) {
            return _NumberTile(
              title: 'Choose from contacts',
              subtitle: 'Pick any number saved on this phone',
              icon: Icons.contacts_outlined,
              onTap: () {
                Navigator.of(context).pop();
                onChooseContacts();
              },
            );
          }
          final number = numbers[index];
          final name = number.displayName;
          return _NumberTile(
            title: number.displayNumber,
            subtitle: name.isEmpty ? 'Saved on this phone' : name,
            icon: Icons.phone_iphone_rounded,
            onTap: () => Navigator.of(context).pop(number),
          );
        },
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 21, color: AppColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.listName),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix({required this.country, required this.onTap});

  final AccountCountry country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              country.e164Prefix,
              style: AppTextStyles.listName.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const Icon(Icons.expand_more_rounded, size: 20),
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.only(left: 6, right: 4),
              color: AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({required this.controller});

  final AccountOtpController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => Text(
            'OTP sent to ${controller.formattedMobile}',
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: controller.otp,
          label: 'Enter OTP *',
          hint: '6-digit code',
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofocus: true,
          autofillHints: const [AutofillHints.oneTimeCode],
          onFieldSubmitted: (_) => controller.verifyOtp(),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Obx(
              () => TextButton(
                onPressed: controller.isWorking.value
                    ? null
                    : controller.resendOtp,
                child: const Text('Resend OTP'),
              ),
            ),
            Obx(
              () => TextButton(
                onPressed: controller.isWorking.value
                    ? null
                    : controller.editNumber,
                child: const Text('Change number'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
