import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';

class AyetOfferwallScreen extends StatefulWidget {
  const AyetOfferwallScreen({super.key});

  @override
  State<AyetOfferwallScreen> createState() => _AyetOfferwallScreenState();
}

class _AyetOfferwallScreenState extends State<AyetOfferwallScreen> {
  WebViewController? _controller;
  bool _isLoading = true;

  // Ayet Studio API Credentials
  static const int placementId = 22259; // Must be number, not string
  static const String appKey = '95d451486ca911e80562d842250055a7';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    // Get user ID - ALWAYS use mobile number if available (required by Ayet)
    // Ayet expects NUMERIC user ID, not string
    int userId = 0;
    final mobileNumber = await StorageService.getMobileNumber();
    
    // Prioritize mobile number - Convert to integer (Ayet requires number)
    if (mobileNumber != null && mobileNumber.isNotEmpty) {
      // Convert mobile number string to integer
      try {
        userId = int.parse(mobileNumber);
        if (kDebugMode) {
          print('Ayet: Using mobile number as user ID: $userId (converted from: $mobileNumber)');
        }
      } catch (e) {
        // If mobile number is not a valid number, create hash from it
        userId = mobileNumber.hashCode.abs();
        if (kDebugMode) {
          print('Ayet: Mobile number is not numeric, using hash: $userId (from: $mobileNumber)');
        }
      }
    } else {
      // Only use device ID if mobile number is not available
      final deviceId = await StorageService.getDeviceId();
      if (deviceId != null && deviceId.isNotEmpty) {
        // Convert device ID to numeric hash
        userId = deviceId.hashCode.abs();
        if (kDebugMode) {
          print('Ayet: Mobile number not available, using device ID hash: $userId (from: $deviceId)');
        }
      } else {
        // Use default numeric ID if nothing is available
        userId = 999999999; // Default guest user ID
        if (kDebugMode) {
          print('Ayet: No user ID available, using default numeric ID: $userId');
        }
      }
    }

    // Build offerwall URL
    // NOTE: Ayet's web integration uses query params. We also include the app key
    // to ensure the correct publisher/app context (some setups require it).
    final offerwallUrl =
        'https://support.ayet.io/offers?externalIdentifier=$userId&placementId=$placementId&ayet_app_key=$appKey';
    
    if (kDebugMode) {
      print('Ayet: Opening offerwall with URL: $offerwallUrl');
      print('Ayet: User ID (externalIdentifier): $userId (type: ${userId.runtimeType})');
      print('Ayet: Placement ID: $placementId (type: ${placementId.runtimeType})');
      print('Ayet: App Key: $appKey');
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading offerwall: ${error.description}'),
                  backgroundColor: Colors.red.withOpacity(0.9),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(offerwallUrl));

    // Set controller before callbacks can run
    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_controller != null && await _controller!.canGoBack()) {
      _controller!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          backgroundColor: AppColors.cardBackground(context),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (_controller != null && await _controller!.canGoBack()) {
                _controller!.goBack();
              } else {
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
          title: const Text(
            'Earn Rewards',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            if (_controller != null)
              WebViewWidget(controller: _controller!)
            else
              Container(
                color: AppColors.background(context),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (_isLoading)
              Container(
                color: AppColors.background(context),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Loading Offerwall',
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we load premium offers...',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
