import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

enum UpdatePromptMode { optional, mandatory }

class UpdateService {
  /// Check if update is available.
  static Future<AppUpdateInfo?> _getUpdateInfo() async {
    if (!Platform.isAndroid) return null;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        return updateInfo;
      }
      return null;
    } catch (e) {
      debugPrint('Update check error: $e');
      return null;
    }
  }

  /// Show custom update prompt.
  /// - [UpdatePromptMode.optional]: shows Cancel + Update now
  /// - [UpdatePromptMode.mandatory]: only Update now (no close/cancel)
  static Future<bool> checkAndPromptUpdate(
    BuildContext context, {
    UpdatePromptMode mode = UpdatePromptMode.optional,
  }) async {
    final updateInfo = await _getUpdateInfo();
    if (updateInfo == null || !context.mounted) {
      return false;
    }

    return _showUpdateDialog(context, mode: mode);
  }

  /// Legacy programmatic update trigger.
  /// [updateType] - 'flexible' for background update or 'immediate' for forced update
  static Future<bool> checkForUpdate({String updateType = 'flexible'}) async {
    try {
      final updateInfo = await _getUpdateInfo();
      if (updateInfo != null) {
        if (updateType == 'immediate') {
          await InAppUpdate.performImmediateUpdate();
          return true;
        } else {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Update error: $e');
      return false;
    }
  }

  /// Check for updates silently (non-blocking)
  /// This can be called during app initialization
  static Future<void> checkForUpdateSilently() async {
    try {
      final updateInfo = await _getUpdateInfo();
      if (updateInfo != null) {
        // Use flexible update by default so user can continue using the app
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('Silent update check error: $e');
      // Silently fail - don't interrupt user experience
    }
  }

  static Future<bool> _showUpdateDialog(
    BuildContext context, {
    required UpdatePromptMode mode,
  }) async {
    final isMandatory = mode == UpdatePromptMode.mandatory;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => !isMandatory,
        child: AlertDialog(
          title: const Text('Update Available'),
          content: Text(
            isMandatory
                ? 'A new version is required to continue. Please update now.'
                : 'A new version is available. Please update for better performance.',
          ),
          actions: [
            if (!isMandatory)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop('cancel'),
                child: const Text('Cancel'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop('update'),
              child: const Text('Update now'),
            ),
          ],
        ),
      ),
    );

    if (action != 'update') {
      return false;
    }

    try {
      if (isMandatory) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
      return true;
    } catch (e) {
      debugPrint('Update launch error: $e');
      return false;
    }
  }
}
