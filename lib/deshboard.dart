import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:animated_widgets/widgets/scale_animated.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/labour_registration_page.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/observation_ncr.dart';
import 'package:himappnew/service/labour_registration_service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:himappnew/site_observation_quality.dart';
import 'package:himappnew/transaction/observation_quality_ncr.dart';
import 'package:himappnew/transaction/observation_safety_ncr.dart';
import 'login_page.dart';
import 'site_observation_safety.dart';
import 'package:himappnew/service/firebase_messaging_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';

class DashboardPage extends StatefulWidget {
  final String companyName;
  final String userName;
  final ProjectService projectService;
  final SiteObservationService siteObservationService;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

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
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final firebaseService = FirebaseMessagingService();
  int ongoingProjectsCount = 0;
  int safetyObservationsCount = 0;
  int qualityObservationsCount = 0;
  int pendingCount = 0;
  bool isLoading = true;
  int _unreadCount = 0;
  @override
  void initState() {
    super.initState();
    isLoading = true;
    _loadStats();
    _fetchUnreadCount(); // to show badge on start
  }

  Future<void> _loadStats() async {
    try {
      final userId = await SharedPrefsHelper.getUserId();
      if (userId != null) {
        final safety = await widget.siteObservationService
            .fatchSiteObservationSafetyByUserID(userId);
        final quality = await widget.siteObservationService
            .fatchSiteObservationQualityByUserID(userId);
        setState(() {
          safetyObservationsCount = safety.length;
          qualityObservationsCount = quality.length;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading stats: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUnreadCount() async {
    int? userId = await SharedPrefsHelper.getUserId();
    if (userId == null) return;

    // List<NotificationModel> notifications =
    //     await getNotificationsByUserID(userId);

    List<NotificationModel> notifications =
        await widget.siteObservationService.getNotificationsByUserID(userId!);

    final unread = notifications.where((n) => n.isMobileRead == false).toList();

    setState(() {
      _unreadCount = unread.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<NotificationModel> _dialogNotifications = [];
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Text("Dashboard - ${widget.companyName}"),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () async {
                  int? userId = await SharedPrefsHelper.getUserId();
                  // List<NotificationModel> notifications =
                  //     await getNotificationsByUserID(userId!);
                  List<NotificationModel> notifications = await widget
                      .siteObservationService
                      .getNotificationsByUserID(userId!);

                  setState(() {
                    _unreadCount = 0; // Mark as read in UI
                  });

                  _dialogNotifications = List.from(notifications);

                  showDialog(
                    context: context,
                    builder: (_) => StatefulBuilder(
                      builder: (context, setState) => AlertDialog(
                        title: Text("Notifications"),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: _dialogNotifications.isEmpty
                              ? Center(child: Text("No notifications"))
                              : ListView.builder(
                                  itemCount: _dialogNotifications.length,
                                  itemBuilder: (context, index) {
                                    final n = _dialogNotifications[index];
                                    return Card(
                                      elevation: 2,
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      child: ListTile(
                                        title: Text(n.programRowCode ??
                                            'ProgramRowCode'),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(n.programName ?? 'NoMessage'),
                                            Html(
                                                data:
                                                    n.notificationDescription ??
                                                        ''),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () async {
                                            int? userId =
                                                await SharedPrefsHelper
                                                    .getUserId();
                                            if (userId == null) return;

                                            final notificationId =
                                                _dialogNotifications[index].id;
                                            if (notificationId == null) return;
                                            bool success = await widget
                                                .siteObservationService
                                                .deleteNotification(
                                              notificationId
                                                  .toString(), // Convert to String if needed
                                              userId,
                                              AppSettings.DEVICEID[
                                                  'Mobile']!, // Device type
                                            );

                                            if (success) {
                                              setState(() {
                                                _dialogNotifications
                                                    .removeAt(index);
                                              });
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        "Failed to delete notification")),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        actions: [
                          TextButton(
                            child: Text("Close"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Theme toggle icon
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(widget.userName),
            const SizedBox(height: 20),
            _buildStatsCards(context),
            const SizedBox(height: 30),
            Center(
                // child: ElevatedButton.icon(
                //   onPressed: () async {
                //     await FirebaseMessaging.instance.requestPermission();
                //     final token = await FirebaseMessaging.instance.getToken();
                //     final userId = await SharedPrefsHelper.getUserId();
                //     if (token != null && userId != null) {
                //       await firebaseService.updateUserMobileAppTokenPut(
                //         userId: userId,
                //         webTokenID: "from_web_or_blank",
                //         mobileAppTokenID: token,
                //       );
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(content: Text('✅ Token updated on server')),
                //       );
                //     } else {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(
                //             content: Text('⚠️ Failed to get token or user ID')),
                //       );
                //     }
                //   },
                //   icon: Icon(Icons.notifications_active),
                //   label: Text("Save Notification Token"),
                // ),
                ),
          ],
        ),
      ),
    );
  }

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
            Text("Welcome back to ${widget.companyName}",
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    double cardSpacing = 16;

    final cards = [
      // _buildNeonGlassCard(
      //   icon: Icons.work,
      //   title: "Ongoing Projects",
      //   value: "12",
      //   color: Color(0xFF3A86FF),
      // ),
      GestureDetector(
        onTap: () async {
          final userId = await SharedPrefsHelper.getUserId();
          if (userId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ObservationSafetyNCRPage(
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
          title: "SiteObservations Safety",
          value: "$safetyObservationsCount",
          color: Color(0xFFFFB703),
        ),
      ),
      // _buildNeonGlassCard(
      //   icon: Icons.pending_actions,
      //   title: "Pending",
      //   value: "3",
      //   color: Color(0xFFFB5607),
      // ),
      GestureDetector(
        onTap: () async {
          final userId = await SharedPrefsHelper.getUserId();
          if (userId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ObservationQCNCRPage(
                  userId: userId,
                  siteObservationService: SiteObservationService(),
                  siteObservationId: 0,
                ),
              ),
            );
          }
        },
        child: _buildNeonGlassCard(
          icon: Icons.science,
          title: "Site Observation Quality",
          value: "$qualityObservationsCount",
          color: Color.fromARGB(255, 221, 57, 194),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: cardSpacing,
        crossAxisSpacing: cardSpacing,
        childAspectRatio: 5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
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
        bool isDark = Theme.of(context).brightness == Brightness.dark;

        double iconSize = screenWidth < 400 ? 26 : 32;
        double titleFontSize = screenWidth < 350
            ? 12
            : screenWidth < 400
                ? 13
                : 14;
        double valueFontSize;
        if (value.length > 3) {
          valueFontSize = 16; // zyada digit ho to font chhota kar do
        } else {
          valueFontSize = screenWidth < 400 ? 20 : 22;
        }

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
                  // padding: const EdgeInsets.all(12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment
                              .center, // ✅ Center it vertically
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Flexible(
                              child: Text(
                                value,
                                style: GoogleFonts.poppins(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: valueFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            children: [
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
                    Text(widget.companyName,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.blue),
                title: const Text('Dashboard'),
                onTap: () => Navigator.pop(context),
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
                        companyName: widget.companyName,
                        projectService: widget.projectService,
                        siteObservationService: widget.siteObservationService,
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
                        companyName: widget.companyName,
                        projectService: widget.projectService,
                        siteObservationService: widget.siteObservationService,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.green),
                title: const Text('Labour Registration'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabourRegistrationPage(
                        companyName: widget.companyName,
                        projectService: widget.projectService,
                        labourRegistrationService: LabourRegistrationService(),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.home_repair_service, color: Colors.purple),
                title: const Text('P & M Service Request'),
                // onTap: () {
                //   Navigator.pop(context);
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => PMServiceRequestPage(
                //         companyName: widget.companyName,
                //         projectService: widget.projectService,
                //       ),
                //     ),
                //   );
                // },
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
                      builder: (_) => MyCustomForm(
                        isDarkMode: widget.isDarkMode,
                        onToggleTheme: widget.onToggleTheme,
                      ),
                    ),
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
