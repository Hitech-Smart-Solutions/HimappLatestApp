import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

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

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
    });

    // Background handler when app is opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked!');
    });

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }
}
