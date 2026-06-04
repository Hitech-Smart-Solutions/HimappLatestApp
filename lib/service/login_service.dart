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

  Future<String?> forgotPassword(
    String input, {
    int? channel,
  }) async {
    try {
      final requestBody = {
        "Input": input,
        "Channel": channel ?? 2, // 👈 ensure always sent
      };

      print("📤 REQUEST (Forgot Password): $requestBody");

      final response = await ApiClient.dio.post(
        '/api/UserMaster/forgot-password',
        data: requestBody,
      );

      print("📥 RESPONSE: ${response.data}");

      return response.data["message"];
    } on DioException catch (e) {
      print("❌ API ERROR");
      print("Status: ${e.response?.statusCode}");
      print("Body: ${e.response?.data}");

      return e.response?.data["message"] ?? "Something went wrong";
    } catch (e) {
      print("❌ UNEXPECTED ERROR: $e");
      return "Unexpected error occurred";
    }
  }

  Future<Map<String, dynamic>?> forgotUsername(
    String input, {
    int? channel,
  }) async {
    try {
      // print("📤 REQUEST BODY: Input=$input, Channel=$channel");

      final response = await ApiClient.dio.post(
        '/api/UserMaster/forgot-username',
        data: {
          "Input": input,
          if (channel != null) "Channel": channel,
        },
      );

      // print("📥 FULL RESPONSE: ${response.data}");

      if (response.data["isSuccess"] == true) {
        return response.data["user"];
      } else {
        return null;
      }
    } catch (e) {
      print("❌ ERROR: $e");
      return null;
    }
  }
}
