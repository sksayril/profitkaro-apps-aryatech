import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'device_service.dart';

class ApiService {
  static const String baseUrl = 'https://apiprofit.seotube.in';
  // static const String baseUrl = 'https://7cvccltb-3111.inc1.devtunnels.ms';
  
  // Signup endpoint
  static Future<Map<String, dynamic>> signup({
    required String userName,
    required String mobileNumber,
    required String password,
    String? referralCode,
  }) async {
    try {
      // Get device ID automatically in the background
      final deviceId = await DeviceService.getDeviceId();
      
      final requestBody = {
        'UserName': userName,
        'MobileNumber': mobileNumber,
        'Password': password,
        'DeviceId': deviceId,
      };
      
      // Add referral code only if provided
      if (referralCode != null && referralCode.isNotEmpty) {
        requestBody['ReferralCode'] = referralCode.trim().toUpperCase();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Signup failed',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Login endpoint
  static Future<Map<String, dynamic>> login({
    required String mobileNumber,
    required String password,
  }) async {
    try {
      // Get device ID automatically in the background
      final deviceId = await DeviceService.getDeviceId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'MobileNumber': mobileNumber,
          'Password': password,
          'DeviceId': deviceId,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
          'token': data['token'],
        };
      } else if (response.statusCode == 403) {
        // Handle blocked user or device mismatch
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
          'isBlocked': data['isBlocked'] ?? false,
          'blockedReason': data['blockedReason'],
          'blockedAt': data['blockedAt'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get wallet balance endpoint
  static Future<Map<String, dynamic>> getWalletBalance({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/wallet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else if (response.statusCode == 403) {
         return {
          'success': false,
          'message': data['message'],
          'isBlocked': data['isBlocked'] ?? false,
          'blockedReason': data['blockedReason'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch wallet balance',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user referral code endpoint
  static Future<Map<String, dynamic>> getReferCode({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/refercode'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch referral code',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get captcha endpoint
  static Future<Map<String, dynamic>> getCaptcha({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/captcha'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch captcha',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Solve captcha endpoint
  static Future<Map<String, dynamic>> solveCaptcha({
    required String token,
    required String captcha,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/captcha/solve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Captcha': captcha,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to solve captcha',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get daily bonuses endpoint
  static Future<Map<String, dynamic>> getDailyBonuses({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/dailybonus'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch daily bonuses',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Claim daily bonus endpoint
  static Future<Map<String, dynamic>> claimDailyBonus({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/dailybonus/claim'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to claim daily bonus',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Submit withdrawal request endpoint
  static Future<Map<String, dynamic>> submitWithdrawalRequest({
    required String token,
    required double amount,
    required String paymentMethod,
    String? upiId,
    String? virtualId,
    String? bankAccountNumber,
    String? bankIFSC,
    String? bankName,
    String? accountHolderName,
  }) async {
    try {
      final requestBody = {
        'Amount': amount,
        'PaymentMethod': paymentMethod,
      };

      if (paymentMethod == 'UPI' || paymentMethod == 'Paytm' || paymentMethod == 'Google Pay') {
        if (upiId != null && upiId.isNotEmpty) {
          requestBody['UPIId'] = upiId;
        }
        if (virtualId != null && virtualId.isNotEmpty) {
          requestBody['VirtualId'] = virtualId;
        }
      } else if (paymentMethod == 'BankTransfer') {
        if (bankAccountNumber != null && bankAccountNumber.isNotEmpty) {
          requestBody['BankAccountNumber'] = bankAccountNumber;
        }
        if (bankIFSC != null && bankIFSC.isNotEmpty) {
          requestBody['BankIFSC'] = bankIFSC;
        }
        if (bankName != null && bankName.isNotEmpty) {
          requestBody['BankName'] = bankName;
        }
        if (accountHolderName != null && accountHolderName.isNotEmpty) {
          requestBody['AccountHolderName'] = accountHolderName;
        }
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/withdrawal/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit withdrawal request',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get withdrawal requests endpoint
  static Future<Map<String, dynamic>> getWithdrawalRequests({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/withdrawal/requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch withdrawal requests',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// POST /users/gift-voucher/request — submit a gift voucher redemption.
  ///
  /// `brand` must be one of: `Amazon`, `Flipkart`, `GooglePlay`, `Paytm`.
  /// `amount` must be one of the allowed denominations enforced by the
  /// backend (currently 10, 20, 30, 50).
  static Future<Map<String, dynamic>> submitGiftVoucherRequest({
    required String token,
    required String brand,
    required int amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/gift-voucher/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Brand': brand,
          'Amount': amount,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit gift voucher request',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// GET /users/gift-voucher/requests — list the user's gift voucher
  /// requests (Pending / Approved / Rejected / Delivered). The
  /// `voucherCode` field is only returned when status is `Delivered`.
  static Future<Map<String, dynamic>> getGiftVoucherRequests({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/gift-voucher/requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch gift voucher requests',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user profile endpoint
  static Future<Map<String, dynamic>> getUserProfile({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else if (response.statusCode == 403) {
        // Handle blocked user
         return {
          'success': false,
          'message': data['message'],
          'isBlocked': data['isBlocked'] ?? false,
          'blockedReason': data['blockedReason'],
          'blockedAt': data['blockedAt'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch user profile',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get all available apps for installation
  static Future<Map<String, dynamic>> getApps({
    required String token,
    String? filter,
    String? difficulty,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (filter != null && filter.isNotEmpty) {
        queryParams['filter'] = filter;
      }
      if (difficulty != null && difficulty.isNotEmpty) {
        queryParams['difficulty'] = difficulty;
      }

      final uri = Uri.parse('$baseUrl/users/apps').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch apps',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Submit app installation with screenshot
  static Future<Map<String, dynamic>> submitAppInstallation({
    required String token,
    required String appId,
    File? screenshotFile,
    String? screenshotBase64,
    String? screenshotUrl,
  }) async {
    try {
      if (screenshotFile != null) {
        // Method 1: File Upload (multipart/form-data) - Recommended
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/users/apps/$appId/submit'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(
          await http.MultipartFile.fromPath(
            'screenshot',
            screenshotFile.path,
            filename: screenshotFile.path.split('/').last,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': data['message'],
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to submit app installation',
            'error': data['error'],
          };
        }
      } else if (screenshotBase64 != null && screenshotBase64.isNotEmpty) {
        // Method 2: Base64 Image (JSON)
        final response = await http.post(
          Uri.parse('$baseUrl/users/apps/$appId/submit'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'screenshotBase64': screenshotBase64,
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': data['message'],
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to submit app installation',
            'error': data['error'],
          };
        }
      } else if (screenshotUrl != null && screenshotUrl.isNotEmpty) {
        // Method 3: Direct URL (JSON) - Legacy support
        final response = await http.post(
          Uri.parse('$baseUrl/users/apps/$appId/submit'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'ScreenshotUrl': screenshotUrl,
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': data['message'],
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to submit app installation',
            'error': data['error'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Screenshot is required. Please provide either a file upload, base64 image, or ScreenshotUrl',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user's app installation submission history
  static Future<Map<String, dynamic>> getAppSubmissions({
    required String token,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/users/apps/submissions').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch submissions',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get coin conversion rate
  static Future<Map<String, dynamic>> getCoinConversionRate({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/coinconversion/rate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch conversion rate',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Convert coins to rupees
  static Future<Map<String, dynamic>> convertCoins({
    required String token,
    required int coins,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/coinconversion/convert'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Coins': coins,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to convert coins',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get scratch card information
  static Future<Map<String, dynamic>> getScratchCard({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/scratchcard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch scratch card',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Claim scratch card reward
  static Future<Map<String, dynamic>> claimScratchCard({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/scratchcard/claim'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to claim scratch card',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get scratch card history
  static Future<Map<String, dynamic>> getScratchCardHistory({
    required String token,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (page != null) {
        queryParams['page'] = page.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final uri = Uri.parse('$baseUrl/users/scratchcard/history').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch scratch card history',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get scratch card daily limit info
  static Future<Map<String, dynamic>> getScratchCardDailyLimit({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/scratchcard/dailylimit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': data['message'] ?? 'User Not Found',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch scratch card daily limit',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Claim scratch card daily limit
  static Future<Map<String, dynamic>> claimScratchCardDailyLimit({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/scratchcard/dailylimit/claim'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to claim scratch card',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': data['message'] ?? 'User Not Found',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to claim scratch card',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Add coins to user wallet
  static Future<Map<String, dynamic>> addCoins({
    required String token,
    required int coins,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/addcoins'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Coins': coins,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add coins',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get support link (public - no token required)
  static Future<Map<String, dynamic>> getPublicSupportLink() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/support/link'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch support link',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get support link (with token - for authenticated users)
  static Future<Map<String, dynamic>> getSupportLink({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/support/link'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch support link',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get withdrawal threshold
  static Future<Map<String, dynamic>> getWithdrawalThreshold({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/withdrawal/threshold'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch withdrawal threshold',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  // Get top users leaderboard
  static Future<Map<String, dynamic>> getLeaderboard({
    required String token,
    String type = 'wallet',
    int limit = 50,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{
        'type': type,
        'limit': limit.toString(),
        'page': page.toString(),
      };

      final uri = Uri.parse('$baseUrl/users/leaderboard').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch leaderboard',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get daily spin status
  static Future<Map<String, dynamic>> getDailySpinStatus({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/dailyspin/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch spin status',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Use/record daily spin usage
  static Future<Map<String, dynamic>> useDailySpin({
    required String token,
    int spinCount = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/dailyspin/use'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'SpinCount': spinCount,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to record spin usage',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get combined wallet & task history
  static Future<Map<String, dynamic>> getWalletHistory({
    required String token,
    int page = 1,
    int limit = 50,
    String? type,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse('$baseUrl/users/wallethistory')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch wallet history',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Add amount (RS) to user wallet balance
  static Future<Map<String, dynamic>> addWallet({
    required String token,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/addwallet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'Amount': amount,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add wallet balance',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get signup bonus info endpoint
  static Future<Map<String, dynamic>> getSignupBonusInfo({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/signupbonus/info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch signup bonus info',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Submit sponsor promotion request
  static Future<Map<String, dynamic>> submitSponsorPromotion({
    required String token,
    required String sponsorName,
    required String mobileNumber,
    required String email,
    required String appPromotion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/sponsor/promotion'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'SponsorName': sponsorName,
          'MobileNumber': mobileNumber,
          'Email': email,
          'AppPromotion': appPromotion,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Sponsor promotion submitted successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit sponsor promotion',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Evaluate ads decision endpoint
  static Future<Map<String, dynamic>> getAdsDecision({
    required String token,
    required String taskType,
    required int actionCount,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/users/ads/decision').replace(
        queryParameters: {
          'taskType': taskType,
          'actionCount': actionCount.toString(),
        },
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Ads decision evaluated successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to evaluate ads decision',
          'error': data['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Fetch quiz settings from the task-controls API.
  /// Filters the response array for `TaskType: "Quiz"`.
  static Future<Map<String, dynamic>> getQuizSettingsPublic() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/users/task-controls/public'),
            headers: const {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      dynamic raw;
      try {
        raw = jsonDecode(response.body);
      } catch (_) {
        return {
          'success': false,
          'message': 'Invalid response from server',
        };
      }

      if (response.statusCode == 200 && raw is Map<String, dynamic>) {
        final dataList = raw['data'];
        if (dataList is List) {
          final quizEntry = dataList.firstWhere(
            (item) => item is Map && item['TaskType'] == 'Quiz',
            orElse: () => null,
          );
          if (quizEntry != null && quizEntry is Map) {
            return {
              'success': true,
              'message': 'Quiz settings retrieved successfully',
              'data': Map<String, dynamic>.from(quizEntry),
            };
          }
        }
        return {
          'success': false,
          'message': 'Quiz task control not found',
        };
      }

      return {
        'success': false,
        'message': raw is Map && raw['message'] != null
            ? raw['message'].toString()
            : 'Failed to load quiz settings',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Public home popup template (no auth). See `PopupTemplatePublic`.
  static Future<Map<String, dynamic>> getPopupTemplatePublic() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/users/popup-template/public'),
            headers: const {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      dynamic raw;
      try {
        raw = jsonDecode(response.body);
      } catch (_) {
        return {
          'success': false,
          'message': 'Invalid response from server',
        };
      }
      final data = raw;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return {
          'success': true,
          'message': data['message'] ?? 'Popup template retrieved successfully',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to load popup template',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Public Telegram / YouTube / Instagram URLs (no auth).
  static Future<Map<String, dynamic>> getSocialLinksPublic() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/users/social-links/public'),
            headers: const {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      dynamic raw;
      try {
        raw = jsonDecode(response.body);
      } catch (_) {
        return {
          'success': false,
          'message': 'Invalid response from server',
        };
      }
      final data = raw;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return {
          'success': true,
          'message': data['message'] ?? 'Social links retrieved successfully',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to load social links',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
