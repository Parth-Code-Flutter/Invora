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
    final managed = _storage.getStringList(AppStorageKeyConst.managedUnits);
    if (managed != null && managed.isNotEmpty) return managed;
    final custom = _storage.getStringList(AppStorageKeyConst.customUnits) ?? [];
    return {...defaultUnits, ...custom}.toList(growable: false);
  }

  String get defaultUnit {
    final stored = _storage.getString(AppStorageKeyConst.defaultUnit);
    return stored != null && units.contains(stored) ? stored : units.first;
  }

  Future<String> create(String input) async {
    final value = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) throw ArgumentError('Unit name cannot be empty.');
    final existing = units.where(
      (unit) => unit.toLowerCase() == value.toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first;
    final custom = [...units, value];
    await _saveUnits(custom);
    return value;
  }

  Future<String> rename(String current, String input) async {
    final value = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) throw ArgumentError('Unit name cannot be empty.');
    final duplicate = units.any(
      (unit) => unit.toLowerCase() == value.toLowerCase() && unit != current,
    );
    if (duplicate) throw ArgumentError('A unit with this name already exists.');
    final wasDefault = defaultUnit == current;
    final updated = units
        .map((unit) => unit == current ? value : unit)
        .toList(growable: false);
    await _saveUnits(updated);
    if (wasDefault) await setDefault(value);
    return value;
  }

  Future<void> delete(String unit) async {
    if (units.length == 1) {
      throw StateError('Keep at least one unit available.');
    }
    final wasDefault = defaultUnit == unit;
    final updated = units.where((value) => value != unit).toList();
    await _saveUnits(updated);
    if (wasDefault) await setDefault(updated.first);
  }

  Future<void> setDefault(String unit) async {
    if (!units.contains(unit)) throw ArgumentError('Unit does not exist.');
    await _storage.setString(AppStorageKeyConst.defaultUnit, unit);
  }

  Future<void> _saveUnits(List<String> values) =>
      _storage.setStringList(AppStorageKeyConst.managedUnits, values);
}
