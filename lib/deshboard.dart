import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animated_widgets/widgets/scale_animated.dart';
import 'package:himappnew/labour_registration_page.dart';
import 'package:himappnew/observation_ncr.dart';
import 'package:himappnew/service/labour_registration_service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:himappnew/site_observation_quality.dart';
import 'login_page.dart';
import 'site_observation_safety.dart';

class DashboardPage extends StatelessWidget {
  final String companyName;
  final String userName;
  final ProjectService projectService;
  final SiteObservationService siteObservationService;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const DashboardPage({
    super.key,
    required this.companyName,
    required this.userName,
    required this.projectService,
    required this.siteObservationService,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Text("Dashboard - $companyName"),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(userName),
            const SizedBox(height: 20),
            _buildStatsCards(context),
            const SizedBox(height: 30),
            Text("Insights",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildBarChart(),
            const SizedBox(height: 30),
            Text("Recent Observations",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildRecentObservations(),
            const SizedBox(height: 20),
            Text("Reminders",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildRemindersList(),
          ],
        ),
      ),
    );
  }

  // Greeting Card
  Widget _buildGreetingCard(String userName) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage("assets/images/profile.png"),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, $userName", style: const TextStyle(fontSize: 18)),
            Text("Welcome back to $companyName",
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = (screenWidth - 48) / 2;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildNeonGlassCard(
            icon: Icons.work,
            title: "Ongoing Projects",
            value: "12",
            color: Colors.cyanAccent,
            width: cardWidth),
        GestureDetector(
          onTap: () async {
            final userId = await SharedPrefsHelper.getUserId();
            print("🟡 UserID before navigating: $userId");
            if (userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ObservationNCRPage(
                    userId: userId,
                    siteObservationService: SiteObservationService(),
                  ),
                ),
              );
            }
          },
          child: _buildNeonGlassCard(
            icon: Icons.visibility,
            title: "Observations",
            value: "5",
            color: Colors.orangeAccent,
            width: cardWidth,
          ),
        ),
        _buildNeonGlassCard(
            icon: Icons.pending_actions,
            title: "Pending",
            value: "3",
            color: Colors.pinkAccent,
            width: cardWidth),
      ],
    );
  }

  Widget _buildNeonGlassCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    double? width,
  }) {
    return ScaleAnimatedWidget.tween(
      enabled: true,
      duration: const Duration(milliseconds: 150),
      scaleEnabled: 0.97,
      scaleDisabled: 1,
      child: Container(
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.25),
              color.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // soft neutral shadow
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4), width: 1),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      Text(value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, double width) {
    return ScaleAnimatedWidget.tween(
      enabled: true,
      duration: const Duration(milliseconds: 150),
      scaleDisabled: 1.0,
      scaleEnabled: 0.95,
      child: GestureDetector(
        onTap: () {},
        child: SizedBox(
          width: width,
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            shadowColor: color.withOpacity(0.6),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                    child: Icon(icon, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Chart
  Widget _buildBarChart() {
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(
                x: 0,
                barRods: [BarChartRodData(toY: 12, color: Colors.blueAccent)]),
            BarChartGroupData(
                x: 1,
                barRods: [BarChartRodData(toY: 8, color: Colors.orangeAccent)]),
            BarChartGroupData(
                x: 2,
                barRods: [BarChartRodData(toY: 5, color: Colors.redAccent)]),
          ],
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildRecentObservations() {
    return Column(
      children: List.generate(3, (index) {
        return ListTile(
          leading: const Icon(Icons.warning, color: Colors.orange),
          title: Text("Observation #${index + 1}"),
          subtitle: const Text("Site: ABC, Status: Pending"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        );
      }),
    );
  }

  Widget _buildRemindersList() {
    return Column(
      children: List.generate(3, (index) {
        return ListTile(
          leading: const Icon(Icons.calendar_today, color: Colors.blue),
          title: const Text("Inspection at Site XYZ"),
          subtitle: const Text("Due: Tomorrow"),
        );
      }),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: FutureBuilder<String?>(
        future: SharedPrefsHelper.getUserName(),
        builder: (context, snapshot) {
          String userName = snapshot.data ?? "User";

          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF379AE6), Color(0xFF62C1FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage("assets/images/profile.png"),
                    ),
                    const SizedBox(height: 10),
                    Text(userName,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16)),
                    Text(companyName,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.blue),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment, color: Colors.orange),
                title: const Text('Site Observation - Safety'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SiteObservationSafety(
                        companyName: companyName,
                        projectService: projectService,
                        siteObservationService: siteObservationService,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment, color: Colors.red),
                title: const Text('Site Observation - Quality'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SiteObservationQuality(
                        siteObservationService: SiteObservationService(),
                        projectService: projectService,
                      ),
                    ),
                  );
                },
              ),
              // Add the Labour Registration option here
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.green),
                title: const Text('Labour Registration'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabourRegistrationPage(
                        companyName: companyName,
                        projectService: projectService,
                        labourRegistrationService: LabourRegistrationService(),
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () async {
                  await SharedPrefsHelper.clear();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyCustomForm(
                              isDarkMode: isDarkMode,
                              onToggleTheme: onToggleTheme,
                            )),
                    (route) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
