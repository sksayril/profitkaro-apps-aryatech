import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // static const String baseUrl = 'https://apiprofit.seotube.in';
  static const String baseUrl = 'https://7cvccltb-3111.inc1.devtunnels.ms';
  
  // Signup endpoint
  static Future<Map<String, dynamic>> signup({
    required String mobileNumber,
    required String password,
    String? referralCode,
  }) async {
    try {
      final requestBody = {
        'MobileNumber': mobileNumber,
        'Password': password,
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
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'MobileNumber': mobileNumber,
          'Password': password,
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
}
