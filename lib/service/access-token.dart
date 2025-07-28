import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

Future<void> sendFcmPush() async {
  // Replace with your service account key file
  final serviceAccountJson = '../../config/service-account.json';

  final accountCredentials = ServiceAccountCredentials.fromJson(
    json.decode(await File(serviceAccountJson).readAsString()),
  );

  final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  // Get the access token
  final client = await clientViaServiceAccount(accountCredentials, scopes);
  print("Access token: $client");
  final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/hi-mappnew/messages:send');

  final fcmPayload = {
    "message": {
      "token":
          "ezP48neGR9aYeSYWBmBgnH:APA91bELY4L71upq0AA624SoQCRF0P4T4CrgZ3fHRdBtKLbpfkYyaU2xU7sIPAXVjEBGNi9s2tkRYySrGv96TmnJo0cD2Jw_P4PMVUV2FoBdIPX1G9S6qFw",
      "notification": {
        "title": "Test from Dart",
        "body": "This is a test push notification"
      }
    }
  };

  final response = await client.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: json.encode(fcmPayload),
  );
  print('Sending to token: ${fcmPayload["message"]?["token"]}');
  print('FCM Response: ${response.statusCode}');
  print('Response body: ${response.body}');

  client.close();
}

void main() {
  sendFcmPush();
}
