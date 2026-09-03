import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'account_phone.dart';

abstract class DeviceAccountNumbers {
  Future<List<DeviceAccountNumber>> load();

  Future<DeviceAccountNumber?> pickFromContacts();
}

class EmptyDeviceAccountNumbers implements DeviceAccountNumbers {
  const EmptyDeviceAccountNumbers();

  @override
  Future<List<DeviceAccountNumber>> load() async => const [];

  @override
  Future<DeviceAccountNumber?> pickFromContacts() async => null;
}

class ContactsDeviceAccountNumbers implements DeviceAccountNumbers {
  const ContactsDeviceAccountNumbers();

  static const _phoneProperties = {ContactProperty.phone};

  @override
  Future<List<DeviceAccountNumber>> load() async {
    if (_runningUnderTest) return const [];
    try {
      final allowed = await _ensurePermission();
      if (!allowed) return const [];

      final unique = <String, DeviceAccountNumber>{};
      void addContact(Contact? contact, {String fallbackLabel = ''}) {
        if (contact == null) return;
        final label = (contact.displayName ?? '').trim();
        for (final phone in contact.phones) {
          final parsed = AccountPhone.parseImported(phone.number);
          if (parsed == null) continue;
          unique.putIfAbsent(
            parsed.e164,
            () => DeviceAccountNumber(
              national: parsed.national,
              country: parsed.country,
              label: label.isEmpty ? fallbackLabel : label,
            ),
          );
        }
      }

      try {
        final profile = await FlutterContacts.profile.get(
          properties: _phoneProperties,
        );
        addContact(profile, fallbackLabel: 'This phone');
      } catch (_) {}

      try {
        final simContacts = await FlutterContacts.sim.get();
        for (final contact in simContacts) {
          addContact(contact, fallbackLabel: 'SIM');
        }
      } catch (_) {}

      try {
        final saved = await FlutterContacts.getAll(
          properties: _phoneProperties,
          limit: 80,
        );
        for (final contact in saved) {
          addContact(contact);
        }
      } catch (_) {}

      return unique.values.take(8).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<DeviceAccountNumber?> pickFromContacts() async {
    if (_runningUnderTest) return null;
    final allowed = await _ensurePermission();
    if (!allowed) {
      throw const DeviceAccountNumbersException(
        'Contacts permission needed',
        'Allow contacts to fill a number saved on this phone.',
      );
    }
    try {
      final contact = await FlutterContacts.native.showPicker(
        properties: _phoneProperties,
      );
      if (contact == null) return null;
      if (contact.phones.isEmpty) {
        throw const DeviceAccountNumbersException(
          'No mobile number',
          'The selected contact does not have a phone number.',
        );
      }
      final parsed = AccountPhone.parseImported(contact.phones.first.number);
      if (parsed == null) {
        throw const DeviceAccountNumbersException(
          'Unsupported number',
          'Choose a contact with a valid mobile number.',
        );
      }
      final label = (contact.displayName ?? '').trim();
      return DeviceAccountNumber(
        national: parsed.national,
        country: parsed.country,
        label: label,
      );
    } on DeviceAccountNumbersException {
      rethrow;
    } on PlatformException {
      throw const DeviceAccountNumbersException(
        'Could not open contacts',
        'Check contact permission in device settings and try again.',
      );
    }
  }

  Future<bool> _ensurePermission() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  static bool get _runningUnderTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }
}

class DeviceAccountNumbersException implements Exception {
  const DeviceAccountNumbersException(this.title, this.message);

  final String title;
  final String message;
}
