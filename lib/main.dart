import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:himappnew/deshboard.dart';
import 'package:himappnew/service/firebase_messaging_service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/login_page.dart';
import 'package:himappnew/shared_prefs_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessagingService.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // final String? token;
  // final String? userName;
  // final String? companyName;

  const MyApp({
    super.key,
    // required this.token,
    // required this.userName,
    // required this.companyName,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  String? token;
  String? userName;
  String? companyName;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  Future<void> loadInitialData() async {
    token = await SharedPrefsHelper.getToken();
    userName = await SharedPrefsHelper.getUserName();
    companyName = await SharedPrefsHelper.getCompanyName();

    // print("🚀 Token: $token");
    // print("🚀 UserName: $userName");
    // print("🚀 CompanyName: $companyName");

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard App',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: token != null && token!.isNotEmpty
          ? DashboardPage(
              isDarkMode: isDarkMode,
              onToggleTheme: toggleTheme,
              userName: userName ?? '',
              companyName: companyName ?? '',
              projectService: ProjectService(),
              siteObservationService: SiteObservationService(),
            )
          : MyCustomForm(
              onToggleTheme: toggleTheme,
              isDarkMode: isDarkMode,
            ),
    );
  }
}
