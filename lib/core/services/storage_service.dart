import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _mobileNumberKey = 'mobile_number';
  static const String _deviceIdKey = 'device_id';
  static const String _userNameKey = 'user_name';

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
}
