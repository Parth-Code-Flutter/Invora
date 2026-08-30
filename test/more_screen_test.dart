import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/repositories/business_repository.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/business_workspace_service.dart';
import 'package:creovo_invoice/modules/settings/controllers/more_controller.dart';
import 'package:creovo_invoice/modules/settings/more_destinations.dart';
import 'package:creovo_invoice/modules/settings/screens/more_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('filterMoreDestinations', () {
    test('keeps stock destinations hidden until a product tracks stock', () {
      final hidden = filterMoreDestinations(query: '', stockEnabled: false);
      expect(_titles(hidden), isNot(contains('Stock')));
      expect(_titles(hidden), isNot(contains('Stock reports')));

      final shown = filterMoreDestinations(query: 'stock', stockEnabled: true);
      expect(_titles(shown), containsAll(['Stock', 'Stock reports']));
    });

    test('matches titles, aliases, and section labels', () {
      final gst = filterMoreDestinations(query: 'gst', stockEnabled: false);
      expect(_titles(gst), ['GST / CA export']);

      final lock = filterMoreDestinations(query: 'lock', stockEnabled: false);
      expect(_titles(lock), ['App settings']);

      final erase = filterMoreDestinations(query: 'erase', stockEnabled: false);
      expect(_titles(erase), ['Backup & restore']);

      final create = filterMoreDestinations(
        query: 'create & manage',
        stockEnabled: false,
      );
      expect(create, hasLength(1));
      expect(create.single.label, 'Create & manage');
      expect(_titles(create), isNot(contains('Stock')));
    });

    test('returns no groups when nothing matches', () {
      expect(
        filterMoreDestinations(query: 'zzzz', stockEnabled: true),
        isEmpty,
      );
    });
  });

  group('MoreScreen search', () {
    late AppDatabase database;

    setUp(() async {
      Get.testMode = true;
      SharedPreferences.setMockInitialValues({});
      database = AppDatabase.forTesting(NativeDatabase.memory());
      Get.put(BusinessWorkspaceService(await AppStorage.create()));
      Get.put(MoreController(BusinessRepository(database)));
    });

    tearDown(() async {
      Get.reset();
      await database.close();
    });

    testWidgets('filters destinations from the AppBar search', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GetMaterialApp(theme: AppTheme.light, home: const MoreScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('More'), findsWidgets);
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('App settings'), findsOneWidget);

      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      expect(find.text('Search features'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'GST');
      await tester.pump();

      expect(find.text('GST / CA export'), findsOneWidget);
      expect(find.text('Sales'), findsNothing);
      expect(find.text('App settings'), findsNothing);
      expect(
        find.text('Private by design. Your data stays on this device.'),
        findsNothing,
      );

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();

      expect(find.text('No matching features'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('App settings'), findsOneWidget);
    });
  });
}

List<String> _titles(List<MoreDestinationGroup> groups) => [
  for (final group in groups)
    for (final item in group.items) item.title,
];
