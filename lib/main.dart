import 'package:flutter/material.dart';
import 'login_page.dart'; // Your Login Page

void main() {
  runApp(const MyApp());
}

// ✅ Make MyApp Stateful to toggle theme
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  // ✅ Function to toggle theme
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
      // ✅ Pass the toggle function & theme to login/dashboard
      home: MyCustomForm(
        onToggleTheme: toggleTheme,
        isDarkMode: isDarkMode,
      ),
    );
  }
}
