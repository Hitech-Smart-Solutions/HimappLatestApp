// naya code

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:flutter/services.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
// import 'package:collection/collection.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ObservationDetailDialog extends StatefulWidget {
  final GetSiteObservationMasterById detail;
  final SiteObservationService siteObservationService;
  final int siteObservationId;
  final String? createdBy;
  final int? activityId;
  // final String? statusName;
  // final int activityId;
  // final int projectId;
  const ObservationDetailDialog({
    super.key,
    required this.detail,
    required this.siteObservationService,
    required this.siteObservationId,
    required this.createdBy,
    required this.activityId,
    // required this.statusName,
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
  // Default value, can be set later
  int? userId;

  List<String> uploadedFiles = [];
  bool isButtonDisabled = false;

  String? selectedFileName;
  bool _isReadOnly = false;

  List<PlatformFile> selectedFiles = [];
  List<String> uploadedFileNames = [];

  List<String> attachmentFiles = []; // At top in your State class
  bool showSaveAttachmentButton = false;
  late GetSiteObservationMasterById currentDetail;
  @override
  void initState() {
    super.initState();
    currentDetail = widget.detail;
    _setupPage();
  }

  Future<void> _setupPage() async {
    // Parse status ID
    final rawStatus = widget.detail.statusName;
    final int statusId = int.tryParse(rawStatus ?? '') ?? 0;

    if (statusId != 0) {
      await setObservationStatusDropdown(
          statusId, widget.detail.createdBy, widget.detail);
    } else {
      print("⚠️ Invalid status ID string: ${widget.detail.statusName}");
    }

    await _loadRootCauses(); // wait for root causes to load before proceeding

    _initializeFormFields(); // now safe to initialize form fields with loaded data

    editingUserId = widget.siteObservationId;
    await initData(); // optionally await this if it’s async
  }

  Future<void> initData() async {
    int? projectId = await SharedPrefsHelper.getProjectID();
    if (projectId == null) {
      return;
    }
    await fetchUsers(); // Only fetch after getting valid ProjectID
    userId = await SharedPrefsHelper.getUserId();
  }

  void _initializeFormFields() {
    if (selectedStatus == SiteObservationStatus.Open.toString()) {
      try {
        // If rootCauseID is valid, find matching RootCause
        if (widget.detail.rootCauseID != null &&
            widget.detail.rootCauseID != 0) {
          selectedRootCause = rootCauses.firstWhere(
            (rc) => rc.id == widget.detail.rootCauseID,
          );
        } else if (widget.detail.rootCauseID == 0 && rootCauses.isNotEmpty) {
          // If rootCauseID is 0, fallback to first in list
          selectedRootCause = rootCauses.first;
        } else {
          selectedRootCause = null;
        }
      } catch (e) {
        selectedRootCause = null;
      }

      reworkCostController.text = widget.detail.reworkCost?.toString() ?? '';
      preventiveActionController.text =
          widget.detail.preventiveActionTaken ?? '';
      correctiveActionController.text =
          widget.detail.corretiveActionToBeTaken ?? '';
    }
    if (selectedStatus == SiteObservationStatus.ReadyToInspect.toString() ||
        selectedStatus == SiteObservationStatus.Completed.toString()) {
      _isReadOnly = true;
      try {
        // If rootCauseID is valid, find matching RootCause
        if (widget.detail.rootCauseID != null &&
            widget.detail.rootCauseID != 0) {
          selectedRootCause = rootCauses.firstWhere(
            (rc) => rc.id == widget.detail.rootCauseID,
          );
        } else if (widget.detail.rootCauseID == 0 && rootCauses.isNotEmpty) {
          // If rootCauseID is 0, fallback to first in list
          selectedRootCause = rootCauses.first;
        } else {
          selectedRootCause = null;
        }
      } catch (e) {
        selectedRootCause = null;
      }

      reworkCostController.text = widget.detail.reworkCost?.toString() ?? '';
      preventiveActionController.text =
          widget.detail.preventiveActionTaken ?? '';
      correctiveActionController.text =
          widget.detail.corretiveActionToBeTaken ?? '';
    }
  }

  @override
  void dispose() {
    rootCauseController.dispose();
    reworkCostController.dispose();
    preventiveActionController.dispose();
    correctiveActionController.dispose();
    super.dispose();
  }

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

  Future<void> setObservationStatusDropdown(
      int statusId, int? createdBy, GetSiteObservationMasterById detail) async {
    observationStatus = [];
    selectedStatus = null;
    isStatusEnabled = true;
    int? userID = await SharedPrefsHelper.getUserId();
    // this.editDetails.activityDTO.filter(x => x.assignedToUserID == userID)
    var isAssign = detail.activityDTO
        .where((activity) => activity.assignedUserID == userID)
        .toList();

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
        if (createdBy == userID) {
          observationStatus = [
            {
              "id": SiteObservationStatus.Completed.toString(),
              "name": "Completed"
            },
            {"id": SiteObservationStatus.Reopen.toString(), "name": "Reopen"},
            {
              "id": SiteObservationStatus.ReadyToInspect.toString(),
              "name": "Ready To Inspect"
            }
          ];
          isStatusEnabled = true;
        } else if (isAssign.isEmpty && createdBy != userID) {
          observationStatus = [
            {
              "id": SiteObservationStatus.ReadyToInspect.toString(),
              "name": "Ready To Inspect"
            }
          ];
          isStatusEnabled = false;
        }
        selectedStatus = SiteObservationStatus.ReadyToInspect.toString();
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
        siteObservationID: editingUserId,
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
    print("Uploaded files list: $uploadedFiles");
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
      id: editingUserId,
      rootCauseID: rootCauseID,
      corretiveActionToBeTaken: correctiveActionController.text,
      preventiveActionTaken: preventiveActionController.text,
      reworkCost: double.tryParse(reworkCostController.text) ?? 0.0,
      statusID: 3,
      lastModifiedBy: userId!,
      lastModifiedDate: DateTime.now(),
      activityDTO: activities,
    );
  }

  Future<void> pickAndUploadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true, // required for bytes
    );

    if (result != null && result.files.isNotEmpty) {
      selectedFiles = result.files;

      uploadedFileNames.clear();

      for (var file in selectedFiles) {
        if (file.bytes != null) {
          final uploadedName = await SiteObservationService()
              .uploadFileAndGetFileName(file.name, file.bytes!);
          if (uploadedName != null) {
            uploadedFileNames.add(uploadedName);
          } else {
            print("❌ Failed to upload ${file.name}");
          }
        }
      }

      print("✅ Uploaded filenames: $uploadedFileNames");
    }
  }

  Future<void> _loadRootCauses() async {
    // if (activityIds == null) return; // safety check
    // print("Loading root causes for activity ID: $activityIds");
    setState(() => isLoading = true);
    try {
      int? activityId = widget.activityId;
      if (activityId == null) {
        print("⚠️ activityId is null, skipping root cause fetch");
        return;
      }
      print("Fetching root causes for activity ID: ${widget.activityId}");
      rootCauses = await SiteObservationService()
          .fatchRootCausesByActivityID(activityId!);
      print("Fetched root causes: $rootCauses");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load root causes: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<Uint8List?> compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 1024,
      minHeight: 1024,
      quality: 70, // 0-100
    );
    return result;
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
                          final idStr = status['id'].toString();
                          final id = int.tryParse(idStr);
                          final name = SiteObservationStatus.idToName[id] ??
                              status['name'] ??
                              'Unknown';

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
                                        SiteObservationStatus.Open.toString() ||
                                    selectedStatus ==
                                        SiteObservationStatus.ReadyToInspect
                                            .toString() ||
                                    selectedStatus ==
                                        SiteObservationStatus.InProgress
                                            .toString() ||
                                    selectedStatus ==
                                        SiteObservationStatus.Completed
                                            .toString() ||
                                    selectedStatus ==
                                        SiteObservationStatus.Reopen.toString())
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
                            /// Upload Image Button
                            ElevatedButton.icon(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? pickedFile = await picker
                                    .pickImage(source: ImageSource.gallery);

                                if (pickedFile != null) {
                                  File imageFile = File(pickedFile.path);
                                  final fileName =
                                      imageFile.path.split('/').last;
                                  final fileBytes =
                                      await compressImage(imageFile);

                                  if (fileBytes == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("Compression failed")));
                                    return;
                                  }

                                  final uploadedFileName =
                                      await SiteObservationService()
                                          .uploadFileAndGetFileName(
                                    fileName,
                                    fileBytes,
                                  );

                                  if (uploadedFileName != null) {
                                    uploadedFiles.add(uploadedFileName);
                                    setState(() {
                                      showSaveAttachmentButton = true;
                                      widget.detail.activityDTO.add(
                                        ActivityDTO(
                                          id: 0,
                                          siteObservationID: widget.detail.id,
                                          actionID: 0,
                                          actionName: "Created",
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
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Upload failed.")),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Upload Image"),
                            ),

                            const SizedBox(height: 12),

                            /// Save Button
                            if (showSaveAttachmentButton)
                              ElevatedButton(
                                onPressed: () async {
                                  print("Save button pressed");
                                  setState(() {
                                    showSaveAttachmentButton =
                                        false; // Disable button immediately to avoid multiple taps
                                  });
                                  print("SetState completed");
                                  UpdateSiteObservation updatedData =
                                      getUpdatedDataFromForm(uploadedFiles);
                                  print("Before API call");
                                  bool success = await SiteObservationService()
                                      .updateSiteObservationByID(updatedData);
                                  print("After API call, success: $success");
                                  print("success:$success");
                                  if (success) {
                                    final newDetail = (await widget
                                            .siteObservationService
                                            .fetchGetSiteObservationMasterById(
                                                currentDetail.id))
                                        .first;
                                    setState(() {
                                      currentDetail = newDetail;
                                      uploadedFiles.clear();
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: const [
                                            Icon(Icons.error,
                                                color: Colors.red),
                                            SizedBox(width: 10),
                                            Text("Failed to save attachment."),
                                          ],
                                        ),
                                        backgroundColor: Colors.black87,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                    setState(() {
                                      showSaveAttachmentButton =
                                          true; // Re-enable button on failure
                                    });
                                  }
                                },
                                child: const Text("Save Attachment"),
                              ),

                            const SizedBox(height: 16),

                            /// Show Uploaded Images
                            widget.detail.activityDTO.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: widget.detail.activityDTO
                                        .where((activity) =>
                                            activity.documentName.isNotEmpty)
                                        .map((activity) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(activity.actionName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 6),
                                            GestureDetector(
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
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.network(
                                                    isImage(activity
                                                            .documentName)
                                                        ? "$url/${activity.documentName}"
                                                        : "assets/default-image.png",
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        const Icon(
                                                      Icons.broken_image,
                                                      size: 50,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : const Text("No attachments available."),
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
                                      print(
                                          'ActivityLatest #$index: actionNameLatest=${activity.actionName}, commentsLatest=${activity.comments}');
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
                                                      : (activity.createdBy
                                                              .isNotEmpty
                                                          ? activity
                                                              .createdBy[0]
                                                              .toUpperCase()
                                                          : '?'),
                                                ),
                                              ),
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      activity.assignedUserName
                                                                  ?.isNotEmpty ==
                                                              true
                                                          ? activity
                                                              .assignedUserName!
                                                          : activity.createdBy,
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
                                                  // Show comment text only if action is "Commented" and comment exists
                                                  if (activity.actionName ==
                                                          "Commented" &&
                                                      activity
                                                          .comments.isNotEmpty)
                                                    Text(activity.comments),

                                                  // ✅ Show only if actionName == Assigned
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
                                                  // ✅ This is your solution
                                                  if ((activity.actionName ==
                                                              "DocUploaded" ||
                                                          activity.actionName ==
                                                              "Created") &&
                                                      activity.documentName !=
                                                          null &&
                                                      activity.documentName!
                                                          .isNotEmpty &&
                                                      isImage(activity
                                                          .documentName!))
                                                    Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8.0),
                                                        child: SizedBox(
                                                          height: 150,
                                                          width: 150,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            child:
                                                                Image.network(
                                                              "$url/${activity.documentName!}",
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context,
                                                                      error,
                                                                      stackTrace) =>
                                                                  const Icon(Icons
                                                                      .broken_image),
                                                            ),
                                                          ),
                                                        )),
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
                  SiteObservationStatus.ReadyToInspect.toString() ||
              selectedStatus == SiteObservationStatus.Open.toString() ||
              selectedStatus == SiteObservationStatus.Completed.toString() ||
              selectedStatus == SiteObservationStatus.Reopen.toString()) ...[
            DropdownButtonFormField<RootCause>(
              value: selectedRootCause,
              decoration: const InputDecoration(
                labelText: 'Select Root Cause',
                border: OutlineInputBorder(),
              ),
              items: rootCauses.map((cause) {
                return DropdownMenuItem<RootCause>(
                  value: cause,
                  child: Text(cause.rootCauseDesc),
                );
              }).toList(),
              onChanged: _isReadOnly
                  ? null // 👈 disables the dropdown
                  : (newValue) {
                      setState(() {
                        selectedRootCause = newValue;
                      });
                    },
              validator: (value) {
                if (value == null) return 'Root Cause is required';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reworkCostController,
              readOnly: _isReadOnly,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Rework Cost',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Rework Cost is required';
                }
                final numValue = num.tryParse(value);
                if (numValue == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: preventiveActionController,
              readOnly: _isReadOnly,
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
              readOnly: _isReadOnly,
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
                  SiteObservationStatus.ReadyToInspect.toString() ||
              selectedStatus == SiteObservationStatus.Open.toString() ||
              selectedStatus == SiteObservationStatus.Completed.toString() ||
              selectedStatus == SiteObservationStatus.Reopen.toString()) ...[
            const Text(
              "Upload File",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  allowMultiple: false,
                  withData: true,
                );

                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  print("Picked file: ${file.name}");

                  setState(() {
                    selectedFileName = file.name;
                  });

                  // ✅ Upload file here
                  final uploadedFileName =
                      await SiteObservationService().uploadFileAndGetFileName(
                    file.name,
                    file.bytes!,
                  );

                  if (uploadedFileName != null) {
                    print("Uploaded file name: $uploadedFileName");

                    setState(() {
                      uploadedFiles.add(
                          uploadedFileName); // 🔁 Add to your list for saving in activityDTO
                    });
                    print("Current uploadedFiles list: $uploadedFiles");
                    print("File upload successful: $uploadedFileName");
                  } else {
                    print("Upload failed");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("File upload failed")),
                    );
                  }
                } else {
                  print("No file selected");
                }
              },
              child: const Text("Choose File"),
            ),
            if (selectedFileName != null) ...[
              const SizedBox(height: 8),
              Text(
                "Selected file: $selectedFileName",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // Update button only if form fields are shown (i.e. ReadyToInspect)
          if (selectedStatus == SiteObservationStatus.Open.toString() ||
              selectedStatus ==
                  SiteObservationStatus.ReadyToInspect.toString() ||
              selectedStatus ==
                  SiteObservationStatus.ReadyToInspect.toString() ||
              selectedStatus == SiteObservationStatus.Completed.toString() ||
              selectedStatus == SiteObservationStatus.Reopen.toString()) ...[
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

                          print("uploadedFiles before update: $uploadedFiles");

                          UpdateSiteObservation updatedData =
                              getUpdatedDataFromForm(uploadedFiles);

                          bool success = await SiteObservationService()
                              .updateSiteObservationByID(updatedData);

                          if (success) {
                            // 👇👇 Add uploaded files to activityDTO here
                            for (var fileName in uploadedFiles) {
                              widget.detail.activityDTO.add(
                                ActivityDTO(
                                  id: 0,
                                  siteObservationID: widget.detail.id,
                                  actionID: 0,
                                  actionName: '',
                                  comments: '',
                                  documentName: fileName,
                                  fromStatusID: 0,
                                  toStatusID: 0,
                                  assignedUserID: 0,
                                  assignedUserName: null,
                                  createdBy: 'You',
                                  createdDate: DateTime.now(),
                                ),
                              );
                            }

                            setState(() {
                              uploadedFiles
                                  .clear(); // Reset after successful update
                            });

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
              selectedStatus != SiteObservationStatus.InProgress.toString() &&
              selectedStatus != SiteObservationStatus.Open.toString() &&
              selectedStatus == SiteObservationStatus.Completed.toString() &&
              selectedStatus == SiteObservationStatus.Reopen.toString())
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
