import 'package:animated_widgets/widgets/translation_animated.dart';
import 'package:flutter/material.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'login_page.dart';
import 'site_observation_page.dart';

class DashboardPage extends StatelessWidget {
  final String companyName;
  final String userName;
  final ProjectService projectService;
  final SiteObservationService siteObservationService;

  const DashboardPage({
    super.key,
    required this.companyName,
    required this.userName,
    required this.projectService,
    required this.siteObservationService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Text("Dashboard - $companyName"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(userName),
            SizedBox(height: 20),
            _buildStatsCards(context),
            SizedBox(height: 20),
            Text("Recent Observations",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildRecentObservations(),
            SizedBox(height: 20),
            Text("Reminders",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildRemindersList(),
          ],
        ),
      ),
    );
  }

  // Greeting Card with User Name and Avatar
  Widget _buildGreetingCard(String userName) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage("images/profile.png"),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, $userName!", style: TextStyle(fontSize: 18)),
            Text("Welcome back to $companyName",
                style: TextStyle(fontSize: 14, color: Colors.grey)),
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
        _buildStatCard(
            "Ongoing Projects", "12", Icons.work, Colors.blue, cardWidth, 0),
        _buildStatCard("Site Observations", "5", Icons.visibility,
            Colors.orange, cardWidth, 200),
        _buildStatCard("Pending Approvals", "3", Icons.pending_actions,
            Colors.red, cardWidth, 400),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      double width, int delay) {
    return TranslationAnimatedWidget.tween(
      enabled: true,
      duration: Duration(milliseconds: 600 + delay),
      translationDisabled: Offset(0, 50),
      translationEnabled: Offset(0, 0),
      child: SizedBox(
        width: width,
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(icon, color: Colors.white),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    SizedBox(height: 4),
                    Text(value,
                        style: TextStyle(
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
    );
  }

  // Recent Site Observations List
  Widget _buildRecentObservations() {
    return Column(
      children: List.generate(3, (index) {
        return ListTile(
          leading: Icon(Icons.warning, color: Colors.orange),
          title: Text("Observation #${index + 1}"),
          subtitle: Text("Site: ABC, Status: Pending"),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        );
      }),
    );
  }

  // Reminders List
  Widget _buildRemindersList() {
    return Column(
      children: List.generate(3, (index) {
        return ListTile(
          leading: Icon(Icons.calendar_today, color: Colors.blue),
          title: Text("Inspection at Site XYZ"),
          subtitle: Text("Due: Tomorrow"),
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
          String userName = "User";
          if (snapshot.hasData && snapshot.data != null) {
            userName = snapshot.data!;
          }

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
                      backgroundImage: AssetImage(
                          "images/profile.png"), // Add your profile image in assets
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userName,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      companyName,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.blue),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment, color: Colors.orange),
                title: const Text('Site Observation'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SiteObservationPage(
                        companyName: companyName,
                        projectService: projectService,
                        siteObservationService: siteObservationService,
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
                        builder: (context) => const MyCustomForm()),
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
