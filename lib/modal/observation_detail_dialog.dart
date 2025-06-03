import 'dart:io';
import 'package:flutter/material.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:flutter/services.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:himappnew/constants.dart';

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
  // Static controllers for form fields
  final TextEditingController rootCauseController = TextEditingController();
  final TextEditingController reworkCostController = TextEditingController();
  final TextEditingController preventiveActionController =
      TextEditingController();
  final TextEditingController correctiveActionController =
      TextEditingController();
  final TextEditingController _activityCommentController =
      TextEditingController();
// final FlutterMentionsController _mentionController = FlutterMentionsController();

  late int editingUserId;
  // late int projectId;
  bool assigned = true;
  List<ActivityDTO> activities = [];
  final GlobalKey<FlutterMentionsState> mentionsKey =
      GlobalKey<FlutterMentionsState>();
  // final mentionData = userList.map((e) => e.toMentionMap()).toList();
  List<Map<String, String>> userList = [];

  List<RootCause> rootCauses = [];
  RootCause? selectedRootCause;
  bool isLoading = false;

  // final int activityId;
  int? activityIds = 0; // Default value, can be set later
  int? userId;
  // List<int> activityIds = [];
  List<String> uploadedFiles = [];
  bool isButtonDisabled = false;
  @override
  void initState() {
    super.initState();
    _loadActivityByCompanyIdAndScreenTypeId();
    _loadRootCauses();
    String statusValue = widget.detail.statusName ?? '';

    assigned = widget.detail.assignedUserID != null &&
        widget.detail.assignedUserID != 0;

    setObservationStatusDropdown(
      {"ObservationStatus": statusValue},
      assigned,
    );

    editingUserId = widget.siteObservationId;
    initData();
  }

  Future<void> initData() async {
    // await SharedPrefsHelper.saveProjectID(123);
    // await SharedPrefsHelper.saveProjectID(projectId);
    int? projectId = await SharedPrefsHelper.getProjectID();
    // print("📤 Project ID fetched in initData: $projectId");

    if (projectId == null) {
      // Handle missing projectId (show alert, skip fetchUsers, etc.)
      // print("⚠️ Project ID is null. Aborting fetchUsers.");
      return;
    }
    // print("✅ Got Project ID: $projectId");
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

  void _sendActivityComment() {
    // final mentions = mentionsKey.currentState?.markupText ?? "";
    final markupText = mentionsKey.currentState?.controller!.markupText ?? "";

    final RegExp mentionRegex = RegExp(r'\@\[(.*?)\]\((.*?)\)');
    final matches = mentionRegex.allMatches(markupText);

    List<User> selectedUsers = matches.map((match) {
      return User(
        // uniqueId: '',
        id: int.parse(match.group(2)!),
        userName: match.group(1)!,
        // password: '',
        // firstName: '',
        // lastName: '',
        // mobileNumber: '',
        // emailId: '',
        // userTypeId: 0,
        // reportingUserId: 0,
        // statusId: 1,
        // isActive: true,
        // createdBy: 0,
        // createdDate: DateTime.now(),
        // lastModifiedBy: 0,
        // lastModifiedDate: DateTime.now(),
      );
    }).toList();

    List<ActivityDTO> activities = [];

    for (var user in selectedUsers) {
      activities.add(ActivityDTO(
        id: 0,
        siteObservationID: editingUserId,
        actionID: 1,
        actionName: "Assigned",
        comments: "",
        documentName: "",
        fromStatusID: 0,
        toStatusID: 0,
        assignedUserID: user.id,
        assignedUserName: user.userName,
        createdBy: "",
        createdDate: DateTime.now(),
      ));
    }

    if (_activityCommentController.text.trim().isNotEmpty) {
      activities.add(ActivityDTO(
        id: 0,
        siteObservationID: editingUserId,
        actionID: 2,
        actionName: "Commented",
        comments: _activityCommentController.text.trim(),
        documentName: "",
        fromStatusID: 0,
        toStatusID: 0,
        assignedUserID: 0,
        assignedUserName: null,
        createdBy: "",
        createdDate: DateTime.now(),
      ));
    }

    UpdateSiteObservation updatedData = getUpdatedDataFromForm(uploadedFiles);
    updatedData.activityDTO.addAll(activities);
  }

  void setObservationStatusDropdown(Map<String, dynamic> ele, bool assigned) {
    if (ele["ObservationStatus"] == "Completed") {
      observationStatus = [
        {"id": "Completed", "name": "Completed"}
      ];
      selectedStatus = "Completed";
      isStatusEnabled = false;
    } else if (assigned && ele["ObservationStatus"] == "Ready To Inspect") {
      observationStatus = [
        {"id": "Completed", "name": "Completed"},
        {"id": "Reopen", "name": "Reopen"}
      ];
      selectedStatus = null;
      isStatusEnabled = true;
    } else if (!assigned && ele["ObservationStatus"] == "Ready To Inspect") {
      observationStatus = [
        {"id": "Ready To Inspect", "name": "Ready To Inspect"}
      ];
      selectedStatus = "Ready To Inspect";
      isStatusEnabled = false;
    } else {
      observationStatus = [
        {"id": "In Progress", "name": "In Progress"},
        {"id": "Ready To Inspect", "name": "Ready To Inspect"}
      ];
      selectedStatus = null;
      isStatusEnabled = true;
    }
  }

  bool _isLoading = false;

  fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      int? projectID = await SharedPrefsHelper.getProjectID();

      // print("Project ID O servation: $projectID");
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
        _isLoading = false;
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
        // print('Selected Activity ID: $activityIds');
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
    final media = MediaQuery.of(context);

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
                            return DropdownMenuItem<String>(
                              value: status['id'],
                              child: Text(status['name'] ?? ''),
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
                        ),
                      ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Status: $selectedStatus"),
                              const SizedBox(height: 8),
                              Text("Description: ${widget.detail.description}"),
                              const SizedBox(height: 8),
                              Text(
                                  "Observation Date: ${widget.detail.trancationDate}"),
                              const SizedBox(height: 8),
                              Text(
                                  "Created Date: ${widget.detail.createdDate}"),
                              const SizedBox(height: 8),
                              Text(
                                  "Observation Type: ${widget.detail.observationType}"),
                              const SizedBox(height: 8),
                              Text("Issue Type: ${widget.detail.issueType}"),
                              // const SizedBox(height: 8),
                              // Text("Created By: ${widget.detail.cre}"),
                              const SizedBox(height: 8),
                              Text("Due Date: ${widget.detail.dueDate}"),
                              const SizedBox(height: 8),
                              Text("Activity: ${widget.detail.activityName}"),
                              const SizedBox(height: 8),
                              Text("Section: ${widget.detail.sectionName}"),
                              const SizedBox(height: 8),
                              Text("Floor: ${widget.detail.floorName}"),
                              const SizedBox(height: 8),
                              Text("Part: ${widget.detail.partName}"),
                              const SizedBox(height: 8),
                              Text("Element: ${widget.detail.elementName}"),
                              const SizedBox(height: 8),
                              Text(
                                  "Contractor: ${widget.detail.contractorName}"),
                              const SizedBox(height: 8),
                              Text(
                                  "Compliance Required: ${widget.detail.complianceRequired}"),
                              const SizedBox(height: 8),
                              Text(
                                  "Escalation Required: ${widget.detail.escalationRequired}"),
                              const SizedBox(height: 8),
                              Text(
                                  "Action To Be Taken: ${widget.detail.actionToBeTaken}"),
                              const SizedBox(height: 8),
                              Text(
                                  "Raised By: ${widget.detail.observationRaisedBy}"),
                              const SizedBox(height: 16),
                              if (selectedStatus == "Ready To Inspect")
                                Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
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
                                            Text(
                                              "Root Cause Details",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
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
                                        if (!isEditingRootCause) ...[
                                          // Static view or placeholder here
                                          const Text("Root Cause info here..."),
                                        ] else
                                          _buildRootCauseForm(),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
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
                          child: Column(
                            children: [
                              widget.detail.activityDTO.isEmpty
                                  ? const Center(
                                      child: Text("No activity recorded."))
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          widget.detail.activityDTO.length,
                                      itemBuilder: (context, index) {
                                        final activity =
                                            widget.detail.activityDTO[index];
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
                                                            .assignedUserName![
                                                                0]
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
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                                            color: Colors.grey),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                                        color:
                                                            activity.actionName ==
                                                                    'Commented'
                                                                ? Colors.pink
                                                                    .shade100
                                                                : Colors.orange
                                                                    .shade100,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
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
                                                    if (activity
                                                        .comments.isNotEmpty)
                                                      Text(activity.comments),
                                                    if (activity.assignedUserName !=
                                                            null &&
                                                        activity
                                                            .assignedUserName!
                                                            .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 4),
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
                                                    if (activity.documentName
                                                        .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 14),
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            openImageModal(activity
                                                                .documentName);
                                                          },
                                                          child: Container(
                                                            width: 100,
                                                            height: 100,
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade300,
                                                                  width: 2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              child:
                                                                  ConstrainedBox(
                                                                constraints:
                                                                    BoxConstraints(
                                                                  maxHeight:
                                                                      150,
                                                                  maxWidth:
                                                                      MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width,
                                                                ),
                                                                child: Image
                                                                    .network(
                                                                  isImage(activity
                                                                          .documentName)
                                                                      ? "$url/${activity.documentName}"
                                                                      : "assets/default-image.png",
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder: (context,
                                                                          error,
                                                                          stackTrace) =>
                                                                      const Icon(
                                                                          Icons
                                                                              .broken_image),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
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
                                clipBehavior: Clip
                                    .none, // Allow overlay to overflow outside Stack bounds
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          constraints:
                                              BoxConstraints(maxHeight: 250),
                                          child: FlutterMentions(
                                            key: mentionsKey,
                                            // controller: _mentionController,
                                            // controller:
                                            //     _activityCommentController,
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
                                                style: TextStyle(
                                                    color: Colors.blue),
                                                matchAll: true,
                                                data: userList,
                                                suggestionBuilder: (data) {
                                                  return ListTile(
                                                    leading: CircleAvatar(
                                                      child: Text(
                                                          data['display'][0]
                                                              .toUpperCase()),
                                                    ),
                                                    title:
                                                        Text(data['display']),
                                                    subtitle:
                                                        Text(data['full_name']),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      ElevatedButton(
                                        onPressed: _sendActivityComment,
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size(70, 48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text("Send"),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
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
          if (selectedStatus == "Ready To Inspect") ...[
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
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isButtonDisabled
                    ? null // disables the button
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() {
                            isEditingRootCause = false;
                            isButtonDisabled = true; // disable the button
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
                            // Optional: Keep button disabled or navigate away
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Update failed! Please try again.')),
                            );
                            setState(() {
                              isButtonDisabled = false; // re-enable on failure
                            });
                          }
                        } else {
                          print("Validation failed.");
                        }
                      },
                child: const Text('Update'),
              ),
            ),
          ] else
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
}
