import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';

class BitlabsOfferwallScreen extends StatefulWidget {
  const BitlabsOfferwallScreen({super.key});

  @override
  State<BitlabsOfferwallScreen> createState() => _BitlabsOfferwallScreenState();
}

class _BitlabsOfferwallScreenState extends State<BitlabsOfferwallScreen> {
  WebViewController? _controller;
  bool _isLoading = true;

  // BitLabs API Credentials
  static const String apiToken = 'a35d4e74-34a4-4949-bf48-e05dff23baba';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    // Get user ID - prefer mobile number, fallback to device ID, or use guest_user
    String userId = 'guest_user';
    final mobileNumber = await StorageService.getMobileNumber();
    final deviceId = await StorageService.getDeviceId();
    
    if (mobileNumber != null && mobileNumber.isNotEmpty) {
      userId = mobileNumber;
    } else if (deviceId != null && deviceId.isNotEmpty) {
      userId = deviceId;
    }

    // Build offerwall URL - use 'token' parameter as required by BitLabs
    final offerwallUrl = 'https://web.bitlabs.ai/?uid=$userId&token=$apiToken';
    
    if (kDebugMode) {
      print('BitLabs: Opening offerwall with URL: $offerwallUrl');
      print('BitLabs: User ID: $userId');
      print('BitLabs: API Token: $apiToken');
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

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  Future<bool> _onWillPop() async {
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

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
              if (controller != null && await controller.canGoBack()) {
                controller.goBack();
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
            if (controller != null) WebViewWidget(controller: controller),
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
