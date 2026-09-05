import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/network/api_client.dart';
import '../domain/app_update_model.dart';
import '../presentation/app_update_dialog.dart';

class AppUpdateService {
  final ApiClient _apiClient;
  bool _isDialogShowing = false;

  AppUpdateService(this._apiClient);

  Future<AppUpdateModel?> fetchVersionCheck() async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final response = await _apiClient.dio.get(
        '/app-config/version-check',
        queryParameters: {'platform': platform},
      );
      if (response.data != null && response.data is Map) {
        return AppUpdateModel.fromJson(Map<String, dynamic>.from(response.data));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> checkAndShowUpdateDialog(
    BuildContext context, {
    bool isManualCheck = false,
  }) async {
    if (_isDialogShowing) return;

    try {
      final updateModel = await fetchVersionCheck();
      if (updateModel == null || !context.mounted) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final isForce = updateModel.isForceRequired(currentVersion);
      final isAvailable = updateModel.isUpdateAvailable(currentVersion);

      if (isForce || isAvailable || isManualCheck) {
        if (!context.mounted) return;

        _isDialogShowing = true;
        await AppUpdateDialog.show(
          context: context,
          updateInfo: updateModel,
          isForceUpdate: isForce,
          currentVersion: currentVersion,
        );
        _isDialogShowing = false;
      }
    } catch (_) {
      _isDialogShowing = false;
    }
  }
}

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AppUpdateService(client);
});
