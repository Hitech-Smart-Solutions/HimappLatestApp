import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;

Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

class FirebaseMessagingService {
  static Future<void> initialize() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission (especially important on iOS)
    await messaging.requestPermission();

    // Print the token
    final token = await messaging.getToken();
    print('FCM Token: $token');
    if (token != null) {
      await SharedPrefsHelper.saveFcmToken(token);
      print('Token saved in SharedPreferences!');
    }
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // print('Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        // Manually show using flutter_local_notifications here
        print('Message title: ${message.notification!.title}');
        print('Message body: ${message.notification!.body}');
      }
    });

    // Background handler when app is opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked!');
    });

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  Future<void> updateUserMobileAppTokenPut({
    required int userId,
    required String webTokenID,
    required String mobileAppTokenID,
  }) async {
    final url = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/UserMaster/UpdateUserMobileAppToken/$userId');

    final body = jsonEncode({
      "userId": userId,
      "webTokenID": webTokenID,
      "mobileAppTokenID": mobileAppTokenID,
    });
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      print('✅ Token updated successfully with PUT!');
    } else {
      print(
          '❌ Failed to update token with PUT: ${response.statusCode} ${response.body}');
    }
  }
}
