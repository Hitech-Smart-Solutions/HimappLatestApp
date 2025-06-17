import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
import 'package:himappnew/service/firebase_messaging_service.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatelessWidget {
  final String companyName;
  final String userName;
  final ProjectService projectService;
  final SiteObservationService siteObservationService;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final firebaseService = FirebaseMessagingService();

  DashboardPage({
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
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseMessaging.instance.requestPermission();
                  final token = await FirebaseMessaging.instance.getToken();
                  print("📱 Firebase Token Dash oard: $token");
                  final userId = await SharedPrefsHelper.getUserId();
                  print('UserIDDDDD : $userId');
                  if (token != null && userId != null) {
                    await firebaseService.updateUserMobileAppTokenPut(
                      userId: userId,
                      webTokenID: "from_web_or_blank",
                      mobileAppTokenID: token,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ Token updated on server')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('⚠️ Failed to get token or user ID')),
                    );
                  }
                },
                icon: Icon(Icons.notifications_active),
                label: Text("Save Notification Token"),
              ),
            ),
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
    double horizontalPadding = 16 * 2; // Scaffold padding
    double cardSpacing = 16;

    // Card width calculation (optional, for reference)
    double cardWidth = (screenWidth - horizontalPadding - cardSpacing) / 2;

    final cards = [
      _buildNeonGlassCard(
        icon: Icons.work,
        title: "Ongoing Projects",
        value: "12",
        color: Color(0xFF3A86FF),
      ),

      GestureDetector(
        onTap: () async {
          final userId = await SharedPrefsHelper.getUserId();
          if (userId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ObservationNCRPage(
                  userId: userId,
                  siteObservationService: SiteObservationService(),
                  siteObservationId: 0,
                ),
              ),
            );
          }
        },
        child: _buildNeonGlassCard(
          icon: Icons.visibility,
          title: "Observations",
          value: "5",
          color: Color(0xFFFFB703),
        ),
      ),
      _buildNeonGlassCard(
        icon: Icons.pending_actions,
        title: "Pending",
        value: "3",
        color: Color(0xFFFB5607),
      ),
      _buildNeonGlassCard(
        icon: Icons.science,
        title: "SiteObservation Quality",
        value: "5",
        color: Color.fromARGB(255, 221, 57, 194),
      ),
      // Aap aur cards yaha add kar sakte ho
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics:
          NeverScrollableScrollPhysics(), // Scroll only the parent ScrollView
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Har row me 2 cards
        mainAxisSpacing: cardSpacing,
        crossAxisSpacing: cardSpacing,
        childAspectRatio:
            2.5, // Card ka width/height ratio (adjust karo apne design ke hisab se)
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return cards[index];
      },
    );
  }

  Widget _buildNeonGlassCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = MediaQuery.of(context).size.width;

        // Theme check
        bool isDark = Theme.of(context).brightness == Brightness.dark;

        // Responsive sizes
        double iconSize = screenWidth < 400 ? 26 : 32;
        double titleFontSize = screenWidth < 400 ? 13 : 14;
        double valueFontSize = screenWidth < 400 ? 20 : 22;

        return ScaleAnimatedWidget.tween(
          enabled: true,
          duration: const Duration(milliseconds: 150),
          scaleEnabled: 0.97,
          scaleDisabled: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withOpacity(0.3), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.6),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: isDark ? Colors.white : Colors.black,
                          size: iconSize,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              value,
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: valueFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
