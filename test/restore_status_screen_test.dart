import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/modules/backup_restore/screens/restore_status_screen.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('runs restore after entering the isolated status screen', (
    tester,
  ) async {
    String? restoredPath;
    var reloaded = false;
    var continued = false;

    await tester.pumpWidget(
      GetMaterialApp(
        home: RestoreStatusScreen(
          path: '/tmp/backup.zip',
          startDelay: Duration.zero,
          restoreOperation: (path) async => restoredPath = path,
          reloadOperation: () async => reloaded = true,
          onContinue: () => continued = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(restoredPath, '/tmp/backup.zip');
    expect(reloaded, isTrue);
    expect(find.text('Restore complete'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    expect(continued, isTrue);
  });

  testWidgets('keeps users off database screens when restore fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: RestoreStatusScreen(
          path: '/tmp/invalid.zip',
          startDelay: Duration.zero,
          restoreOperation: (_) async => throw StateError('Invalid backup'),
          reloadOperation: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restore needs attention'), findsOneWidget);
    expect(find.text('Invalid backup'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
