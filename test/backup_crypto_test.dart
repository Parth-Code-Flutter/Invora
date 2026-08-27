import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/services/backup_crypto.dart';

void main() {
  test('round-trips bytes and rejects the wrong password', () async {
    const crypto = BackupCrypto();
    final clear = List<int>.generate(64, (index) => index);
    final payload = await crypto.encrypt(clear, 'correct horse');

    expect(payload.sublist(0, 4), [0x43, 0x52, 0x42, 0x32]);
    expect(await crypto.decrypt(payload, 'correct horse'), clear);
    await expectLater(
      crypto.decrypt(payload, 'wrong-pass'),
      throwsA(
        isA<BackupPasswordException>().having(
          (error) => error.message,
          'message',
          contains('Wrong backup password'),
        ),
      ),
    );
  });
}
