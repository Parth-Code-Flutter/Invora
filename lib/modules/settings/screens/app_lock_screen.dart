import 'package:flutter/material.dart' hide Text;
import 'package:get/get.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/localization/localized_text.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/widgets/app_back_button.dart';
import '../../../app/widgets/app_button.dart';
import '../../../app/widgets/app_card.dart';
import '../../../data/services/app_lock_service.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.service, required this.child, super.key});

  final AppLockService service;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  var _leftForeground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _leftForeground = true;
    } else if (state == AppLifecycleState.resumed && _leftForeground) {
      _leftForeground = false;
      widget.service.lock();
    }
  }

  @override
  Widget build(BuildContext context) => Obx(
    () => Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!widget.service.isUnlocked)
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const _UnlockView(),
          ),
      ],
    ),
  );
}

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  final service = Get.find<AppLockService>();
  var _mode = _LockSettingsMode.overview;
  String? _firstPin;
  String? _error;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: _mode == _LockSettingsMode.overview
          ? const AppBackButton()
          : AppBackButton(onPressed: _reset),
      title: AppBarTitle(_title),
    ),
    body: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _mode == _LockSettingsMode.overview
          ? _overview(context)
          : _PinEntryView(
              key: ValueKey(_mode),
              title: _entryTitle,
              subtitle: _entrySubtitle,
              error: _error,
              onCompleted: _handlePin,
            ),
    ),
  );

  Widget _overview(BuildContext context) => ListView(
    key: const ValueKey('overview'),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    children: [
      AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 29,
              ),
            ),
            const SizedBox(height: 14),
            Obx(
              () => Text(
                service.isEnabled ? 'App lock is on' : 'Protect your app',
                style: AppTextStyles.sectionTitle,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Require a four-digit PIN when Creovo Billing opens or returns from the background.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Obx(
        () => service.isEnabled
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: 'Change PIN',
                    icon: Icons.password_rounded,
                    onPressed: () => _start(_LockSettingsMode.verifyForChange),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _start(_LockSettingsMode.verifyForDisable),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Disable app lock'),
                  ),
                ],
              )
            : AppButton(
                label: 'Set up PIN',
                icon: Icons.lock_rounded,
                onPressed: () => _start(_LockSettingsMode.create),
              ),
      ),
      const SizedBox(height: 16),
      Text(
        'Your PIN protects access to this app on this device. It does not encrypt exported files or backups.',
        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
        textAlign: TextAlign.center,
      ),
    ],
  );

  String get _title => switch (_mode) {
    _LockSettingsMode.overview => 'App lock',
    _LockSettingsMode.create => 'Create PIN',
    _LockSettingsMode.confirm => 'Confirm PIN',
    _LockSettingsMode.verifyForChange ||
    _LockSettingsMode.verifyForDisable => 'Verify PIN',
  };

  String get _entryTitle => switch (_mode) {
    _LockSettingsMode.create => 'Choose a four-digit PIN',
    _LockSettingsMode.confirm => 'Enter the PIN again',
    _ => 'Enter your current PIN',
  };

  String get _entrySubtitle => switch (_mode) {
    _LockSettingsMode.create => 'Use a PIN you can remember.',
    _LockSettingsMode.confirm => 'This makes sure you entered it correctly.',
    _LockSettingsMode.verifyForDisable => 'Verify before turning off app lock.',
    _ => 'Verify before choosing a new PIN.',
  };

  void _start(_LockSettingsMode mode) => setState(() {
    _mode = mode;
    _firstPin = null;
    _error = null;
  });

  void _reset() => setState(() {
    _mode = _LockSettingsMode.overview;
    _firstPin = null;
    _error = null;
  });

  Future<void> _handlePin(String pin) async {
    if (_mode == _LockSettingsMode.create) {
      setState(() {
        _firstPin = pin;
        _mode = _LockSettingsMode.confirm;
        _error = null;
      });
      return;
    }
    if (_mode == _LockSettingsMode.confirm) {
      if (pin != _firstPin) {
        setState(() => _error = 'PINs do not match. Try again.');
        return;
      }
      await service.setPin(pin);
      if (mounted) _reset();
      return;
    }
    if (!service.verifyPin(pin)) {
      setState(() => _error = 'Incorrect PIN. Try again.');
      return;
    }
    if (_mode == _LockSettingsMode.verifyForDisable) {
      await service.disable(pin);
      if (mounted) _reset();
      return;
    }
    setState(() {
      _firstPin = null;
      _mode = _LockSettingsMode.create;
      _error = null;
    });
  }
}

class _UnlockView extends StatefulWidget {
  const _UnlockView();

  @override
  State<_UnlockView> createState() => _UnlockViewState();
}

class _UnlockViewState extends State<_UnlockView> {
  String? _error;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: SafeArea(
      child: _PinEntryView(
        title: 'Welcome back',
        subtitle: 'Enter your PIN to unlock Creovo Billing.',
        error: _error,
        icon: Icons.lock_rounded,
        onCompleted: (pin) {
          if (!Get.find<AppLockService>().unlock(pin)) {
            setState(() => _error = 'Incorrect PIN. Try again.');
          }
        },
      ),
    ),
  );
}

class _PinEntryView extends StatefulWidget {
  const _PinEntryView({
    required this.title,
    required this.subtitle,
    required this.onCompleted,
    this.error,
    this.icon = Icons.password_rounded,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? error;
  final IconData icon;
  final ValueChanged<String> onCompleted;

  @override
  State<_PinEntryView> createState() => _PinEntryViewState();
}

class _PinEntryViewState extends State<_PinEntryView> {
  var _pin = '';

  @override
  void didUpdateWidget(covariant _PinEntryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != oldWidget.error && widget.error != null) _pin = '';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
    child: Column(
      children: [
        const Spacer(),
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, color: Colors.white, size: 31),
        ),
        const SizedBox(height: 20),
        Text(widget.title, style: AppTextStyles.pageTitle),
        const SizedBox(height: 7),
        Text(
          widget.subtitle,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: index < _pin.length
                    ? AppColors.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.error == null
                      ? AppColors.primary
                      : AppColors.error,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: widget.error == null
              ? null
              : Center(
                  child: Text(
                    widget.error!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
        ),
        _PinKeypad(onDigit: _addDigit, onDelete: _deleteDigit),
        const Spacer(),
      ],
    ),
  );

  void _addDigit(String digit) {
    if (_pin.length == 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) {
      final completed = _pin;
      Future<void>.delayed(const Duration(milliseconds: 110), () {
        if (!mounted) return;
        setState(() => _pin = '');
        widget.onCompleted(completed);
      });
    }
  }

  void _deleteDigit() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }
}

class _PinKeypad extends StatelessWidget {
  const _PinKeypad({required this.onDigit, required this.onDelete});

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 310),
    child: Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row.map((digit) => _key(context, digit)).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 70, height: 62),
            _key(context, '0'),
            SizedBox(
              width: 70,
              height: 62,
              child: Semantics(
                button: true,
                label: l10n('Delete digit'),
                child: IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _key(BuildContext context, String digit) => SizedBox(
    width: 70,
    height: 62,
    child: TextButton(
      onPressed: () => onDigit(digit),
      child: Text(
        digit,
        style: AppTextStyles.pageTitle.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

enum _LockSettingsMode {
  overview,
  create,
  confirm,
  verifyForChange,
  verifyForDisable,
}
