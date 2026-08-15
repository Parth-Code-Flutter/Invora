import 'package:get/get.dart';

import '../../app/constants/app_storage_key_const.dart';
import 'app_storage.dart';

enum BusinessWorkspace { sales, purchases }

class BusinessWorkspaceService extends GetxService {
  BusinessWorkspaceService(this._storage) {
    final fallback = _decode(
      _storage.getString(AppStorageKeyConst.defaultWorkspace),
    );
    defaultWorkspace.value = fallback;
    activeWorkspace.value = _decode(
      _storage.getString(AppStorageKeyConst.activeWorkspace),
      fallback: fallback,
    );
  }

  final AppStorage _storage;
  final defaultWorkspace = BusinessWorkspace.sales.obs;
  final activeWorkspace = BusinessWorkspace.sales.obs;

  bool get isSales => activeWorkspace.value == BusinessWorkspace.sales;
  bool get isPurchases => activeWorkspace.value == BusinessWorkspace.purchases;

  void reload() {
    final fallback = _decode(
      _storage.getString(AppStorageKeyConst.defaultWorkspace),
    );
    defaultWorkspace.value = fallback;
    activeWorkspace.value = _decode(
      _storage.getString(AppStorageKeyConst.activeWorkspace),
      fallback: fallback,
    );
  }

  Future<void> select(BusinessWorkspace workspace) async {
    activeWorkspace.value = workspace;
    await _storage.setString(
      AppStorageKeyConst.activeWorkspace,
      workspace.name,
    );
  }

  Future<void> setInitial(BusinessWorkspace workspace) async {
    defaultWorkspace.value = workspace;
    activeWorkspace.value = workspace;
    await Future.wait([
      _storage.setString(AppStorageKeyConst.defaultWorkspace, workspace.name),
      _storage.setString(AppStorageKeyConst.activeWorkspace, workspace.name),
    ]);
  }

  Future<void> setDefault(BusinessWorkspace workspace) async {
    defaultWorkspace.value = workspace;
    await _storage.setString(
      AppStorageKeyConst.defaultWorkspace,
      workspace.name,
    );
  }

  static BusinessWorkspace _decode(
    String? value, {
    BusinessWorkspace fallback = BusinessWorkspace.sales,
  }) =>
      BusinessWorkspace.values.firstWhereOrNull(
        (workspace) => workspace.name == value,
      ) ??
      fallback;
}
