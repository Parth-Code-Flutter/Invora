import '../../app/constants/app_storage_key_const.dart';
import 'app_storage.dart';

class UnitService {
  UnitService(this._storage);

  static const defaultUnits = <String>[
    'pcs',
    'box',
    'set',
    'pair',
    'kg',
    'g',
    'ltr',
    'ml',
    'meter',
    'sq ft',
    'hour',
    'day',
    'service',
  ];

  final AppStorage _storage;

  List<String> get units {
    final custom = _storage.getStringList(AppStorageKeyConst.customUnits) ?? [];
    return {...defaultUnits, ...custom}.toList(growable: false);
  }

  Future<String> create(String input) async {
    final value = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) throw ArgumentError('Unit name cannot be empty.');
    final existing = units.where(
      (unit) => unit.toLowerCase() == value.toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first;
    final custom = [
      ...?_storage.getStringList(AppStorageKeyConst.customUnits),
      value,
    ];
    await _storage.setStringList(AppStorageKeyConst.customUnits, custom);
    return value;
  }
}
