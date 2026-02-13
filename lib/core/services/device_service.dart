import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceService {
  static Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Android ID
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios-device-${DateTime.now().millisecondsSinceEpoch}';
    } else {
      // For other platforms, generate a unique ID
      return 'device-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
