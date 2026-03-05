import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _mobileNumberKey = 'mobile_number';
  static const String _deviceIdKey = 'device_id';
  static const String _userNameKey = 'user_name';
  static const String _signupBonusShownKey = 'signup_bonus_shown';
  static const String _telegramRewardKey = 'social_telegram_last_reward';
  static const String _youtubeRewardKey = 'social_youtube_last_reward';
  static const String _instagramRewardKey = 'social_instagram_last_reward';
  static const String _pendingReferralCodeKey = 'pending_referral_code';

  // Save token
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      return false;
    }
  }

  // Get token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Save mobile number
  static Future<bool> saveMobileNumber(String mobileNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_mobileNumberKey, mobileNumber);
    } catch (e) {
      return false;
    }
  }

  // Get mobile number
  static Future<String?> getMobileNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_mobileNumberKey);
    } catch (e) {
      return null;
    }
  }

  // Save device ID
  static Future<bool> saveDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_deviceIdKey, deviceId);
    } catch (e) {
      return false;
    }
  }

  // Get device ID
  static Future<String?> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_deviceIdKey);
    } catch (e) {
      return null;
    }
  }

  // Clear all stored data (logout)
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      return false;
    }
  }

  // Save user name
  static Future<bool> saveUserName(String userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userNameKey, userName);
    } catch (e) {
      return false;
    }
  }

  // Get user name
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey);
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Check if signup bonus has been shown
  static Future<bool> hasSignupBonusBeenShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_signupBonusShownKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Mark signup bonus as shown
  static Future<bool> markSignupBonusAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_signupBonusShownKey, true);
    } catch (e) {
      return false;
    }
  }

  // Reset signup bonus shown status (useful for testing or new signups)
  static Future<bool> resetSignupBonusShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_signupBonusShownKey, false);
    } catch (e) {
      return false;
    }
  }

  // ---- Social media daily reward timestamps ----

  static Future<int?> _getLastRewardMillis(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> _setLastRewardMillis(String key, DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(key, time.millisecondsSinceEpoch);
    } catch (e) {
      return false;
    }
  }

  static Future<DateTime?> getLastTelegramRewardTime() async {
    final millis = await _getLastRewardMillis(_telegramRewardKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static Future<bool> setLastTelegramRewardTime(DateTime time) async {
    return _setLastRewardMillis(_telegramRewardKey, time);
  }

  // Generic int storage methods
  static Future<int?> getInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(key, value);
    } catch (e) {
      return false;
    }
  }

  // Generic string storage methods
  static Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, value);
    } catch (e) {
      return false;
    }
  }

  static Future<DateTime?> getLastYoutubeRewardTime() async {
    final millis = await _getLastRewardMillis(_youtubeRewardKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static Future<bool> setLastYoutubeRewardTime(DateTime time) async {
    return _setLastRewardMillis(_youtubeRewardKey, time);
  }

  static Future<DateTime?> getLastInstagramRewardTime() async {
    final millis = await _getLastRewardMillis(_instagramRewardKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static Future<bool> setLastInstagramRewardTime(DateTime time) async {
    return _setLastRewardMillis(_instagramRewardKey, time);
  }

  // ---- Referral Code from URL ----

  // Save pending referral code from URL
  static Future<bool> savePendingReferralCode(String referralCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_pendingReferralCodeKey, referralCode.toUpperCase().trim());
    } catch (e) {
      return false;
    }
  }

  // Get pending referral code from URL
  static Future<String?> getPendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_pendingReferralCodeKey);
    } catch (e) {
      return null;
    }
  }

  // Clear pending referral code (after signup)
  static Future<bool> clearPendingReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_pendingReferralCodeKey);
    } catch (e) {
      return false;
    }
  }
}
