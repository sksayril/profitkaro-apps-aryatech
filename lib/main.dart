import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/google_mobile_ads_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  if (!kDebugMode && !kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const MyApp());

  // Defer third-party SDK initialization until after the first frame to avoid
  // startup-time platform channel races and reduce cold-start crashes/ANRs.
  unawaited(
    Future<void>(() async {
      try {
        await DeepLinkService().init();
      } catch (e, s) {
        if (!kDebugMode && !kIsWeb) {
          FirebaseCrashlytics.instance.recordError(e, s, reason: 'sdk_init');
        } else {
          debugPrint('SDK init failed: $e');
        }
      }
      if (kIsWeb) return;
      try {
        await GoogleMobileAdsService.instance.initialize();
      } catch (e, s) {
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordError(e, s, reason: 'google_mobile_ads_init');
        } else {
          debugPrint('Google Mobile Ads init failed: $e');
        }
      }
    }),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ProfitKaro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: _analytics),
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
