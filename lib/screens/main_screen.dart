import 'dart:async';

import 'package:flutter/material.dart';
import '../core/services/ad_block_detector_service.dart';
import '../core/services/pubscale_offerwall_service.dart';
import 'home/home_screen.dart';
import 'wallet/wallet_screen.dart';
import 'announcements/announcements_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static const Duration _adBlockMonitorInterval = Duration(seconds: 20);

  int _currentIndex = 0;
  bool _wasPaused = false;
  bool _isAdBlockEnabled = false;
  bool _isCheckingAdBlock = false;
  late final List<Widget> _screens;
  Timer? _adBlockMonitorTimer;

  void _goToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
      const HomeScreen(),
      WalletScreen(onBack: _goToHome),
      AnnouncementsScreen(onBack: _goToHome),
      HistoryScreen(onBack: _goToHome),
      ProfileScreen(onBack: _goToHome),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdBlockStatus();
      _startAdBlockMonitoring();
    });
  }

  @override
  void dispose() {
    _adBlockMonitorTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
      _adBlockMonitorTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      _startAdBlockMonitoring();
      _checkAdBlockStatus();
    }
  }

  void _startAdBlockMonitoring() {
    _adBlockMonitorTimer?.cancel();
    _adBlockMonitorTimer = Timer.periodic(_adBlockMonitorInterval, (_) {
      _checkAdBlockStatus();
    });
  }

  Future<void> _checkAdBlockStatus() async {
    if (_isCheckingAdBlock || !mounted) return;
    _isCheckingAdBlock = true;

    final isAdBlockEnabled =
        await AdBlockDetectorService.instance.isAdBlockLikelyEnabled();
    _isCheckingAdBlock = false;

    if (!mounted) return;

    if (_isAdBlockEnabled != isAdBlockEnabled) {
      setState(() {
        _isAdBlockEnabled = isAdBlockEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (_isAdBlockEnabled)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Card(
                        color: Colors.white,
                        elevation: 14,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF2E8),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.shield_moon_rounded,
                                      color: Color(0xFFFF7A00),
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Ad Blocker Detected',
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Please disable AdBlock, AdGuard or VPN DNS filtering to continue using the app and earning rewards.',
                                style: TextStyle(
                                  fontSize: 17,
                                  height: 1.45,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _isCheckingAdBlock
                                      ? null
                                      : () async {
                                          await _checkAdBlockStatus();
                                          if (!mounted) return;
                                          if (!_isAdBlockEnabled) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Thanks! Ad blocker is disabled.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.check_circle_rounded),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0EA5E9),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  label: Text(
                                    _isCheckingAdBlock
                                        ? 'Checking...'
                                        : 'I disabled it',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (_isAdBlockEnabled) {
            return;
          }

          if (index == 2) {
            final launched = await PubscaleOfferwallService.instance.launchOfferwall();
            if (!launched && context.mounted) {
              final details = PubscaleOfferwallService.instance.lastError;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    details == null
                        ? 'Unable to open App Install offers right now. Please try again.'
                        : 'Unable to open App Install offers: $details',
                  ),
                ),
              );
            }
            return;
          }

            setState(() {
              _currentIndex = index;
            });
          },
      ),
    );
  }
}
