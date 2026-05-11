import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pubscale_offerwall_plugin/pubscale_offerwall_plugin.dart';

import 'storage_service.dart';

class PubscaleOfferwallService {
  PubscaleOfferwallService._();
  static final PubscaleOfferwallService instance = PubscaleOfferwallService._();

  static const String _appId = '77721845';
  static const bool _sandboxMode = false;

  final PubscaleOfferwallPlugin _plugin = PubscaleOfferwallPlugin();
  StreamSubscription<dynamic>? _eventSubscription;
  bool _isInitialized = false;
  String? _lastError;
  Completer<bool>? _initCompleter;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    _initCompleter = Completer<bool>();
    _lastError = null;

    final userId = await _resolveUserId();

    try {
      _eventSubscription ??= _plugin.offerwallEvents.listen((event) {
        final eventName = event is Map ? event['event'] as String? : null;
        if (kDebugMode) {
          debugPrint('PubScale event: $event');
        }

        if (eventName == 'offerwall_init_success' && !(_initCompleter?.isCompleted ?? true)) {
          _isInitialized = true;
          _initCompleter?.complete(true);
        } else if (eventName == 'offerwall_init_failed' && !(_initCompleter?.isCompleted ?? true)) {
          _lastError = (event is Map ? event['error'] : null)?.toString() ?? 'Offerwall initialization failed';
          _isInitialized = false;
          _initCompleter?.complete(false);
        }
      });

      await _plugin.initializeOfferwall(_appId, userId, _sandboxMode, false);

      // Wait for explicit SDK callback to avoid launching before init completes.
      final initOk = await _initCompleter!.future.timeout(const Duration(seconds: 8), onTimeout: () {
        _lastError = 'Offerwall initialization timed out';
        _isInitialized = false;
        return false;
      });
      _isInitialized = initOk;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PubScale init failed: $e');
      }
      _lastError ??= e.toString();
      _isInitialized = false;
      if (!(_initCompleter?.isCompleted ?? true)) {
        _initCompleter?.complete(false);
      }
    } finally {
      _initCompleter = null;
    }
  }

  Future<bool> launchOfferwall() async {
    _lastError = null;
    try {
      if (!_isInitialized) {
        await initialize();
      }
      if (!_isInitialized) {
        _lastError ??= 'Offerwall is not initialized on this device';
        return false;
      }

      await _plugin.launchOfferwall();
      return true;
    } catch (e) {
      _lastError ??= e.toString();
      if (kDebugMode) {
        debugPrint('PubScale launch failed: $e');
      }
      return false;
    }
  }

  Future<String> _resolveUserId() async {
    final mobileNumber = await StorageService.getMobileNumber();
    if (mobileNumber != null && mobileNumber.isNotEmpty) {
      return mobileNumber;
    }

    final deviceId = await StorageService.getDeviceId();
    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    return 'guest-${DateTime.now().millisecondsSinceEpoch}';
  }

}
