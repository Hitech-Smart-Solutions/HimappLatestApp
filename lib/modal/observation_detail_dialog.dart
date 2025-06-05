import 'dart:io';
import 'package:flutter/material.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:flutter/services.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_mentions/flutter_mentions.dart';

class ObservationDetailDialog extends StatefulWidget {
  final GetSiteObservationMasterById detail;
  final SiteObservationService siteObservationService;
  final int siteObservationId;
  // final int activityId;
  // final int projectId;
  const ObservationDetailDialog({
    super.key,
    required this.detail,
    required this.siteObservationService,
    required this.siteObservationId,
    // required this.activityId
    // required this.projectId,
  });

  @override
  State<ObservationDetailDialog> createState() =>
      _ObservationDetailDialogState();
}

class _ObservationDetailDialogState extends State<ObservationDetailDialog> {
  // String selectedStatus = 'Open';
  bool isEditingRootCause = false;

  List<Map<String, String>> observationStatus = [];
  String? selectedStatus;
  bool isStatusEnabled = false;
  String url = AppSettings.url;

  List<User> selectedUsers = [];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController rootCauseController = TextEditingController();
  final TextEditingController reworkCostController = TextEditingController();
  final TextEditingController preventiveActionController =
      TextEditingController();
  final TextEditingController correctiveActionController =
      TextEditingController();
  final TextEditingController _activityCommentController =
      TextEditingController();

  late int editingUserId;
  bool assigned = true;
  List<ActivityDTO> activities = [];
  final GlobalKey<FlutterMentionsState> mentionsKey =
      GlobalKey<FlutterMentionsState>();

  List<Map<String, String>> userList = [];
  List<User> allUsers = [];
  List<RootCause> rootCauses = [];
  RootCause? selectedRootCause;
  bool isLoading = false;

  // final int activityId;
  int? activityIds = 0; // Default value, can be set later
  int? userId;

  List<String> uploadedFiles = [];
  bool isButtonDisabled = false;
  @override
  void initState() {
    super.initState();
    _loadActivityByCompanyIdAndScreenTypeId();
    _loadRootCauses();
    final int statusId = int.tryParse(widget.detail.statusName ?? '') ?? 0;
    if (statusId != 0) {
      setObservationStatusDropdown(
        statusId,
        widget.detail.assignedUserID != null &&
            widget.detail.assignedUserID != 0,
      );
    } else {
      print("⚠️ Invalid status ID string: ${widget.detail.statusName}");
    }

    editingUserId = widget.siteObservationId;
    initData();
  }

  Future<void> initData() async {
    int? projectId = await SharedPrefsHelper.getProjectID();
    if (projectId == null) {
      return;
    }
    await fetchUsers(); // Only fetch after getting valid ProjectID
    userId = await SharedPrefsHelper.getUserId();
  }

  @override
  void dispose() {
    rootCauseController.dispose();
    reworkCostController.dispose();
    preventiveActionController.dispose();
    correctiveActionController.dispose();
    super.dispose();
  }

  // void _sendActivityComment() async {
  //   try {
  //     final markupText = mentionsKey.currentState?.controller!.markupText ?? "";
  //     final RegExp mentionRegex = RegExp(r'\@\[(.*?)\]\((.*?)\)');
  //     final Iterable<RegExpMatch> matches = mentionRegex.allMatches(markupText);

  //     List<User> selectedUsers = matches.map((match) {
  //       final displayName = match.group(2)!;
  //       final rawIdOrDisplay = match.group(1)!;
  //       final cleanedIdStr = rawIdOrDisplay.replaceAll(RegExp(r'\D'), '');
  //       int userId = int.tryParse(cleanedIdStr) ?? 0;
  //       return User(id: userId, userName: displayName);
  //     }).toList();

  //     List<ActivityDTO> activities = [];

  //     int? createdBy = await SharedPrefsHelper.getUserId();

  //     for (var user in selectedUsers) {
  //       activities.add(ActivityDTO(
  //         id: 0,
  //         siteObservationID: widget.editingUserId,
  //         actionID: SiteObservationActions.Assigned,
  //         actionName: "Assigned",
  //         comments: "",
  //         documentName: "",
  //         fromStatusID: 0,
  //         toStatusID: 0,
  //         assignedUserID: user.id,
  //         assignedUserName: user.userName,
  //         createdBy: createdBy.toString(),
  //         createdDate: DateTime.now(),
  //       ));
  //     }

  //     if (_activityCommentController.text.trim().isNotEmpty) {
  //       activities.add(ActivityDTO(
  //         id: 0,
  //         siteObservationID: widget.editingUserId,
  //         actionID: SiteObservationActions.Commented,
  //         actionName: "Commented",
  //         comments: _activityCommentController.text.trim(),
  //         documentName: "",
  //         fromStatusID: 0,
  //         toStatusID: 0,
  //         assignedUserID: 0,
  //         assignedUserName: null,
  //         createdBy: createdBy.toString(),
  //         createdDate: DateTime.now(),
  //       ));
  //     }

  //     bool success = await SiteObservationService().sendSiteObservationActivity(
  //       activities: activities,
  //       siteObservationID: widget.editingUserId,
  //     );

  //     if (success) {
  //       // ✅ Clear input
  //       mentionsKey.currentState?.controller!.clear();
  //       _activityCommentController.clear();

  //       // ✅ Push to ListView
  //       setState(() {
  //         widget.detail.activityDTO.insertAll(0, activities); // Add to top
  //       });

  //       print("✅ Successfully posted activity!");
  //     }
  //   } catch (e, stack) {
  //     print("❌ Error in _sendActivityComment: $e");
  //     print(stack);
  //   }
  // }

  Future<void> _sendActivityComment() async {
    try {
      final markupText = mentionsKey.currentState?.controller!.markupText ?? "";
      final RegExp mentionRegex = RegExp(r'\@\[(.*?)\]\((.*?)\)');
      final Iterable<RegExpMatch> matches = mentionRegex.allMatches(markupText);

      List<User> selectedUsers = matches.map((match) {
        String rawIdStr = match.group(1)!;
        String rawUserName = match.group(2)!;

        String cleanedIdStr = rawIdStr.replaceAll('_', '');
        String cleanedUserName = rawUserName.replaceAll('_', '');

        int userId = int.tryParse(cleanedIdStr) ?? 0;

        final matchedUser = allUsers.firstWhere(
          (user) => user.id == userId,
          orElse: () => User(id: 0, userName: ''),
        );

        String finalUserName = matchedUser.userName.isNotEmpty
            ? matchedUser.userName
            : cleanedUserName;

        return User(id: userId, userName: finalUserName);
      }).toList();

      int? createdBy = await SharedPrefsHelper.getUserId();

      List<ActivityDTO> activities = [];

      final commentText =
          mentionsKey.currentState?.controller?.text.trim() ?? "";

      // Remove mentions to get only the actual comment text
      final plainComment =
          commentText.replaceAll(RegExp(r'\@\[(.*?)\]\((.*?)\)'), '').trim();

      bool hasMentions = selectedUsers.isNotEmpty;
      bool hasComment = plainComment.isNotEmpty;

      // 1) Agar sirf mention hai (comment empty) → assigned activity banega
      if (hasMentions && !hasComment) {
        for (var user in selectedUsers) {
          activities.add(ActivityDTO(
            id: 0,
            siteObservationID: editingUserId,
            actionID: SiteObservationActions.Assigned,
            actionName: "Assigned",
            comments: "",
            documentName: "",
            fromStatusID: 0,
            toStatusID: 0,
            assignedUserID: user.id,
            assignedUserName: user.userName,
            createdBy: createdBy.toString(),
            createdDate: DateTime.now(),
          ));
        }
      }

      // 2) Agar sirf comment hai (mention nahi) → comment activity banega
      else if (!hasMentions && hasComment) {
        activities.add(ActivityDTO(
          id: 0,
          siteObservationID: editingUserId,
          actionID: SiteObservationActions.Commented,
          actionName: "Commented",
          comments: plainComment,
          documentName: "",
          fromStatusID: 0,
          toStatusID: 0,
          assignedUserID: 0,
          createdBy: createdBy.toString(),
          createdDate: DateTime.now(),
        ));
      }

      // 3) Agar dono mention + comment hain → dono activities banenge
      else if (hasMentions && hasComment) {
        for (var user in selectedUsers) {
          activities.add(ActivityDTO(
            id: 0,
            siteObservationID: editingUserId,
            actionID: SiteObservationActions.Assigned,
            actionName: "Assigned",
            comments: "",
            documentName: "",
            fromStatusID: 0,
            toStatusID: 0,
            assignedUserID: user.id,
            assignedUserName: user.userName,
            createdBy: createdBy.toString(),
            createdDate: DateTime.now(),
          ));
        }

        activities.add(ActivityDTO(
          id: 0,
          siteObservationID: editingUserId,
          actionID: SiteObservationActions.Commented,
          actionName: "Commented",
          comments: plainComment,
          documentName: "",
          fromStatusID: 0,
          toStatusID: 0,
          assignedUserID: 0,
          createdBy: createdBy.toString(),
          createdDate: DateTime.now(),
        ));
      }

      // Agar dono mention aur comment nahi hain, activities empty hain, kuch nahi karna

      print("Activities to send: $commentText");
      if (activities.isEmpty) {
        print("No valid activity to send.");
        return;
      }

      bool success = await SiteObservationService().sendSiteObservationActivity(
        activities: activities,
        siteObservationID: editingUserId,
      );

      if (success) {
        print("✅ Successfully posted activity!");
        mentionsKey.currentState?.controller?.clear();
        _activityCommentController.clear();

        setState(() {
          widget.detail.activityDTO.insertAll(0, activities);
        });
      } else {
        print("❌ Failed to post activity!");
      }
    } catch (e, st) {
      print("Error in _sendActivityComment: $e");
      print(st);
    }
  }

  void setObservationStatusDropdown(int statusId, bool assigned) {
    observationStatus = [];
    selectedStatus = null;
    isStatusEnabled = true;

    switch (statusId) {
      case SiteObservationStatus.Completed:
        observationStatus = [
          {
            "id": SiteObservationStatus.Completed.toString(),
            "name": "Completed"
          }
        ];
        selectedStatus = SiteObservationStatus.Completed.toString();
        isStatusEnabled = false;
        break;

      case SiteObservationStatus.ReadyToInspect:
        if (assigned) {
          observationStatus = [
            {
              "id": SiteObservationStatus.Completed.toString(),
              "name": "Completed"
            },
            {"id": SiteObservationStatus.Reopen.toString(), "name": "Reopen"}
          ];
          selectedStatus = null;
          isStatusEnabled = true;
        } else {
          observationStatus = [
            {
              "id": SiteObservationStatus.ReadyToInspect.toString(),
              "name": "Ready To Inspect"
            }
          ];
          selectedStatus = SiteObservationStatus.ReadyToInspect.toString();
          isStatusEnabled = false;
        }
        break;

      case SiteObservationStatus.Open:
        observationStatus = [
          {"id": SiteObservationStatus.Open.toString(), "name": "Open"},
          {
            "id": SiteObservationStatus.InProgress.toString(),
            "name": "In Progress"
          },
          {
            "id": SiteObservationStatus.ReadyToInspect.toString(),
            "name": "Ready To Inspect"
          },
        ];
        selectedStatus = SiteObservationStatus.Open.toString();
        isStatusEnabled = true;
        break;

      default:
        observationStatus = [
          {
            "id": SiteObservationStatus.InProgress.toString(),
            "name": "In Progress"
          },
          {
            "id": SiteObservationStatus.ReadyToInspect.toString(),
            "name": "Ready To Inspect"
          },
        ];
        selectedStatus = statusId.toString();
        isStatusEnabled = true;
        break;
    }
  }

  fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      int? projectID = await SharedPrefsHelper.getProjectID();
      if (projectID == null) throw Exception("Project ID not found");

      final response = await SiteObservationService().fetchUsersForList(
        projectId: projectID,
      );

      setState(() {
        userList = response
            .map((u) => {
                  'id': u.id.toString(),
                  'display': u.userName,
                  'full_name': '${u.firstName} ${u.lastName}',
                })
            .toList();
      });
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  UpdateSiteObservation getUpdatedDataFromForm(List<String> uploadedFiles) {
    int id = widget.detail.id;
    int rootCauseID = selectedRootCause?.id ?? 0;

    List<ActivityDTO> activities = [];

    // Assigned action (static entry like Angular)
    activities.add(
      ActivityDTO(
        id: 0,
        siteObservationID: id,
        actionID: SiteObservationActions.Assigned,
        actionName: '', // ✅ Required field
        comments: '',
        documentName: '',
        fromStatusID: 0,
        toStatusID: SiteObservationStatus.ReadyToInspect,
        assignedUserID: widget.detail.createdBy,
        assignedUserName: null, // Optional
        createdBy: userId!.toString(), // ✅ createdBy is a String in your model
        createdDate: DateTime.now(),
      ),
    );

    // Add file uploads if available
    for (String fileName in uploadedFiles) {
      activities.add(
        ActivityDTO(
          id: 0,
          siteObservationID: id,
          actionID: SiteObservationActions.DocUploaded,
          actionName: '', // ✅ Must provide even if empty
          comments: '',
          documentName: fileName,
          fromStatusID: 0,
          toStatusID: 0,
          assignedUserID: userId!,
          assignedUserName: null,
          createdBy: userId!.toString(), // ✅ Ensure it's a String
          createdDate: DateTime.now(),
        ),
      );
    }

    return UpdateSiteObservation(
      id: id,
      rootCauseID: rootCauseID,
      corretiveActionToBeTaken: correctiveActionController.text,
      preventiveActionTaken: preventiveActionController.text,
      reworkCost: int.tryParse(reworkCostController.text) ?? 0,
      statusID: 3,
      lastModifiedBy: userId!,
      lastModifiedDate: DateTime.now(),
      activityDTO: activities,
    );
  }

  Future<void> _loadActivityByCompanyIdAndScreenTypeId() async {
    setState(() => isLoading = true);
    try {
      int? companyId = await SharedPrefsHelper.getCompanyId();
      int functionID = ScreenTypes.Safety;

      List<Activity> activities = await SiteObservationService()
          .fatchActivityByCompanyIdAndScreenTypeId(companyId!, functionID);

      if (activities.isNotEmpty) {
        activityIds = activities.first.id; // 👈 yahi Angular jaisa kaam hai
        await _loadRootCauses(); // root cause load karo single ID ke liye
      }

      await _loadRootCauses(); // ✅ wait for loading
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load activities: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadRootCauses() async {
    if (activityIds == null) return; // safety check

    setState(() => isLoading = true);
    try {
      rootCauses = await SiteObservationService()
          .fatchRootCausesByActivityID(activityIds!);
      // print("Fetched root causes: ${rootCauses.length}");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load root causes: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print("selectedStatus: $selectedStatus");
    print(
        "Dropdown items: ${observationStatus.map((e) => e['id'].toString()).toList()}");
    final media = MediaQuery.of(context);
    print("Dropdown items count: ${observationStatus.length}");

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: media.size.width * 0.9,
        height: media.size.height * 0.8, // 80% of screen height for more space
        child: DefaultTabController(
          length: 3,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.detail.observationCode,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white),
                        ),
                      ),
                      Expanded(
                          child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        hint: const Text("-- Status --"),
                        isExpanded: true,
                        items: observationStatus.map((status) {
                          String idStr = status['id'].toString();
                          int? id = int.tryParse(idStr);
                          String name = SiteObservationStatus.idToName[id] ??
                              status['name'] ??
                              '';

                          return DropdownMenuItem<String>(
                            value: idStr,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: isStatusEnabled
                            ? (newValue) {
                                setState(() {
                                  selectedStatus = newValue!;
                                });
                              }
                            : null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a status';
                          }
                          return null;
                        },
                      )),
                    ],
                  ),
                ),

                const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: "Details"),
                    Tab(text: "Attachments"),
                    Tab(text: "Activity"),
                  ],
                ),

                // Use Expanded + SingleChildScrollView with Column instead of ListView for smooth scrolling
                Expanded(
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status
                                RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      const TextSpan(
                                        text: 'Status: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: observationStatus.firstWhere(
                                            (element) =>
                                                element['id'] == selectedStatus,
                                            orElse: () =>
                                                {'name': 'Unknown'})['name'],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Description - full width (col-md-12)
                                RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      const TextSpan(
                                        text: 'Description: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                          text: widget.detail.description ??
                                              'N/A'),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Now 6 rows with 2 columns each (col-md-6)
                                _buildTwoColumnRow(
                                    'Observation Date',
                                    widget.detail.trancationDate,
                                    'Created Date',
                                    widget.detail.createdDate),

                                _buildTwoColumnRow(
                                    'Observation Type',
                                    widget.detail.observationType,
                                    'Issue Type',
                                    widget.detail.issueType),

                                _buildTwoColumnRow(
                                    'Due Date',
                                    widget.detail.dueDate,
                                    'Activity',
                                    widget.detail.activityName),

                                _buildTwoColumnRow(
                                    'Section',
                                    widget.detail.sectionName,
                                    'Floor',
                                    widget.detail.floorName),

                                _buildTwoColumnRow(
                                    'Part',
                                    widget.detail.partName,
                                    'Element',
                                    widget.detail.elementName),

                                _buildTwoColumnRow(
                                    'Contractor',
                                    widget.detail.contractorName,
                                    'Compliance Required',
                                    widget.detail.complianceRequired),

                                // If you want, you can add more rows below similarly...

                                const SizedBox(height: 24),

                                if (selectedStatus ==
                                        SiteObservationStatus.ReadyToInspect
                                            .toString() ||
                                    selectedStatus ==
                                        SiteObservationStatus.InProgress
                                            .toString())
                                  Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "Root Cause Details",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () {
                                                  setState(() {
                                                    isEditingRootCause = true;
                                                  });
                                                },
                                              )
                                            ],
                                          ),
                                          if (!isEditingRootCause)
                                            const Text(
                                                "Root Cause info here...")
                                          else
                                            _buildRootCauseForm(),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Attachments Tab
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? pickedFile = await picker
                                    .pickImage(source: ImageSource.gallery);

                                if (pickedFile != null) {
                                  File imageFile = File(pickedFile.path);

                                  final uploadedFileName =
                                      await SiteObservationService()
                                          .uploadFile(imageFile);

                                  if (uploadedFileName != null) {
                                    setState(() {
                                      widget.detail.activityDTO.add(
                                        ActivityDTO(
                                          id: 0,
                                          siteObservationID: widget.detail.id,
                                          actionID: 0,
                                          actionName: '',
                                          comments: '',
                                          documentName: uploadedFileName,
                                          fromStatusID: 0,
                                          toStatusID: 0,
                                          assignedUserID: 0,
                                          assignedUserName: null,
                                          createdBy: 'You',
                                          createdDate: DateTime.now(),
                                        ),
                                      );
                                    });

                                    /// 👇👇 Yahan Add Karo Update Call 👇👇
                                    UpdateSiteObservation updatedData =
                                        getUpdatedDataFromForm(uploadedFiles);
                                    // print(
                                    //     "Updating with activities count: ${updatedData.activityDTO.length}");
                                    updatedData.activityDTO.forEach((act) {
                                      // print(
                                      //     "Activity siteObservationID: ${act.siteObservationID}, documentName: ${act.documentName}");
                                    });
                                    bool success =
                                        await SiteObservationService()
                                            .updateSiteObservationByID(
                                                updatedData);

                                    if (success) {
                                      // print(
                                      //     "✅ Update successful after file upload");
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "File uploaded and updated successfully!")),
                                      );
                                    } else {
                                      // print(
                                      //     "❌ Failed to update after file upload");
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Upload done but update failed!")),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Upload failed.")),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Upload Image"),
                            ),
                            const SizedBox(height: 16),
                            widget.detail.activityDTO.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: widget.detail.activityDTO
                                        .map((activity) {
                                      if (activity.documentName.isEmpty)
                                        return const SizedBox();

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: GestureDetector(
                                          onTap: () {
                                            openImageModal(
                                                activity.documentName);
                                          },
                                          child: Container(
                                            height: 150,
                                            width: 150,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: SizedBox(
                                              height:
                                                  150, // 👈 Image ki height fix
                                              width: double.infinity,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  isImage(activity.documentName)
                                                      ? "$url/${activity.documentName}"
                                                      : "assets/default-image.png",
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const Icon(
                                                          Icons.broken_image),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : const Center(
                                    child: Text("No attachments available.")),
                          ],
                        ),
                      ),

                      // Activity Tab
                      Portal(
                          child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(children: [
                            widget.detail.activityDTO.isEmpty
                                ? const Center(
                                    child: Text("No activity recorded."))
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: widget.detail.activityDTO.length,
                                    itemBuilder: (context, index) {
                                      final activity =
                                          widget.detail.activityDTO[index];

                                      // Agar Commented hai aur comment empty hai, toh ye item mat dikhao
                                      if (activity.actionName == "Commented" &&
                                          activity.comments.trim().isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      // Agar Assigned hai aur assignedUserName null ya empty hai, toh ye item mat dikhao
                                      if (activity.actionName == "Assigned" &&
                                          (activity.assignedUserName == null ||
                                              activity.assignedUserName!
                                                  .trim()
                                                  .isEmpty)) {
                                        return const SizedBox.shrink();
                                      }

                                      // Baaki tumhara existing code jaisa hi rahega
                                      return Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 3,
                                        child: Column(
                                          children: [
                                            const Divider(height: 1),
                                            ListTile(
                                              leading: CircleAvatar(
                                                child: Text(
                                                  (activity.assignedUserName
                                                              ?.isNotEmpty ??
                                                          false)
                                                      ? activity
                                                          .assignedUserName![0]
                                                          .toUpperCase()
                                                      : '?',
                                                ),
                                              ),
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      activity.assignedUserName ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      activity.createdDate
                                                          .toLocal()
                                                          .toString()
                                                          .split('.')[0],
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: activity
                                                                  .actionName ==
                                                              'Commented'
                                                          ? Colors.pink.shade100
                                                          : Colors
                                                              .orange.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      activity.actionName,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  if (activity.actionName ==
                                                          "Commented" &&
                                                      activity
                                                          .comments.isNotEmpty)
                                                    Text(activity.comments),
                                                  if (activity.actionName ==
                                                          "Assigned" &&
                                                      activity.assignedUserName !=
                                                          null &&
                                                      activity.assignedUserName!
                                                          .isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 4),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.person,
                                                              size: 16),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(activity
                                                              .assignedUserName!),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                            const Divider(),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        constraints:
                                            BoxConstraints(maxHeight: 250),
                                        child: FlutterMentions(
                                          key: mentionsKey,
                                          maxLines: 5,
                                          minLines: 2,
                                          suggestionPosition:
                                              SuggestionPosition.Top,
                                          decoration: InputDecoration(
                                            hintText:
                                                "Add comment and assign user...",
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          mentions: [
                                            Mention(
                                              trigger: '@',
                                              style: const TextStyle(
                                                  color: Colors.blue),
                                              data: userList,
                                              matchAll: true,
                                              suggestionBuilder: (data) {
                                                return ListTile(
                                                  leading: CircleAvatar(
                                                    child: Text(data['display']
                                                            [0]
                                                        .toUpperCase()),
                                                  ),
                                                  title: Text(data['display']),
                                                  subtitle:
                                                      Text(data['full_name']),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed: _sendActivityComment,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(70, 48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text("Send"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ]),
                        ),
                      )),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 12),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Close"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Utility method to check image file type
  bool isImage(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.webp');
  }

  void openImageModal(String documentName) {
    final imageUrl = "$url/$documentName";

    showDialog(
      context: context,
      barrierColor: Colors.black54, // Dim background for focus on image
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16), // Padding from screen edges
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1,
            maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRootCauseForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show form fields only for ReadyToInspect
          if (selectedStatus ==
              SiteObservationStatus.ReadyToInspect.toString()) ...[
            DropdownButtonFormField<RootCause>(
              value: selectedRootCause,
              decoration: const InputDecoration(
                labelText: 'Select Root Cause',
                border: OutlineInputBorder(),
              ),
              items: rootCauses.map((RootCause cause) {
                return DropdownMenuItem<RootCause>(
                  value: cause,
                  child: Text(cause.rootCauseDesc),
                );
              }).toList(),
              onChanged: (RootCause? newValue) {
                setState(() {
                  selectedRootCause = newValue;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reworkCostController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Rework Cost',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: preventiveActionController,
              decoration: const InputDecoration(
                labelText: 'Preventive Action To Be Taken',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Preventive Action To Be Taken is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: correctiveActionController,
              decoration: const InputDecoration(
                labelText: 'Corrective Action To Be Taken',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Corrective Action To Be Taken is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Show file upload for both InProgress and ReadyToInspect
          if (selectedStatus == SiteObservationStatus.InProgress.toString() ||
              selectedStatus ==
                  SiteObservationStatus.ReadyToInspect.toString()) ...[
            const Text(
              "Upload File",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Your file picker logic here
                // final pickedFile = await FilePicker.platform.pickFiles();
              },
              child: const Text("Choose File"),
            ),
            const SizedBox(height: 16),
          ],

          // Update button only if form fields are shown (i.e. ReadyToInspect)
          if (selectedStatus ==
              SiteObservationStatus.ReadyToInspect.toString()) ...[
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isButtonDisabled
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() {
                            isEditingRootCause = false;
                            isButtonDisabled = true;
                          });

                          UpdateSiteObservation updatedData =
                              getUpdatedDataFromForm(uploadedFiles);

                          print(updatedData.toJson());

                          bool success = await SiteObservationService()
                              .updateSiteObservationByID(updatedData);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Update successful!')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Update failed! Please try again.')),
                            );
                            setState(() {
                              isButtonDisabled = false;
                            });
                          }
                        } else {
                          print("Validation failed.");
                        }
                      },
                child: const Text('Update'),
              ),
            ),
          ],

          // Show this text if status is neither InProgress nor ReadyToInspect
          if (selectedStatus !=
                  SiteObservationStatus.ReadyToInspect.toString() &&
              selectedStatus != SiteObservationStatus.InProgress.toString())
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Root Cause Details are hidden for the current status.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method inside your State class to create 2 columns row
  Widget _buildTwoColumnRow(
      String label1, dynamic value1, String label2, dynamic value2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$label1: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value1?.toString() ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$label2: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value2?.toString() ?? 'N/A'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
