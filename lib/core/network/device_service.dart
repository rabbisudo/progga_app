import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceMetadata {
  final String appVersion;
  final String buildNumber;
  final String osName;
  final String osVersion;
  final String deviceModel;
  final String manufacturer;
  final String userAgent;

  const DeviceMetadata({
    required this.appVersion,
    required this.buildNumber,
    required this.osName,
    required this.osVersion,
    required this.deviceModel,
    required this.manufacturer,
    required this.userAgent,
  });
}

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<DeviceMetadata> getDeviceMetadata() async {
    String appVersion = '1.0.0';
    String buildNumber = '1';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    } catch (_) {}

    String osName = Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : Platform.operatingSystem;
    String osVersion = Platform.operatingSystemVersion;
    String deviceModel = 'Mobile';
    String manufacturer = 'Generic';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
        deviceModel = _sanitizeHeader(androidInfo.model);
        manufacturer = _sanitizeHeader(androidInfo.manufacturer);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        osVersion = 'iOS ${iosInfo.systemVersion}';
        deviceModel = _sanitizeHeader(iosInfo.utsname.machine.isNotEmpty ? iosInfo.utsname.machine : iosInfo.model);
        manufacturer = 'Apple';
      }
    } catch (_) {}

    final cleanOsName = _sanitizeHeader(osName);
    final cleanOsVersion = _sanitizeHeader(osVersion);
    final cleanDeviceModel = _sanitizeHeader(deviceModel.isNotEmpty ? deviceModel : 'Mobile');
    final cleanManufacturer = _sanitizeHeader(manufacturer.isNotEmpty ? manufacturer : 'Generic');
    final cleanAppVersion = _sanitizeHeader(appVersion);
    final cleanBuildNumber = _sanitizeHeader(buildNumber);

    final userAgent = 'ProggaMobile/$cleanAppVersion ($cleanOsName $cleanOsVersion; $cleanDeviceModel; $cleanManufacturer)';

    return DeviceMetadata(
      appVersion: cleanAppVersion,
      buildNumber: cleanBuildNumber,
      osName: cleanOsName,
      osVersion: cleanOsVersion,
      deviceModel: cleanDeviceModel,
      manufacturer: cleanManufacturer,
      userAgent: userAgent,
    );
  }

  static String _sanitizeHeader(String input) {
    if (input.isEmpty) return '';
    return input.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
  }
}
