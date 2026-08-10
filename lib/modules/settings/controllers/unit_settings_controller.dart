import 'package:get/get.dart';

import '../../../data/services/unit_service.dart';

class UnitSettingsController extends GetxController {
  UnitSettingsController(this._service);

  final UnitService _service;
  final units = <String>[].obs;
  final selectedDefault = ''.obs;

  @override
  void onInit() {
    super.onInit();
    refreshUnits();
  }

  void refreshUnits() {
    units.assignAll(_service.units);
    selectedDefault.value = _service.defaultUnit;
  }

  Future<String?> create(String value) async {
    try {
      await _service.create(value);
      refreshUnits();
      return null;
    } on ArgumentError catch (error) {
      return _message(error);
    }
  }

  Future<String?> rename(String current, String value) async {
    try {
      await _service.rename(current, value);
      refreshUnits();
      return null;
    } on ArgumentError catch (error) {
      return _message(error);
    }
  }

  Future<String?> delete(String unit) async {
    try {
      await _service.delete(unit);
      refreshUnits();
      return null;
    } on StateError catch (error) {
      return error.message;
    }
  }

  Future<void> setDefault(String unit) async {
    await _service.setDefault(unit);
    selectedDefault.value = unit;
  }

  String _message(ArgumentError error) =>
      error.message?.toString() ?? 'Enter a valid unit name.';
}
