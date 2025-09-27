import 'package:shared_preferences/shared_preferences.dart';

class PersistentAuthService {
  static const String _isLoggedInKey = 'is_logged_in';

  // Save login state
  static Future<void> saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  // Get login state
  static Future<bool> getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear login state
  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
  }
}