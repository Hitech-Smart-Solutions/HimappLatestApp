import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:himappnew/deshboard.dart';
import 'package:himappnew/service/firebase_messaging_service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'login_page.dart'; // Your Login Page
import 'shared_prefs_helper.dart'; // Import SharedPrefsHelper for saving and fetching token

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessagingService.initialize();
  // Token ko SharedPreferences se fetch karo
  final token = await getToken();
  runApp(MyApp(token: token));
}

class MyApp extends StatefulWidget {
  final String? token;

  const MyApp({super.key, required this.token});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  // Function to toggle theme
  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard App',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: widget.token != null && widget.token!.isNotEmpty
          ? DashboardPage(
              isDarkMode: isDarkMode,
              onToggleTheme: toggleTheme,
              userName: 'John Doe',
              companyName: 'My Company',
              projectService:
                  ProjectService(), // Replace with your actual ProjectService
              siteObservationService:
                  SiteObservationService(), // Replace with your actual SiteObservationService
            )
          : MyCustomForm(
              onToggleTheme: toggleTheme,
              isDarkMode: isDarkMode,
            ),
    );
  }
}

// Simulate SharedPreferences token check
Future<String?> getToken() async {
  // Fetch the token from SharedPreferences
  return await SharedPrefsHelper
      .getToken(); // Replace with actual function to get token
}
