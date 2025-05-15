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

// Retrieve project ID from SharedPreferences
  static Future<int?> getProjectID() async {
    final prefs = await SharedPreferences.getInstance();
    int? projectId = prefs.getInt('ProjectID');
    print("📤 Retrieved ProjectID: $projectId");
    return projectId;
  }

  // Save project ID to SharedPreferences
  static Future<void> saveProjectID(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ProjectID', projectId);
    print("✅ ProjectID saved: $projectId");
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Sab data hata dega
  }

  // Save user name
  static Future<void> saveUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', userName);
  }

// Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  // Save dark mode status
  static Future<void> saveDarkModeStatus(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  // Get dark mode status
  static Future<bool> getDarkModeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? false; // Default to false if not set
  }

  // Manually set a test token (for debugging purposes)
  static Future<void> setManualToken() async {
    String token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6InNhIiwibmJmIjoxNzQyNDc4MjgxLCJleHAiOjE3NDc3NDg2ODEsImlhdCI6MTc0MjQ3ODI4MSwiaXNzIjoibG9jYWxob3N0IiwiYXVkIjoibG9jYWxob3N0In0.ic39ZtVmb4fX3VbJ8Uw5mroCgHVl8ZZmhQruPBjDw3g";
    await saveToken(token);
  }
}
