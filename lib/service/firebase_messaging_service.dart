import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:himappnew/network/api_client.dart'; // ✅ NEW (only addition)

/// Background notification handler (UNCHANGED)
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

class FirebaseMessagingService {
  /// Firebase init (UNCHANGED)
  static Future<void> initialize() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission (especially important on iOS)
    await messaging.requestPermission();

    // Get FCM token
    final token = await messaging.getToken();
    print('FCM Token: $token');

    if (token != null) {
      await SharedPrefsHelper.saveFcmToken(token);
      print('Token saved in SharedPreferences!');
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Message title: ${message.notification!.title}');
        print('Message body: ${message.notification!.body}');
      }
    });

    // Notification click handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked!');
    });

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  /// 🔥 ONLY THIS METHOD IS CHANGED (http → Dio + Interceptor)
  Future<void> updateUserMobileAppTokenPut({
    required int userId,
    required String webTokenID,
    required String mobileAppTokenID,
  }) async {
    try {
      final response = await ApiClient.dio.put(
        '/api/UserMaster/UpdateUserMobileAppToken/$userId',
        data: {
          "userId": userId,
          "webTokenID": webTokenID,
          "mobileAppTokenID": mobileAppTokenID,
        },
      );

      print('✅ Token updated successfully with PUT!');
      print('Response: ${response.data}');
    } catch (e) {
      print('❌ Failed to update token with PUT: $e');
    }
  }
}
