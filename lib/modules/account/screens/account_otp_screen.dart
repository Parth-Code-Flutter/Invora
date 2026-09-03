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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [AppColors.darkBackground, Color(0xFF3A1A36)]
                : const [
                    Color(0xFFFFFFFF),
                    Color(0xFFF6F1FF),
                    Color(0xFFFFF4EE),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AutofillGroup(
            child: Form(
              key: controller.formKey,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.horizontalPadding(context),
                ),
                child: ListView(
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  children: [
                    const _WelcomeHero(),
                    const SizedBox(height: 16),
                    Text(
                      'Make GST invoices in minutes. Your bills stay on this phone.',
                      style: AppTextStyles.body.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.waitingForOtp.value) {
                        return _OtpStep(controller: controller);
                      }
                      return _MobileStep(controller: controller);
                    }),
                    Obx(() {
                      final message = controller.errorMessage.value;
                      if (message.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _ErrorBanner(message: message),
                      );
                    }),
                    const SizedBox(height: 16),
                    const _BenefitPills(),
                  ],
                ),
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
            8,
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

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(right: -28, top: -36, child: _Glow(size: 110)),
          const Positioned(left: -24, bottom: -40, child: _Glow(size: 90)),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .28),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icons/creovo_invoice_app_icon.png',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Offline GST invoicing',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your first bill is minutes away',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .1),
        ),
      ),
    );
  }
}

class _BenefitPills extends StatelessWidget {
  const _BenefitPills();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pill(icon: Icons.wifi_off_rounded, label: 'Works offline'),
        _Pill(icon: Icons.lock_rounded, label: 'Bills stay here'),
        _Pill(icon: Icons.bolt_rounded, label: 'Ready in minutes'),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.error,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileStep extends StatelessWidget {
  const _MobileStep({required this.controller});

  final AccountOtpController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: isDark ? .08 : .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
        child: Column(
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
            const SizedBox(height: 10),
            Text(
              'Used for your plan only. Never printed on invoices.',
              style: AppTextStyles.caption.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _openDeviceNumbers(context),
              icon: const Icon(Icons.smartphone_rounded, size: 18),
              label: const Text('Use a number from this phone'),
            ),
          ],
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Text(
                'OTP sent to ${controller.formattedMobile}',
                style: AppTextStyles.small.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
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
        ),
      ),
    );
  }
}
