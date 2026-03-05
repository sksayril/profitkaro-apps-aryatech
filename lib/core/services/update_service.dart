import 'package:in_app_update/in_app_update.dart';
import 'dart:io';

class UpdateService {
  /// Check for app updates and handle them
  /// 
  /// [updateType] - 'flexible' for background update or 'immediate' for forced update
  /// Returns true if update was started, false otherwise
  static Future<bool> checkForUpdate({String updateType = 'flexible'}) async {
    try {
      // Only works on Android
      if (!Platform.isAndroid) {
        return false;
      }

      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateType == 'immediate') {
          // Immediate Update (Force update)
          await InAppUpdate.performImmediateUpdate();
          return true;
        } else {
          // Flexible Update (User can continue using app)
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print("Update error: $e");
      return false;
    }
  }

  /// Check for updates silently (non-blocking)
  /// This can be called during app initialization
  static Future<void> checkForUpdateSilently() async {
    try {
      if (!Platform.isAndroid) {
        return;
      }

      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Use flexible update by default so user can continue using the app
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      print("Silent update check error: $e");
      // Silently fail - don't interrupt user experience
    }
  }
}
