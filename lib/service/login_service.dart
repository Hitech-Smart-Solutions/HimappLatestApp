import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../shared_prefs_helper.dart';

class LoginService {
  /// LOGIN API
  Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/UserMaster/UserLogin',
        data: {
          'userName': username,
          'password': password,
          'token': '',
        },
        options: Options(
          headers: {
            'Authorization': null, // 🔥 login me token nahi bhejna
          },
        ),
      );

      final responseBody = response.data;

      final int userId = responseBody['userId'] ?? 0;
      final String token = responseBody['token'] ?? '';

      if (token.isNotEmpty) {
        await SharedPrefsHelper.saveToken(token);
      }

      if (userId != 0) {
        await SharedPrefsHelper.saveUserId(userId);
      }

      return {
        'success': true,
        'data': responseBody,
        'token': token,
      };
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      // ❌ Wrong username or password
      if (statusCode == 401 || statusCode == 404) {
        return {
          'success': false,
          'message': 'Invalid username or password',
        };
      }
      return {
        'success': false,
        'message': 'Login failed. Please try again later.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  /// UPDATE FCM TOKEN
  Future<void> updateUserMobileAppToken(
    int userId,
    String fcmToken,
  ) async {
    try {
      await ApiClient.dio.put(
        '/api/UserMaster/UpdateUserMobileAppToken/$userId',
        data: {
          "userId": userId,
          "webTokenID": "",
          "mobileAppTokenID": fcmToken,
        },
      );

      print("✅ FCM token saved to DB");
    } on DioException catch (e) {
      print("❌ Failed to save FCM token");
      print("Status: ${e.response?.statusCode}");
      print("Body: ${e.response?.data}");
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      // print("📤 Forgot Password API CALL");
      // print("➡️ Email: $email");

      final response = await ApiClient.dio.post(
        '/api/UserMaster/forgot-password',
        data: {
          "Email": email,
        },
      );

      // print("✅ API RESPONSE RECEIVED");
      // print("Status Code: ${response.statusCode}");
      // print("Response Data: ${response.data}");

      return response.data["message"];
    } on DioException catch (e) {
      print("❌ API ERROR");
      print("Status: ${e.response?.statusCode}");
      print("Error Data: ${e.response?.data}");

      return e.response?.data["message"] ?? "Something went wrong";
    } catch (e) {
      print("❌ UNEXPECTED ERROR: $e");
      return "Unexpected error occurred";
    }
  }
}
