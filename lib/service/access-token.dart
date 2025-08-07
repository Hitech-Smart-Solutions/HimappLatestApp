import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

Future<void> sendFcmPush() async {
  try {
    // Step 1: Load your service account key
    final serviceAccountJsonPath = '../../config/service-account.json';
    final file = File(serviceAccountJsonPath);

    if (!file.existsSync()) {
      print('❌ File not found at: $serviceAccountJsonPath');
      return;
    }

    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(await file.readAsString()),
    );

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // Step 2: Create authenticated client
    final client = await clientViaServiceAccount(credentials, scopes);
    print('🔑 Access Token: ${client.credentials.accessToken.data}');

    // Step 3: Prepare the API URL
    final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/hi-mappnew/messages:send');

    // Step 4: Create the notification payload
    final fcmPayload = {
      "message": {
        "token":
            "ezP48neGR9aYeSYWBmBgnH:APA91bELY4L71upq0AA624SoQCRF0P4T4CrgZ3fHRdBtKLbpfkYyaU2xU7sIPAXVjEBGNi9s2tkRYySrGv96TmnJo0cD2Jw_P4PMVUV2FoBdIPX1G9S6qFw",
        "notification": {
          "title": "🔥 Dart Firebase Test",
          "body": "This is a notification with optional image"
        },
        "android": {
          "notification": {
            "image":
                "https://yourdomain.com/image.jpg" // <-- Replace this with a real public URL
          }
        },
        "webpush": {
          "fcm_options": {"image": "https://yourdomain.com/image.jpg"}
        },
        "apns": {
          "payload": {
            "aps": {"mutable-content": 1}
          },
          "fcm_options": {"image": "https://yourdomain.com/image.jpg"}
        }
      }
    };

    // Step 5: Send POST request to FCM API
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(fcmPayload),
    );

    // Step 6: Print the result
    print('✅ Notification Sent!');
    print('🔑 Access Token: ${client.credentials.accessToken.data}');
    print('🔢 Status Code: ${response.statusCode}');
    print('📩 Response Body: ${response.body}');

    client.close();
  } catch (e, stacktrace) {
    print('❌ Error: $e');
    print('📌 Stacktrace: $stacktrace');
  }
}

void main() {
  print("🌟 Main started");
  sendFcmPush();
}
