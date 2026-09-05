import 'dart:ui';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:creovo_invoice/app/localization/localized_text.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/utils/app_focus.dart';
import '../../../app/widgets/app_notification.dart';
import '../../../data/services/account_phone.dart';
import '../../../data/services/entitlement_policy.dart';
import '../controllers/plan_controller.dart';

abstract final class _PlanIcons {
  static const back = 'assets/icons/plan/back.svg';
  static const help = 'assets/icons/plan/help.svg';
  static const crown = 'assets/icons/plan/crown.svg';
  static const checkLicense = 'assets/icons/plan/check_license.svg';
  static const calendar = 'assets/icons/plan/calendar.svg';
  static const autorenew = 'assets/icons/plan/autorenew.svg';
  static const checkUnlocked = 'assets/icons/plan/check_unlocked.svg';
  static const gstBills = 'assets/icons/plan/gst_bills.svg';
  static const checkActive = 'assets/icons/plan/check_active.svg';
  static const ledger = 'assets/icons/plan/ledger.svg';
  static const offlineShield = 'assets/icons/plan/offline_shield.svg';
  static const support = 'assets/icons/plan/support.svg';
  static const phone = 'assets/icons/plan/phone.svg';
  static const checkPrimary = 'assets/icons/plan/check_primary.svg';
  static const refresh = 'assets/icons/plan/refresh.svg';
  static const whatsapp = 'assets/icons/plan/whatsapp.svg';
  static const manage = 'assets/icons/plan/manage.svg';
  static const dataShield = 'assets/icons/plan/data_shield.svg';
}

abstract final class _PlanUi {
  static const page = Color(0xFFF8F6F4);
  static const ink = Color(0xFF180E1C);
  static const muted = Color(0xFF685D70);
  static const plum = Color(0xFF4E1B59);
  static const line = Color(0xFFECE5E9);
  static const lineStrong = Color(0xFFE9E0E5);
  static const cardShadow = Color(0x0D2C124D);
}

class PlanScreen extends GetView<PlanController> {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageColor = isDark ? AppColors.darkBackground : _PlanUi.page;
    return Scaffold(
      backgroundColor: pageColor,
      body: SafeArea(
        child: GetBuilder<PlanController>(
          builder: (controller) {
            final snapshot = controller.snapshot;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    children: [
                      _PlanHeader(isDark: isDark),
                      const SizedBox(height: 14),
                      _HeroCard(snapshot: snapshot),
                      const SizedBox(height: 14),
                      _AutoRenewStrip(snapshot: snapshot, isDark: isDark),
                      const SizedBox(height: 14),
                      _PrivilegesCard(isDark: isDark),
                      const SizedBox(height: 14),
                      _AccountBindingCard(
                        mobile: controller.accountMobile,
                        isDark: isDark,
                      ),
                      if (controller.errorMessage.value.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          controller.errorMessage.value,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _PlanFooter(
                  isDark: isDark,
                  refreshing: controller.refreshing.value,
                  onRefresh: controller.refreshing.value
                      ? null
                      : controller.refreshPlan,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.darkTextPrimary : _PlanUi.ink;
    final muted = isDark ? AppColors.darkTextSecondary : _PlanUi.muted;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : _PlanUi.lineStrong;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          _ChromeButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => AppFocus.maybePop(context),
            surface: surface,
            border: border,
            child: const _PlanIcon(_PlanIcons.back, width: 11, height: 9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your plan',
                  style: AppTextStyles.appBarTitle.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 22.5 / 18,
                    letterSpacing: -0.45,
                  ),
                ),
                Text(
                  'Subscription & Billing',
                  style: AppTextStyles.caption.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    height: 16.5 / 11,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: surface,
            shape: StadiumBorder(side: BorderSide(color: border)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => Get.toNamed<void>(AppRoutes.about),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 7, 13, 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PlanIcon(_PlanIcons.help, width: 12, height: 12),
                    const SizedBox(width: 6),
                    Text(
                      'Help',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : _PlanUi.plum,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.snapshot});

  final EntitlementSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final paid = snapshot?.isPaid ?? false;
    final days = snapshot?.remainingDays() ?? 0;
    final total = snapshot?.licenseTotalDays ?? 90;
    final progress = snapshot?.licenseProgress() ?? 0;
    final endsAt = snapshot?.trialEndsAt;
    final price = snapshot?.yearlyPriceLabel ?? '₹499/yr';
    final status = paid || days > 0 ? 'ACTIVE' : 'ENDED';
    final licenseLabel = paid ? 'Active License' : 'Trial License';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x4DF59E0B)),
        gradient: const LinearGradient(
          begin: Alignment(-0.72, -1),
          end: Alignment(0.82, 1),
          colors: [Color(0xFF13121D), Color(0xFF1A162B), Color(0xFF25162A)],
          stops: [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x9914101E),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0x26F59E0B),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: const SizedBox(
                width: 144,
                height: 144,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x26F59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: const SizedBox(
                width: 144,
                height: 144,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x33F05A3E),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const _PlanIcon(
                        _PlanIcons.crown,
                        width: 16,
                        height: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            snapshot?.displayTitle ?? 'Creovo Yearly',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              height: 25 / 20,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All-in-one Business Suite',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xCCFDE68A),
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                              height: 15 / 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(11, 5, 11, 5),
                      decoration: BoxDecoration(
                        color: const Color(0x3310B981),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x8034D399)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF6EE7B7),
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              height: 15 / 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: const Color(0x73000000),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'VALIDITY & STATUS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                height: 1.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
                            decoration: BoxDecoration(
                              color: const Color(0xB3022C22),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0x6610B981),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _PlanIcon(
                                  _PlanIcons.checkLicense,
                                  width: 10,
                                  height: 10,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  licenseLabel,
                                  style: AppTextStyles.caption.copyWith(
                                    color: const Color(0xFF34D399),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  days > 0 ? '$days' : (paid ? '—' : '0'),
                                  style: AppTextStyles.displayAmount.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 30,
                                    height: 1,
                                    letterSpacing: -0.75,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      days > 0 || !paid
                                          ? 'Days Remaining'
                                          : 'Yearly license',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption.copyWith(
                                        color: const Color(0xFFFCD34D),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '$days of $total days left',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xE61E293B),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth * progress;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: width < 10 && progress > 0 ? 10 : width,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFBBF24),
                                      Color(0xFFF43F5E),
                                      Color(0xFF34D399),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _PlanIcon(
                            _PlanIcons.calendar,
                            width: 11,
                            height: 12,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '${l10n('Renews')} '),
                                  TextSpan(
                                    text: endsAt == null
                                        ? l10n('yearly')
                                        : DateFormat.yMMMd().format(
                                            endsAt.toLocal(),
                                          ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFFE5E7EB),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                                height: 1,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x26FBBF24),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0x4DFBBF24),
                              ),
                            ),
                            child: Text(
                              price,
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFFFCD34D),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoRenewStrip extends StatelessWidget {
  const _AutoRenewStrip({required this.snapshot, required this.isDark});

  final EntitlementSnapshot? snapshot;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.darkTextPrimary : _PlanUi.ink;
    final muted = isDark ? AppColors.darkTextSecondary : _PlanUi.muted;
    final endsAt = snapshot?.trialEndsAt;
    final price = snapshot?.offerPriceInr ?? 499;
    final nextCharge = endsAt == null
        ? 'Play billing isn’t connected yet.'
        : 'Next charge ₹$price on ${DateFormat.yMMMd().format(endsAt.toLocal())}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : _PlanUi.line),
        boxShadow: const [
          BoxShadow(
            color: _PlanUi.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: const _PlanIcon(_PlanIcons.autorenew, width: 11, height: 11),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Auto-Renewal is Off',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 16 / 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1D5DB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  nextCharge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    height: 15 / 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PillButton(
            label: 'Manage',
            filled: true,
            onPressed: _showManageRenewal,
          ),
        ],
      ),
    );
  }
}

class _PrivilegesCard extends StatelessWidget {
  const _PrivilegesCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.darkTextPrimary : _PlanUi.ink;
    final muted = isDark ? AppColors.darkTextSecondary : _PlanUi.muted;
    const items = [
      _PrivilegeSpec(
        icon: _PlanIcons.gstBills,
        iconBg: Color(0xFFFFEDD5),
        title: 'Unlimited GST Bills',
        subtitle: 'Custom bills & receipts',
      ),
      _PrivilegeSpec(
        icon: _PlanIcons.ledger,
        iconBg: Color(0xFFF3E8FF),
        title: 'Ledger & Khata',
        subtitle: 'Real-time balances',
      ),
      _PrivilegeSpec(
        icon: _PlanIcons.offlineShield,
        iconBg: Color(0xFFFFE4E6),
        title: '100% Offline & Safe',
        subtitle: 'Data stays on this phone',
      ),
      _PrivilegeSpec(
        icon: _PlanIcons.support,
        iconBg: Color(0xFFD1FAE5),
        title: 'Priority Support',
        subtitle: 'WhatsApp helpdesk',
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? AppColors.darkBorder : _PlanUi.line),
        boxShadow: const [
          BoxShadow(
            color: _PlanUi.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAN PRIVILEGES',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : _PlanUi.plum,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        height: 16.5 / 11,
                        letterSpacing: 0.55,
                      ),
                    ),
                    Text(
                      'Included in Creovo Yearly',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        height: 15 / 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PlanIcon(
                      _PlanIcons.checkUnlocked,
                      width: 10,
                      height: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'All Unlocked',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF047857),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        height: 15 / 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PrivilegeTile(
                  spec: items[0],
                  ink: ink,
                  muted: muted,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PrivilegeTile(
                  spec: items[1],
                  ink: ink,
                  muted: muted,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PrivilegeTile(
                  spec: items[2],
                  ink: ink,
                  muted: muted,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PrivilegeTile(
                  spec: items[3],
                  ink: ink,
                  muted: muted,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivilegeSpec {
  const _PrivilegeSpec({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final Color iconBg;
  final String title;
  final String subtitle;
}

class _PrivilegeTile extends StatelessWidget {
  const _PrivilegeTile({
    required this.spec,
    required this.ink,
    required this.muted,
    required this.isDark,
  });

  final _PrivilegeSpec spec;
  final Color ink;
  final Color muted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xCCF8F6F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : _PlanUi.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: spec.iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _PlanIcon(spec.icon, width: 12, height: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xCCD1FAE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _PlanIcon(
                      _PlanIcons.checkActive,
                      width: 7,
                      height: 5,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Active',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF059669),
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        height: 13.5 / 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            spec.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: ink,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              height: 14.38 / 11.5,
            ),
          ),
          Text(
            spec.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: muted,
              fontWeight: FontWeight.w400,
              fontSize: 9.5,
              height: 14.25 / 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBindingCard extends StatelessWidget {
  const _AccountBindingCard({required this.mobile, required this.isDark});

  final String? mobile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pretty = _prettyMobile(mobile);
    final ink = isDark ? AppColors.darkTextPrimary : _PlanUi.ink;
    final muted = isDark ? AppColors.darkTextSecondary : _PlanUi.muted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? AppColors.darkBorder : _PlanUi.line),
        boxShadow: const [
          BoxShadow(
            color: _PlanUi.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCOUNT & DEVICE BINDING',
            style: AppTextStyles.caption.copyWith(
              color: muted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              height: 16.5 / 11,
              letterSpacing: 0.55,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : const Color(0xFFFAF7F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xCCECE5E9),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFEBE4E8),
                    ),
                  ),
                  child: const _PlanIcon(
                    _PlanIcons.phone,
                    width: 10,
                    height: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registered Mobile',
                        style: AppTextStyles.caption.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 9.5,
                          height: 11.88 / 9.5,
                        ),
                      ),
                      Text(
                        pretty ?? 'Verify a number to attach the plan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 16 / 12,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Row(
                        children: [
                          const _PlanIcon(
                            _PlanIcons.checkPrimary,
                            width: 8,
                            height: 8,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'This phone (Primary)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF059669),
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                                height: 13.5 / 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PillButton(
                  label: 'Transfer',
                  filled: false,
                  onPressed: () => AppNotification.info(
                    'Account mobile',
                    'The plan stays on this verified number. Moving it to another phone is not available yet.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _prettyMobile(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return AccountPhone.parseImported(value)?.displayNumber ?? value;
  }
}

class _PlanFooter extends StatelessWidget {
  const _PlanFooter({
    required this.isDark,
    required this.refreshing,
    required this.onRefresh,
  });

  final bool isDark;
  final bool refreshing;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkTextSecondary : _PlanUi.muted;
    final plum = isDark ? AppColors.darkTextPrimary : _PlanUi.plum;
    return ColoredBox(
      color: isDark ? AppColors.darkBackground : _PlanUi.page,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: [
            Material(
              color: isDark ? AppColors.darkSurface : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0x334E1B59),
                ),
              ),
              child: InkWell(
                onTap: onRefresh,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (refreshing)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const _PlanIcon(
                          _PlanIcons.refresh,
                          width: 11,
                          height: 11,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        'Refresh Plan',
                        style: AppTextStyles.caption.copyWith(
                          color: plum,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                _FooterLink(
                  icon: _PlanIcons.whatsapp,
                  iconWidth: 12,
                  iconHeight: 12,
                  label: 'Chat on WhatsApp',
                  color: plum,
                  onTap: () => AppNotification.info(
                    'WhatsApp helpdesk',
                    'Priority WhatsApp support is not connected yet. Use Help for app details.',
                  ),
                ),
                Text(
                  '•',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFD1D5DB),
                    fontSize: 12,
                  ),
                ),
                _FooterLink(
                  icon: _PlanIcons.manage,
                  iconWidth: 12,
                  iconHeight: 11,
                  label: 'Manage Renewal',
                  color: plum,
                  onTap: _showManageRenewal,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _PlanIcon(_PlanIcons.dataShield, width: 11, height: 12),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'All business data is encrypted & stored locally on this phone.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                      height: 15 / 10,
                    ),
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

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.icon,
    required this.iconWidth,
    required this.iconHeight,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String icon;
  final double iconWidth;
  final double iconHeight;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PlanIcon(icon, width: iconWidth, height: iconHeight),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                height: 16 / 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: filled
          ? (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3E8EE))
          : (isDark ? AppColors.darkSurface : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: filled ? const Color(0x1A4E1B59) : const Color(0x404E1B59),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.fromLTRB(11, filled ? 5 : 7, 11, filled ? 5 : 7),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextPrimary : _PlanUi.plum,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 16.5 / 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.onPressed,
    required this.surface,
    required this.border,
    required this.child,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final Color surface;
  final Color border;
  final Widget child;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 36, height: 36, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _PlanIcon extends StatelessWidget {
  const _PlanIcon(this.asset, {required this.width, required this.height});

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(asset, fit: BoxFit.contain),
    );
  }
}

void _showManageRenewal() {
  AppNotification.info(
    'Manage renewal',
    'Yearly billing from Play Store or App Store is not connected yet. Refresh plan to re-check this number.',
  );
}
