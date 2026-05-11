import 'dart:io';

class AdBlockDetectorService {
  AdBlockDetectorService._();
  static final AdBlockDetectorService instance = AdBlockDetectorService._();

  static const Duration _lookupTimeout = Duration(seconds: 3);
  static const Duration _cacheDuration = Duration(seconds: 8);

  static const List<String> _adDomains = [
    'googleads.g.doubleclick.net',
    'pagead2.googlesyndication.com',
    'adservice.google.com',
    'doubleclick.net',
    'googlesyndication.com',
    'ads.pubmatic.com',
  ];

  DateTime? _lastCheckAt;
  bool? _lastResult;

  Future<bool> isAdBlockLikelyEnabled() async {
    if (_lastCheckAt != null &&
        _lastResult != null &&
        DateTime.now().difference(_lastCheckAt!) < _cacheDuration) {
      return _lastResult!;
    }

    final hasInternet = await _hasGeneralInternet();
    if (!hasInternet) {
      _lastCheckAt = DateTime.now();
      _lastResult = false;
      return _lastResult!;
    }

    var blockedCount = 0;
    for (final domain in _adDomains.take(4)) {
      final reachable = await _isAdDomainReachable(domain);
      if (!reachable) {
        blockedCount++;
      }
    }

    // If most ad domains fail while internet is healthy, ad-blocking is likely active.
    _lastCheckAt = DateTime.now();
    _lastResult = blockedCount >= 3;
    return _lastResult!;
  }

  Future<bool> _hasGeneralInternet() async {
    final googleOk = await _canResolve('google.com');
    if (!googleOk) return false;
    return _canResolve('cloudflare.com');
  }

  Future<bool> _isAdDomainReachable(String host) async {
    final resolved = await _canResolve(host);
    if (!resolved) return false;

    // DNS can still resolve with sinkhole addresses; verify TCP connectivity too.
    return _canConnect(host, 443);
  }

  Future<bool> _canResolve(String host) async {
    try {
      final addresses = await InternetAddress.lookup(host).timeout(_lookupTimeout);
      return addresses.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _canConnect(String host, int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: _lookupTimeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      await socket?.close();
    }
  }
}
