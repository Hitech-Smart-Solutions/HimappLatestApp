import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppUpdateService {
  static Future<bool> shouldForceUpdate() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero, // DEBUG ke liye
      ),
    );

    await remoteConfig.fetchAndActivate();

    final latestVersion = remoteConfig.getString('android_latest_version');
    final forceUpdate = remoteConfig.getBool('android_force_update');
    final maintenance = remoteConfig.getBool('android_maintenance');

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    // 🔥 DEBUG LOGS (VERY IMPORTANT)
    print("🔥 Firebase latest version: $latestVersion");
    print("🔥 Current app version: $currentVersion");
    print("🔥 Force update: $forceUpdate");
    print("🔥 Maintenance: $maintenance");

    if (maintenance) return true;

    if (_isUpdateRequired(currentVersion, latestVersion) && forceUpdate) {
      return true;
    }

    return false;
  }

  static bool _isUpdateRequired(String current, String latest) {
    final c = current.split('.').map(int.parse).toList();
    final l = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < l.length; i++) {
      if (c[i] < l[i]) return true;
      if (c[i] > l[i]) return false;
    }
    return false;
  }
}
