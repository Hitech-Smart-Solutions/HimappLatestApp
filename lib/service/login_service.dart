import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginService {
  final String apiUrl = "http://192.168.1.130:8000/api/UserMaster/UserLogin";

  // Login function
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userName': username,
          'password': password,
          'token':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6InNhIiwibmJmIjoxNzQyNDc4MjgxLCJleHAiOjE3NDc3NDg2ODEsImlhdCI6MTc0MjQ3ODI4MSwiaXNzIjoibG9jYWxob3N0IiwiYXVkIjoibG9jYWxob3N0In0.ic39ZtVmb4fX3VbJ8Uw5mroCgHVl8ZZmhQruPBjDw3g'
        }),
      );
      print(response);
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        // Extract token and save it to local storage
        final String token =
            responseBody['token']; // Assuming response contains 'token'

        // Save token to local storage
        await _saveTokenToLocalStorage(token);

        return {
          'success': true,
          'data': responseBody,
          'token': token, // Returning token in the response
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to login. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred. Please try again.',
      };
    }
  }

  // Function to save token to local storage
  Future<void> _saveTokenToLocalStorage(String token) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('auth_token', token); // Save token in shared preferences
  }

  // Function to retrieve token from local storage
  Future<String?> getTokenFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // Get the saved token
  }

  // Function to save company ID to local storage
  Future<void> saveCompanyIdToLocalStorage(int companyId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('selectedCompanyId', companyId); // Save the company ID
  }

  // Function to retrieve company ID from local storage
  Future<int?> getCompanyIdFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selectedCompanyId'); // Get the saved company ID
  }

  // Manually set a token for testing or initial setup
  Future<void> setManualToken() async {
    // Define the manual token
    String token =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6InNhIiwibmJmIjoxNzQyNDc4MjgxLCJleHAiOjE3NDc3NDg2ODEsImlhdCI6MTc0MjQ3ODI4MSwiaXNzIjoibG9jYWxob3N0IiwiYXVkIjoibG9jYWxob3N0In0.ic39ZtVmb4fX3VbJ8Uw5mroCgHVl8ZZmhQruPBjDw3g";

    // Save the token to local storage
    await _saveTokenToLocalStorage(token);
    print("Manual Token Saved: $token");
  }
}
