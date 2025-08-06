import 'dart:convert';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;

class LoginService {
  final String apiUrl =
      "https://d94acvrm8bvo5.cloudfront.net/api/UserMaster/UserLogin";
  String token = ""; // Manually added token
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

  Future<void> updateUserMobileAppToken(int userId, String fcmToken) async {
    final token = await SharedPrefsHelper.getToken(); // JWT Auth token

    final url = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/UserMaster/UpdateUserMobileAppToken/$userId');

    final body = jsonEncode({
      "userId": userId,
      "webTokenID": "",
      "mobileAppTokenID": fcmToken,
    });

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      print("✅ FCM token saved to DB");
    } else {
      print("❌ Failed to save FCM token: ${response.statusCode}");
      print("Response body: ${response.body}");
    }
  }
}
