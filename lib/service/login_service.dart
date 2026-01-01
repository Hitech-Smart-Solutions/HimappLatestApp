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
      if (e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized. Please check your credentials.',
        };
      }

      return {
        'success': false,
        'message':
            'Login failed: ${e.response?.statusCode} - ${e.response?.data}',
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
}
