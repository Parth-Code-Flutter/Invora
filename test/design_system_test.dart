import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/constants/app_colors.dart';
import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/app/themes/app_text_styles.dart';
import 'package:creovo_invoice/app/widgets/app_module_banner.dart';
import 'package:creovo_invoice/app/widgets/app_pair_tabs.dart';
import 'package:creovo_invoice/app/widgets/app_search_app_bar.dart';
import 'package:creovo_invoice/app/utils/app_focus.dart';
import 'package:creovo_invoice/app/widgets/app_back_button.dart';
import 'package:creovo_invoice/app/widgets/app_button.dart';
import 'package:creovo_invoice/app/widgets/app_dropdown_field.dart';
import 'package:creovo_invoice/app/widgets/app_filter_chip.dart';
import 'package:creovo_invoice/app/widgets/app_search_field.dart';
import 'package:creovo_invoice/app/widgets/app_status_chip.dart';
import 'package:creovo_invoice/app/widgets/app_text_field.dart';
import 'package:creovo_invoice/app/widgets/app_empty_state.dart';

void _ignoreTab(int _) {}

void main() {
  test('design system uses the bundled Plus Jakarta Sans family', () {
    expect(AppTextStyles.fontFamily, 'Plus Jakarta Sans');
    expect(
      AppTheme.light.textTheme.bodyMedium?.fontFamily,
      'Plus Jakarta Sans',
    );
  });

  testWidgets('empty state uses an illustration instead of a glyph well', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppEmptyState(
            illustration: AppEmptyIllustration.invoice,
            title: 'No invoices yet',
            message: 'Create your first offline invoice to see it here.',
            actionLabel: 'Create invoice',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(find.byType(AppEmptyArt), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsNothing);
    expect(find.text('No invoices yet'), findsOneWidget);
    expect(find.text('Create invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared segment tabs use one branded selector and icons', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppSegmentTabs(
              labels: const ['Sales', 'Purchases'],
              icons: const [
                Icons.receipt_long_outlined,
                Icons.shopping_bag_outlined,
              ],
              index: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    final indicator = tester.widget<AnimatedPositioned>(
      find.byKey(const ValueKey('app-segment-indicator')),
    );
    final decoration =
        (indicator.child as DecoratedBox).decoration as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, Colors.white);
    expect(decoration.boxShadow, isNotEmpty);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);

    final pillRect = tester.getRect(
      find.byKey(const ValueKey('app-segment-indicator')),
    );
    expect(
      tester.getRect(find.text('Sales')).center.dy,
      closeTo(pillRect.center.dy, 1.5),
    );
    expect(
      tester.getRect(find.byIcon(Icons.receipt_long_outlined)).center.dy,
      closeTo(pillRect.center.dy, 2),
    );

    await tester.tap(find.text('Purchases'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog segment tabs stay readable on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppSegmentTabs(
            labels: const ['All', 'Products', 'Services'],
            icons: const [
              Icons.grid_view_rounded,
              Icons.inventory_2_outlined,
              Icons.design_services_outlined,
            ],
            counts: const [12, 8, 4],
            index: 0,
            onChanged: _ignoreTab,
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary action uses branded surface and loading semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            label: 'Save customer',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    final decoration =
        tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
                .decoration
            as BoxDecoration;
    expect(decoration.gradient, isA<LinearGradient>());
    expect(find.byKey(const ValueKey('app-button-loader')), findsOneWidget);
  });

  testWidgets('primary action keeps a long label inside narrow bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 190,
              child: AppButton(
                label: 'Review invoice before saving',
                icon: Icons.visibility_outlined,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppButton)).width, 190);
  });

  testWidgets('primary action supports an icon after its label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(
            label: 'Review invoice',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getCenter(find.text('Review invoice')).dx,
      lessThan(tester.getCenter(find.byIcon(Icons.arrow_forward_rounded)).dx),
    );
  });

  testWidgets('shared dropdown uses a selectable bottom sheet', (tester) async {
    String selected = 'UPI';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppDropdownField<String>(
            label: 'Payment method',
            sheetTitle: 'Choose payment method',
            value: selected,
            options: const [
              AppDropdownOption(
                value: 'UPI',
                label: 'UPI',
                icon: Icons.qr_code_2_rounded,
              ),
              AppDropdownOption(
                value: 'Cash',
                label: 'Cash',
                icon: Icons.payments_outlined,
              ),
            ],
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('UPI'));
    await tester.pumpAndSettle();
    expect(find.text('Choose payment method'), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);

    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();
    expect(selected, 'Cash');
  });

  testWidgets('searchable dropdown filters a fixed-height option sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppDropdownField<String>(
            label: 'Business category',
            sheetTitle: 'Choose your business category',
            value: 'General Business',
            searchable: true,
            sheetHeightFactor: .75,
            options: const [
              AppDropdownOption(
                value: 'General Business',
                label: 'General Business',
              ),
              AppDropdownOption(value: 'Electronics', label: 'Electronics'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('General Business'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Search categories'), findsOneWidget);
    final sheet = find.byType(BottomSheet);
    expect(tester.getSize(sheet).height, greaterThan(490));

    await tester.enterText(find.byType(TextField), 'elect');
    await tester.pump();
    expect(
      find.descendant(of: sheet, matching: find.text('Electronics')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('General Business')),
      findsNothing,
    );
  });

  testWidgets('shared fields and status chip expose clear semantics', (
    tester,
  ) async {
    final textController = TextEditingController();
    addTearDown(textController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              AppSearchField(hint: 'Search invoices', onChanged: (_) {}),
              AppTextField(
                controller: textController,
                label: 'Business name',
                hint: 'Enter business name',
              ),
              const AppStatusChip(status: InvoiceStatus.partiallyPaid),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Business name'), findsOneWidget);
    expect(find.text('Partially paid'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AppStatusChip)),
      matchesSemantics(label: 'Status: Partially paid'),
    );
  });

  testWidgets('module banner stays usable on a narrow phone', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: AppModuleBanner(
                title: 'Your money timeline',
                subtitle: 'Create quickly and see what is paid or still due.',
                icon: Icons.receipt_long_outlined,
                colors: const [AppColors.secondary, AppColors.primary],
                actionLabel: 'New invoice',
                onAction: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Your money timeline'), findsOneWidget);
    expect(find.byTooltip('New invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter and back controls expose clear interaction states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: const Text('Filtered list'),
          ),
          body: AppFilterChip(
            label: 'Paid',
            icon: Icons.check_circle_outline,
            selected: true,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(tester.getSize(find.byType(IconButton).first), const Size(48, 48));
    expect(
      AppTheme.light.appBarTheme.titleTextStyle?.fontSize,
      AppTextStyles.appBarTitle.fontSize,
    );
    expect(find.text('Paid'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AppFilterChip)),
      matchesSemantics(
        label: 'Paid filter',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
  });

  testWidgets('filter chip label and count share a midline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: AppFilterChip(
              label: 'All',
              count: 0,
              selected: true,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getRect(find.text('All')).center.dy,
      closeTo(tester.getRect(find.text('0')).center.dy, 1.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppBar search expands, updates, and clears the query', (
    tester,
  ) async {
    final queries = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: AppSearchAppBar(
            title: 'Customers',
            hint: 'Name or mobile',
            onChanged: queries.add,
          ),
        ),
      ),
    );

    expect(find.text('Customers'), findsOneWidget);
    expect(find.byTooltip('Scan to search'), findsNothing);
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.getSize(find.byType(TextField)).height, 46);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.fillColor, AppColors.surfaceMuted);
    final focused = field.decoration?.focusedBorder as OutlineInputBorder;
    expect(focused.borderSide.color, AppColors.secondary);
    expect(focused.borderRadius.topLeft.x, 12);

    await tester.enterText(find.byType(TextField), 'Asha');
    await tester.pump();
    expect(queries.last, 'Asha');
    expect(find.byTooltip('Clear search'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(queries.last, isEmpty);

    await tester.enterText(find.byType(TextField), 'Asha');
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    expect(find.text('Customers'), findsOneWidget);
    expect(queries.last, isEmpty);
  });

  testWidgets(
    'AppBar scan sits beside search and never enters the text field',
    (tester) async {
      final queries = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            appBar: AppSearchAppBar(
              title: 'Invoices',
              hint: 'Invoice or customer',
              onChanged: queries.add,
              onScan: () async => 'INV-204',
              actions: [
                IconButton(
                  tooltip: 'Sort invoices',
                  onPressed: () {},
                  icon: const Icon(Icons.swap_vert_rounded),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byTooltip('Scan to search'), findsOneWidget);
      await tester.tap(find.byTooltip('Scan to search'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('INV-204'), findsOneWidget);
      expect(queries.last, 'INV-204');
      expect(find.byTooltip('Clear search'), findsOneWidget);
      expect(find.byTooltip('Scan to search'), findsNothing);
      expect(find.byTooltip('Close search'), findsOneWidget);
      expect(find.byTooltip('Sort invoices'), findsOneWidget);
      expect(find.byTooltip('Search'), findsNothing);
    },
  );

  testWidgets('focused text overlay closes after caret work is settled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                content: const TextField(autofocus: true),
                actions: [
                  TextButton(
                    onPressed: () => AppFocus.pop(dialogContext),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            child: const Text('Open input'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open input'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
