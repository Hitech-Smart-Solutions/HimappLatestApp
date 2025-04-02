import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  // Save token to SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Retrieve token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Save user ID to SharedPreferences
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  // Retrieve user ID from SharedPreferences
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Save company ID to SharedPreferences
  static Future<void> saveCompanyId(int companyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedCompanyId', companyId);
  }

  // Retrieve company ID from SharedPreferences
  static Future<int?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selectedCompanyId');
  }

  // Manually set a test token (for debugging purposes)
  static Future<void> setManualToken() async {
    String token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6InNhIiwibmJmIjoxNzQyNDc4MjgxLCJleHAiOjE3NDc3NDg2ODEsImlhdCI6MTc0MjQ3ODI4MSwiaXNzIjoibG9jYWxob3N0IiwiYXVkIjoibG9jYWxob3N0In0.ic39ZtVmb4fX3VbJ8Uw5mroCgHVl8ZZmhQruPBjDw3g";
    await saveToken(token);
  }
}
