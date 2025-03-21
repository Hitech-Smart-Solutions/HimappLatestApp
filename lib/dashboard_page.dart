import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String companyName; // This is where we will receive the company name

  // Constructor to accept the company name as a parameter
  const DashboardPage({super.key, required this.companyName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "$companyName - Dashboard"), // Display the company name in the title
      ),
      body: Center(
        child: Text(
          "Welcome to the $companyName Dashboard!", // Display the company name in the body
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
