class AppUpdateModel {
  final String platform;
  final String latestVersion;
  final String minVersion;
  final bool forceUpdate;
  final String title;
  final String message;
  final String updateUrl;

  const AppUpdateModel({
    required this.platform,
    required this.latestVersion,
    required this.minVersion,
    required this.forceUpdate,
    required this.title,
    required this.message,
    required this.updateUrl,
  });

  factory AppUpdateModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateModel(
      platform: json['platform']?.toString() ?? 'android',
      latestVersion: json['latestVersion']?.toString() ?? '1.0.0',
      minVersion: json['minVersion']?.toString() ?? '1.0.0',
      forceUpdate: json['forceUpdate'] == true || json['forceUpdate'] == 'true',
      title: json['title']?.toString() ?? 'নতুন আপডেট উপলব্ধ!',
      message: json['message']?.toString() ??
          'অ্যাপটি নিরবচ্ছিন্নভাবে ব্যবহার করতে অনুগ্রহ করে এখনই আপডেট করুন।',
      updateUrl: json['updateUrl']?.toString() ??
          'https://play.google.com/store/apps/details?id=com.progga.app',
    );
  }

  /// Returns true if force update is explicitly enabled on backend
  /// OR current app version is strictly lower than minVersion.
  bool isForceRequired(String currentVersion) {
    if (forceUpdate) return true;
    if (_isVersionLower(currentVersion, minVersion)) return true;
    return false;
  }

  /// Returns true if a newer version is available on the server.
  bool isUpdateAvailable(String currentVersion) {
    if (forceUpdate) return true;
    if (_isVersionLower(currentVersion, latestVersion)) return true;
    return false;
  }

  /// Semantic version comparison (e.g. "1.0.11" vs "1.0.12")
  static bool _isVersionLower(String current, String target) {
    try {
      final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final tParts = target.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final len = cParts.length > tParts.length ? cParts.length : tParts.length;
      for (int i = 0; i < len; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final t = i < tParts.length ? tParts[i] : 0;
        if (c < t) return true;
        if (c > t) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

