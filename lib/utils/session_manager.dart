import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _userTokenKey = "USER_TOKEN";
  static const String _userKey = "USER";
  static const String _rememberMeKey = "REMEMBER_ME";
  static const String _organizationIdKey = "ORGANIZATION_ID";

  /// Save user session
  static Future<void> saveUserSession(
    String token,
    Map<String, dynamic> user,
    bool rememberMe,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
    await prefs.setBool(_rememberMeKey, rememberMe);

    if (user.containsKey("OrganizationId") && user["OrganizationId"] != null) {
      await prefs.setInt(_organizationIdKey, user["OrganizationId"]);
    }
  }

  /// Get user token
  static Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey);
  }

  /// Get user object
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return jsonDecode(userString);
    }
    return null;
  }

  /// Get remember me flag
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  /// Get organization id
  static Future<int?> getOrganizationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_organizationIdKey);
  }

  /// Clear session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userTokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_organizationIdKey);
  }
}
