import 'dart:convert';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;

class LoginService {
  final String apiUrl = "http://192.168.1.130:8000/api/UserMaster/UserLogin";
  String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6InNhIiwibmJmIjoxNzQzNTA2NDg0LCJleHAiOjE3NDg3NzY4ODQsImlhdCI6MTc0MzUwNjQ4NCwiaXNzIjoibG9jYWxob3N0IiwiYXVkIjoibG9jYWxob3N0In0.FWB3drzcevP4m0KiHecDu0Xuer1yCNxVGoOCUl26do0"; // Manually added token
  // Login function
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // Dynamic or valid token
        },
        body: json.encode({
          'userName': username,
          'password': password,
          'token': '',
        }),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        // Save userId (assuming 'userId' is returned in the response)
        final int userId = responseBody['userId'] ?? 0;
        // Save token
        final String token = responseBody['token'] ?? '';

        if (token.isNotEmpty) {
          await SharedPrefsHelper.saveToken(token);
        }

        if (userId != 0) {
          await SharedPrefsHelper.saveUserId(userId);
        }

        return {'success': true, 'data': responseBody, 'token': token};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized. Please check your credentials.',
        };
      } else {
        return {
          'success': false,
          'message':
              'Login failed. Status Code: ${response.statusCode}, Body: ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
