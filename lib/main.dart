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

  runApp(MyAppWrapper());
}

/// 👇 Yeh widget wrap karta hai poori app ko with fixed [textScaleFactor]
class MyAppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: const MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard App',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),

      /// 👇 Yahan bhi builder lagana optional hai (already wrapped upar se)
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },

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
