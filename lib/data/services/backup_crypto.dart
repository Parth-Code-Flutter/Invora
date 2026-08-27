import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-256-GCM with PBKDF2-HMAC-SHA256. No custom cipher construction.
class BackupCrypto {
  const BackupCrypto();

  static const kdfName = 'pbkdf2-hmac-sha256';
  static const cipherName = 'aes-256-gcm';
  static const iterations = 210000;
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;
  static const _headerLength =
      4 + 1 + 4 + _saltLength + _nonceLength + _macLength;

  static const _magic = [0x43, 0x52, 0x42, 0x32]; // CRB2

  Future<Uint8List> encrypt(List<int> clearBytes, String password) async {
    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    final key = await _key(password, salt);
    final box = await AesGcm.with256bits().encrypt(
      clearBytes,
      secretKey: key,
      nonce: nonce,
    );
    final builder = BytesBuilder(copy: false)
      ..add(_magic)
      ..addByte(1)
      ..add(_uint32(iterations))
      ..add(salt)
      ..add(nonce)
      ..add(box.mac.bytes)
      ..add(box.cipherText);
    return builder.toBytes();
  }

  Future<Uint8List> decrypt(List<int> payload, String password) async {
    if (payload.length < _headerLength) {
      throw const BackupPasswordException(
        'The backup is damaged or unreadable.',
      );
    }
    for (var i = 0; i < _magic.length; i++) {
      if (payload[i] != _magic[i]) {
        throw const BackupPasswordException(
          'The backup is damaged or unreadable.',
        );
      }
    }
    final version = payload[4];
    if (version != 1) {
      throw const BackupPasswordException(
        'Unsupported backup encryption version.',
      );
    }
    final kdfIterations = _readUint32(payload, 5);
    if (kdfIterations < 100000 || kdfIterations > 10000000) {
      throw const BackupPasswordException(
        'The backup is damaged or unreadable.',
      );
    }
    var offset = 9;
    final salt = payload.sublist(offset, offset + _saltLength);
    offset += _saltLength;
    final nonce = payload.sublist(offset, offset + _nonceLength);
    offset += _nonceLength;
    final mac = payload.sublist(offset, offset + _macLength);
    offset += _macLength;
    final cipherText = payload.sublist(offset);
    final key = await _key(password, salt, iterations: kdfIterations);
    try {
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
      );
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw const BackupPasswordException('Wrong backup password.');
    }
  }

  Future<SecretKey> _key(
    String password,
    List<int> salt, {
    int iterations = BackupCrypto.iterations,
  }) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  List<int> _uint32(int value) => [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ];

  int _readUint32(List<int> bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

class BackupPasswordException implements Exception {
  const BackupPasswordException(this.message);
  final String message;

  @override
  String toString() => message;
}
