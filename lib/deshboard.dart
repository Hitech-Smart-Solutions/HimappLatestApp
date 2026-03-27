import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:animated_widgets/widgets/scale_animated.dart';
import 'package:himappnew/awaitingapprovals/awaiting_approval_mris_page.dart';
import 'package:himappnew/change_password_page.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/labour_registration_page.dart';
import 'package:himappnew/model/page_permission.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/observation_ncr.dart';
import 'package:himappnew/service/app_update_service.dart';
import 'package:himappnew/service/labour_registration_service.dart';
import 'package:himappnew/service/material_requisition_slip_Service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/service/user_role_permission_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:himappnew/site_observation_quality.dart';
import 'package:himappnew/transaction/logbook.dart';
import 'package:himappnew/transaction/material_requisition_slip.dart';
import 'package:himappnew/transaction/observation_quality_ncr.dart';
import 'package:himappnew/transaction/observation_safety_ncr.dart';
import 'package:himappnew/transaction/observation_summary_quality.dart';
import 'package:himappnew/transaction/observation_summary_safety.dart';
import 'package:himappnew/ui/update_popup.dart';
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

  final PagePermissionService _permissionService = PagePermissionService();
  final MaterialRequisitionSlipService _materialIssueSlipService =
      MaterialRequisitionSlipService();
// Ye page permissions fetch ke liye
  List<PagePermission> pagePermissions = [];
  List<NotificationModel> _dialogNotifications = [];

// Module wise group ke liye
  Map<String, List<PagePermission>> moduleWisePages = {};

// Loading flag
  bool permissionLoading = true;
  final List<String> allowedModules = [
    "Safety",
    "Quality",
    "Store",
    "Analytics"
        "PlantAndMachinery"
  ];
  final allowedPrograms = {
    "Quality Observation",
    "Safety Observation",
    "MRIS",
    "Material Issue",
    "Safety Analytics",
    "Quality Analytics",
    "LogBook"
  };

  bool isAllowedProgram(String program) {
    final p = program.toLowerCase().trim();
    return p.contains("quality observation") ||
        p.contains("safety observation");
  }

  late Map<String, Widget Function()> appPages;

  int awaitingApprovalCount = 0;
  bool statsLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppUpdate();
    });
    isLoading = true;
    _loadStats();
    _fetchUnreadCount(); // to show badge on start
    _loadAwaitingApprovalCount();
    // Init appPages WITHOUT pagePermission
    appPages = {
      "Quality Observation": () => SiteObservationQuality(
            companyName: widget.companyName,
            projectService: widget.projectService,
            siteObservationService: widget.siteObservationService,
            pagePermission: PagePermission(
              programId: 0,
              companyId: 0,
              moduleId: 0,
              programName: '',
              isModuleAdmin: false,
              canAdd: false,
              canView: false,
              canEdit: false,
              canDelete: false,
              canExport: false,
              pageName: '',
              moduleName: '',
              iconName: '',
              moduleIconName: '',
              projectId: 0,
            ),
          ),
      "Safety Observation": () => SiteObservationSafety(
            companyName: widget.companyName,
            projectService: widget.projectService,
            siteObservationService: widget.siteObservationService,
            pagePermission: PagePermission(
              programId: 0,
              companyId: 0,
              moduleId: 0,
              programName: '',
              isModuleAdmin: false,
              canAdd: false,
              canView: false,
              canEdit: false,
              canDelete: false,
              canExport: false,
              pageName: '',
              moduleName: '',
              iconName: '',
              moduleIconName: '',
              projectId: 0,
            ),
          ),
      "Material Issue": () => MaterialRequisitionSlip(
            projectService: widget.projectService,
            pagePermission: PagePermission(
              programId: 0,
              companyId: 0,
              moduleId: 0,
              programName: 'MRIS',
              isModuleAdmin: false,
              canAdd: false,
              canView: false,
              canEdit: false,
              canDelete: false,
              canExport: false,
              pageName: 'MRIS',
              moduleName: 'Store',
              iconName: 'inventory',
              moduleIconName: 'store',
              projectId: 0,
            ),
          ),
      "Safety Analytics": () => ObservationSummarySafety(),
      "Quality Analytics": () => ObservationSummaryQuality(),
      "LogBook": () => LogBook()
    };

    _loadPermissions();
  }

  Future<void> _checkAppUpdate() async {
    final forceUpdate = await AppUpdateService.shouldForceUpdate();

    if (forceUpdate && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const UpdatePopup(),
      );
    }
  }

  Map<String, List<PagePermission>> _groupByModule(
      List<PagePermission> permissions) {
    final Map<String, List<PagePermission>> map = {};
    for (final p in permissions) {
      if (!map.containsKey(p.moduleName)) {
        map[p.moduleName] = [p];
      } else {
        // 🔥 Add only if programName not already in the list
        final exists =
            map[p.moduleName]!.any((e) => e.programName == p.programName);
        if (!exists) {
          map[p.moduleName]!.add(p);
        }
      }
    }

    return map;
  }

  Future<void> _loadPermissions() async {
    try {
      final userId = await SharedPrefsHelper.getUserId() ?? 0;
      debugPrint("Fetching permissions for userId: $userId");

      final permissions = await _permissionService.fetchPagePermissions(userId);

      // Debug: print all fetched permissions
      // for (final p in permissions) {
      //   debugPrint(
      //       "Permission fetched: ${p.programName}, Module: ${p.moduleName}, canView: ${p.canView}");
      // }

      final filtered = permissions.toList();
      final grouped = _groupByModule(filtered);

      setState(() {
        moduleWisePages = grouped;
        permissionLoading = false;
      });

      // Debug: print grouped map
      debugPrint("Grouped modules:");
      grouped.forEach((module, pages) {
        debugPrint(
            "Module: $module, Pages: ${pages.map((e) => e.programName).join(", ")}");
      });
    } catch (e) {
      debugPrint("Failed to load permissions: $e");
      setState(() {
        permissionLoading = false;
      });
    }
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

  Future<void> _loadAwaitingApprovalCount() async {
    try {
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) return;

      final data =
          await _materialIssueSlipService.getMaterialIssuesAwaitingApproval(
        userId,
        AppPages.materialIssueSlipProgramId,
      );

      setState(() {
        awaitingApprovalCount = data.length; // ✅ int
        statsLoading = false;
      });

      debugPrint("🟢 Awaiting Approval Count = $awaitingApprovalCount");
    } catch (e) {
      setState(() {
        statsLoading = false;
      });
      debugPrint("❌ Count Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  List<NotificationModel> notifications = await widget
                      .siteObservationService
                      .getNotificationsByUserID(userId!);

                  setState(() {
                    _unreadCount = 0; // Mark as read in UI
                    _dialogNotifications =
                        List.from(notifications); // ✅ IMPORTANT
                  });

                  _dialogNotifications = List.from(notifications);

                  showDialog(
                    context: context,
                    builder: (_) => StatefulBuilder(
                      builder: (context, dialogSetState) => AlertDialog(
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
                                            if (userId == null) {
                                              print("❌ userId null");
                                              return;
                                            }

                                            final notification =
                                                _dialogNotifications[index];
                                            final notificationId =
                                                notification.id;
                                            if (notificationId == null) {
                                              print("❌ notificationId null");
                                              return;
                                            }

                                            bool success = await widget
                                                .siteObservationService
                                                .deleteNotification(
                                              notificationId.toString(),
                                              userId,
                                              AppSettings.DEVICEID['Mobile']!,
                                            );
                                            if (success) {
                                              // ✅ Dialog UI update
                                              dialogSetState(() {
                                                _dialogNotifications
                                                    .removeAt(index);
                                              });

                                              // ✅ Badge / parent UI update
                                              if (notification.isMobileRead ==
                                                  false) {
                                                setState(() {
                                                  _unreadCount = (_unreadCount -
                                                          1)
                                                      .clamp(0, _unreadCount);
                                                });
                                              }
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content:
                                                      Text("❌ Delete failed"),
                                                ),
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
                          // ✅ CLEAR ALL BUTTON
                          TextButton(
                            child: const Text("Clear All"),
                            onPressed: () async {
                              int? userId = await SharedPrefsHelper.getUserId();
                              if (userId == null) return;

                              // copy list to avoid index crash
                              final List<NotificationModel> unreadList =
                                  List.from(_dialogNotifications);

                              for (final n in unreadList) {
                                if (n.id == null) continue;

                                await widget.siteObservationService
                                    .deleteNotification(
                                  n.id.toString(),
                                  userId,
                                  AppSettings.DEVICEID['Mobile']!,
                                );
                              }

                              // UI update (same as web optimistic update)
                              dialogSetState(() {
                                _dialogNotifications.clear();
                              });

                              setState(() {
                                _unreadCount = 0;
                              });

                              print("🧹 CLEAR ALL DONE (WEB LOGIC)");
                            },
                          ),

                          // ❌ CLOSE BUTTON (already tha)
                          TextButton(
                            child: const Text("Close"),
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
            Center(),
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
      GestureDetector(
        onTap: () async {
          final userId = await SharedPrefsHelper.getUserId();
          if (userId != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ObservationSafetyNCRPage(
                  userId: userId,
                  siteObservationService: SiteObservationService(),
                  siteObservationId: 0,
                ),
              ),
            );

            if (result == true) {
              _loadStats();
            }
          }
        },
        child: _buildNeonGlassCard(
          icon: Icons.visibility,
          title: "Site Observations Safety",
          value: "$safetyObservationsCount",
          color: Color(0xFFFFB703),
        ),
      ),
      GestureDetector(
        onTap: () async {
          final userId = await SharedPrefsHelper.getUserId();
          if (userId != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ObservationQCNCRPage(
                  userId: userId,
                  siteObservationService: SiteObservationService(),
                  siteObservationId: 0,
                ),
              ),
            );

            if (result == true) {
              _loadStats(); // 🔁 dashboard count refresh
            }
          }
        },
        child: _buildNeonGlassCard(
          icon: Icons.science,
          title: "Site Observation Quality",
          value: "$qualityObservationsCount",
          color: Color.fromARGB(255, 221, 57, 194),
        ),
      ),
      GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AwaitingApprovalMrisPage(),
            ),
          );

          // 🔥 jab AwaitingApproval se wapas aaye
          _loadAwaitingApprovalCount();
        },
        child: _buildNeonGlassCard(
          icon: Icons.assignment_turned_in,
          title: "MRIS Awaiting Approval",
          value: statsLoading ? "..." : awaitingApprovalCount.toString(),
          color: const Color(0xFF38B000),
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

  Widget _buildHeader(String userName) {
    return DrawerHeader(
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
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          Text(widget.companyName,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final grouped = moduleWisePages;
    final allowedModules = [
      "Safety",
      "Quality",
      "Store",
      "Analytics",
      "PlantAndMachinery"
    ];
    final allowedPrograms = [
      "Safety Observation",
      "Quality Observation",
      "MRIS",
      "Material Issue",
      "Safety Analytics",
      "Quality Analytics",
      "LogBook"
    ];
    final filteredModules = moduleWisePages.entries
        .where((entry) => allowedModules.contains(entry.key))
        .map((entry) => MapEntry(entry.key, entry.value))
        .toList();
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(widget.userName),
          ...moduleWisePages.entries
              // 🔹 Filter modules
              .where((entry) => allowedModules.contains(entry.key))
              .map((entry) {
            return ExpansionTile(
              title: Text(entry.key),
              children: entry.value
                  // 🔹 Filter pages inside module
                  .where((p) => allowedPrograms.contains(p.programName))
                  .map((p) {
                final isDisabled = !p.canView; // grey + disable if no view
                return _subTile(
                  icon: getPageIcon(p.programName),
                  color: isDisabled ? Colors.grey : Colors.orange,
                  title: p.programName,
                  onTap: isDisabled
                      ? null
                      : () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => resolvePage(p)),
                          );
                        },
                );
              }).toList(),
            );
          }).toList(),
          // _drawerTile(
          //   icon: Icons.receipt_long,
          //   color: Colors.blue,
          //   title: "Material Requisition Slip",
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => MaterialRequisitionSlip(
          //           projectService: widget.projectService,
          //           pagePermission: PagePermission(
          //             programId: 0,
          //             companyId: 0,
          //             moduleId: 0,
          //             programName: 'MRIS',
          //             isModuleAdmin: false,
          //             canAdd: false,
          //             canView: true, // view permission for MRIS
          //             canEdit: false,
          //             canDelete: false,
          //             canExport: false,
          //             pageName: 'MRIS',
          //             moduleName: 'Store',
          //             iconName: 'inventory',
          //             moduleIconName: 'store',
          //             projectId: 0,
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),
          // _drawerTile(
          //   icon: Icons.shield,
          //   color: Colors.orange,
          //   title: "Safety Observation Summary",
          //   onTap: () async {
          //     Navigator.pop(context); // close drawer

          //     final int? userId = await SharedPrefsHelper.getUserId();

          //     if (userId == null) {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text('User not logged in')),
          //       );
          //       return;
          //     }

          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => ObservationSummarySafety(),
          //       ),
          //     );
          //   },
          // ),
          // _drawerTile(
          //   icon: Icons.assessment,
          //   color: Colors.orange,
          //   title: "Quality Observation Summary",
          //   onTap: () async {
          //     Navigator.pop(context); // close drawer

          //     final int? userId = await SharedPrefsHelper.getUserId();

          //     if (userId == null) {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text('User not logged in')),
          //       );
          //       return;
          //     }

          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => ObservationSummaryQuality(),
          //       ),
          //     );
          //   },
          // ),
          const Divider(),
          _drawerTile(
            icon: Icons.lock_reset,
            color: Colors.orange,
            title: "Change Password",
            onTap: () async {
              Navigator.pop(context); // close drawer

              final int? userId = await SharedPrefsHelper.getUserId();

              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not logged in')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordPage(
                    userId: userId,
                    companyName: widget.companyName,
                    userName: widget.userName,
                    isDarkMode: widget.isDarkMode,
                    onToggleTheme: widget.onToggleTheme,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _drawerTile(
            icon: Icons.logout,
            color: Colors.red,
            title: "Logout",
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
      ),
    );
  }

// // New code
//   IconData getModuleIcon(String module) {
//     switch (module.toLowerCase()) {
//       case 'safety':
//         return Icons.health_and_safety;
//       case 'quality':
//         return Icons.science;
//       case 'store':
//         return Icons.receipt_long;
//       case 'admin':
//         return Icons.admin_panel_settings;
//       case 'p & m':
//         return Icons.home_repair_service;
//       default:
//         return Icons.apps;
//     }
//   }

  IconData getPageIcon(String pageName) {
    // print("Getting icon for page: $pageName");
    switch (pageName) {
      case "Safety Observation":
        return Icons.visibility;
      case "Quality Observation":
        return Icons.fact_check;
      case "Material Issue":
        return Icons.receipt_long;
      case "Safety Analytics":
        return Icons.shield;
      case "Quality Analytics":
        return Icons.assessment;
      case "LogBook":
        return Icons.assessment;
      case "Labour Registration":
        return Icons.person_add_alt_1;
      default:
        return Icons.arrow_right;
    }
  }

  Widget resolvePage(PagePermission p) {
    print("Resolving page for program: ${p.programName}");
    switch (p.programName) {
      case "Safety Observation":
        return SiteObservationSafety(
          companyName: widget.companyName,
          projectService: widget.projectService,
          siteObservationService: widget.siteObservationService,
          pagePermission: p,
        );
      case "Quality Observation": // 🔥 updated
        return SiteObservationQuality(
          companyName: widget.companyName,
          projectService: widget.projectService,
          siteObservationService: widget.siteObservationService,
          pagePermission: p,
        );
      case "Material Issue": // 🔥 updated
        return MaterialRequisitionSlip(
          projectService: widget.projectService,
          pagePermission: p,
        );
      case "Safety Analytics":
        return ObservationSummarySafety();
      case "Quality Analytics":
        return ObservationSummaryQuality();
      case "LogBook":
        return LogBook();
      case "Labour Registration":
        return LabourRegistrationPage(
          companyName: widget.companyName,
          projectService: widget.projectService,
          labourRegistrationService: LabourRegistrationService(),
        );
      default:
        return Scaffold(
          body: Center(child: Text("Page not implemented yet")),
        );
    }
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: _iconBox(icon, color),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  Widget _subTile({
    required IconData icon,
    required Color color,
    required String title,
    VoidCallback? onTap, // 🔹 nullable
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: _iconBox(icon, color),
        title: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
        onTap: onTap, // null allowed
      ),
    );
  }
}
