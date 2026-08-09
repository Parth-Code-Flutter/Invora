import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/app_storage.dart';
import '../constants/app_storage_key_const.dart';

class AppController extends GetxController {
  AppController(this._storage);

  final AppStorage _storage;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  bool get isDarkMode {
    final mode = themeMode.value;
    if (mode == ThemeMode.system) {
      return Get.context == null
          ? false
          : MediaQuery.platformBrightnessOf(Get.context!) == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    await _storage.setBool(AppStorageKeyConst.isDarkMode, enabled);
  }

  Future<void> useSystemTheme() async {
    themeMode.value = ThemeMode.system;
    await _storage.remove(AppStorageKeyConst.isDarkMode);
  }

  void _loadThemeMode() {
    final storedValue = _storage.getBool(AppStorageKeyConst.isDarkMode);
    if (storedValue != null) {
      themeMode.value = storedValue ? ThemeMode.dark : ThemeMode.light;
    }
  }
}
