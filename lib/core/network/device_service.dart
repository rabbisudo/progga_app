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
        deviceModel = androidInfo.model;
        manufacturer = androidInfo.manufacturer;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        osVersion = 'iOS ${iosInfo.systemVersion}';
        deviceModel = iosInfo.name;
        manufacturer = 'Apple';
      }
    } catch (_) {}

    final userAgent = 'ProggaMobile/$appVersion ($osName $osVersion; $deviceModel; $manufacturer)';

    return DeviceMetadata(
      appVersion: appVersion,
      buildNumber: buildNumber,
      osName: osName,
      osVersion: osVersion,
      deviceModel: deviceModel,
      manufacturer: manufacturer,
      userAgent: userAgent,
    );
  }
}
