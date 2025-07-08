import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ObservationQCDetailDialog extends StatefulWidget {
  final GetSiteObservationMasterById detail;
  final SiteObservationService siteObservationService;
  final int siteObservationId;
  final String? createdBy;
  final int? activityId;
  final int projectID;

  const ObservationQCDetailDialog({
    super.key,
    required this.detail,
    required this.siteObservationService,
    required this.siteObservationId,
    required this.createdBy,
    required this.activityId,
    required this.projectID,
  });

  @override
  _ObservationQCDetailDialogState createState() =>
      _ObservationQCDetailDialogState();
}

class _ObservationQCDetailDialogState extends State<ObservationQCDetailDialog> {
  bool isLoading = false;
  String? selectedStatus;
  List<Map<String, String>> observationStatus = [];

  List<RootCause> rootCauses = [];
  RootCause? selectedRootCause;
  bool isStatusEnabled = false;
  bool isEditingRootCause = false;
  bool isButtonDisabled = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController rootCauseController = TextEditingController();
  final TextEditingController reworkCostController = TextEditingController();
  final TextEditingController preventiveActionController =
      TextEditingController();
  final TextEditingController correctiveActionController =
      TextEditingController();
  final TextEditingController _activityCommentController =
      TextEditingController();
  final GlobalKey<FlutterMentionsState> mentionsKey =
      GlobalKey<FlutterMentionsState>();

  String? selectedFileName;
  List<String> uploadedFiles = [];
  bool showSaveAttachmentButton = false;
  String url = AppSettings.url;

  int? userId;
  String? currentUserName;
  late GetSiteObservationMasterById currentDetail;
  List<User> allUsers = [];
  late int editingUserId;
  List<Map<String, String>> userList = [];
  List<User> selectedUsers = [];
  List<ActivityDTO> activities = [];

  int fromStatus = SiteObservationStatus.Open;
  int toStatus = SiteObservationStatus.Open;
  String? areaLabel;
  String? floorLabel;
  String? elementLabel;

  @override
  void initState() {
    super.initState();
    // print("widget.detail ${widget.detail}");
    currentDetail = widget.detail;
    _setupPage();
    loadSection();
    loadFloor();
    loadElement();
  }

  Future<void> _setupPage() async {
    final statusId = widget.detail.statusID;
    // print('🔁 rawStatus: $statusId');

    if (statusId != 0) {
      selectedStatus = statusId.toString(); // Dropdown ke liye string chahiye
      fromStatus = statusId; // Current status id
      toStatus = statusId;
      await setObservationStatusDropdown(
        statusId,
        widget.detail.createdBy,
        widget.detail,
      );
    } else {
      print("⚠️ Invalid status name: ${widget.detail.statusName}");
      print("⚠️ Invalid status ID");
      selectedStatus = null;
      fromStatus = 0; // Ya default koi bhi status id rakh lo
      toStatus = 0;
    }
    await _loadRootCauses(); // wait for root causes to load before proceeding

    _initializeFormFields(); // now safe to initialize form fields with loaded data

    editingUserId = widget.siteObservationId;
    await initData(); // optionally await this if it’s async
  }

  Future<void> initData() async {
    int projectID = widget.projectID;
    await fetchUsers();
    userId = await SharedPrefsHelper.getUserId();
    currentUserName = await SharedPrefsHelper.getUserName();
  }

  // void onStatusChanged(int newStatusId) {
  //   setState(() {
  //     fromStatus = toStatus; // Old "toStatus" now becomes "fromStatus"
  //     toStatus = newStatusId; // New selected status
  //   });
  // }

  void _initializeFormFields() {
    if (selectedStatus == SiteObservationStatus.Open.toString()) {
      try {
        if (widget.detail.rootCauseID != null &&
            widget.detail.rootCauseID != 0) {
          selectedRootCause = rootCauses.firstWhere(
            (rc) => rc.id == widget.detail.rootCauseID,
          );
        } else if (widget.detail.rootCauseID == 0 && rootCauses.isNotEmpty) {
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
        selectedStatus == SiteObservationStatus.Closed.toString()) {
      try {
        if (widget.detail.rootCauseID != null &&
            widget.detail.rootCauseID != 0) {
          selectedRootCause = rootCauses.firstWhere(
            (rc) => rc.id == widget.detail.rootCauseID,
          );
        } else if (widget.detail.rootCauseID == 0 && rootCauses.isNotEmpty) {
          selectedRootCause = rootCauses.first;
        } else {
          selectedRootCause = null;
        }
      } catch (e) {
        selectedRootCause = null;
      }

      reworkCostController.text = widget.detail.reworkCost != null
          ? widget.detail.reworkCost!.toStringAsFixed(2)
          : '';
      preventiveActionController.text =
          widget.detail.preventiveActionTaken ?? '';
      correctiveActionController.text =
          widget.detail.corretiveActionToBeTaken ?? '';
    }
  }

  Future<void> _loadRootCauses() async {
    setState(() => isLoading = true);
    try {
      int? companyId = await SharedPrefsHelper.getCompanyId();
      if (companyId == null) {
        print('Error: Company ID is null');
        return;
      }
      rootCauses =
          await SiteObservationService().fatchRootCausesByActivityID(companyId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load root causes: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<UpdateSiteObservation> getUpdatedDataFromForm(
      List<String> uploadedFiles) async {
    int id = widget.detail.id;
    int rootCauseID = selectedRootCause?.id ?? 0;

    List<ActivityDTO> activities = [];
    int selectedStatusId =
        int.tryParse(selectedStatus ?? '') ?? SiteObservationStatus.Open;
    if (selectedStatusId == SiteObservationStatus.ReadyToInspect) {
      activities.add(
        ActivityDTO(
          id: 0,
          siteObservationID: id,
          actionID: SiteObservationActions.Assigned,
          actionName: 'Assigned',
          comments: '',
          documentName: '',
          fromStatusID: fromStatus,
          toStatusID: toStatus,
          assignedUserID: widget.detail.createdBy,
          assignedUserName: null,
          createdBy: userId!.toString(),
          createdDate: DateTime.now(),
        ),
      );
      print("🔁 selectedStatusId 510: $selectedStatusId");
    } else if (selectedStatusId == SiteObservationStatus.Reopen) {
      final assignedUsers =
          await SiteObservationService().fetchGetassignedusersforReopen(id);
      print("🔁 Assigned Users210: $assignedUsers");
      String currentUserId = userId!.toString();
      // Add an activity for each assigned user
      for (var user in assignedUsers) {
        activities.add(
          ActivityDTO(
            id: 0,
            siteObservationID: id,
            actionID: SiteObservationActions.Assigned,
            actionName: 'Assigned',
            comments: '',
            documentName: '',
            fromStatusID: fromStatus,
            toStatusID: toStatus,
            assignedUserID: user.assignedUserID,
            createdBy: currentUserId,
            createdDate: DateTime.now(),
          ),
        );
      }
    }

    // Add file uploads if available
    for (String fileName in uploadedFiles) {
      activities.add(
        ActivityDTO(
          id: 0,
          siteObservationID: id,
          actionID: SiteObservationActions.DocUploaded,
          actionName: 'DocUploaded',
          comments: '',
          documentName: fileName,
          fromStatusID: fromStatus,
          toStatusID: toStatus,
          assignedUserID: userId!,
          assignedUserName: null,
          createdBy: userId!.toString(),
          createdDate: DateTime.now(),
        ),
      );
    }

    return UpdateSiteObservation(
      id: id,
      rootCauseID: rootCauseID,
      corretiveActionToBeTaken: correctiveActionController.text,
      preventiveActionTaken: preventiveActionController.text,
      reworkCost: double.tryParse(reworkCostController.text) ?? 0.0,
      statusID: selectedStatusId,
      lastModifiedBy: userId!,
      lastModifiedDate: DateTime.now(),
      activityDTO: activities,
    );
  }

  String getStatusNameFromId(String id) {
    final status = observationStatus.firstWhere(
      (e) => e['id'].toString() == id,
      orElse: () => {'name': 'Unknown'},
    );
    return status['name'] ?? 'Unknown';
  }

  Future<void> setObservationStatusDropdown(
      int statusId, int? createdBy, GetSiteObservationMasterById detail) async {
    int? userID = await SharedPrefsHelper.getUserId();
    var isAssign = detail.activityDTO
        .where((activity) => activity.assignedUserID == userID)
        .toList();

    List<Map<String, String>> newStatusList = [];
    String? newSelectedStatus;
    bool newStatusEnabled = true;

    switch (statusId) {
      case SiteObservationStatus.Closed:
        newStatusList = [
          {"id": SiteObservationStatus.Closed.toString(), "name": "Closed"}
        ];
        newSelectedStatus = SiteObservationStatus.Closed.toString();
        newStatusEnabled = false;
        break;

      case SiteObservationStatus.ReadyToInspect:
        if (createdBy == userID) {
          newStatusList = [
            {"id": SiteObservationStatus.Closed.toString(), "name": "Closed"},
            {"id": SiteObservationStatus.Reopen.toString(), "name": "Reopen"},
            {
              "id": SiteObservationStatus.ReadyToInspect.toString(),
              "name": "Ready To Inspect"
            }
          ];
        } else if (isAssign.isEmpty && createdBy != userID) {
          newStatusList = [
            {
              "id": SiteObservationStatus.ReadyToInspect.toString(),
              "name": "Ready To Inspect"
            }
          ];
          newStatusEnabled = false;
        }
        newSelectedStatus = SiteObservationStatus.ReadyToInspect.toString();
        break;

      case SiteObservationStatus.Open:
        newStatusList = [
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
        newSelectedStatus = SiteObservationStatus.Open.toString();
        break;

      default:
        newStatusList = [
          {
            "id": SiteObservationStatus.InProgress.toString(),
            "name": "In Progress"
          },
          {
            "id": SiteObservationStatus.ReadyToInspect.toString(),
            "name": "Ready To Inspect"
          },
        ];
        newSelectedStatus = statusId.toString();
        break;
    }
    if (!newStatusList.any((s) => s['id'] == statusId.toString())) {
      newStatusList.add({
        "id": statusId.toString(),
        "name": SiteObservationStatus.idToName[statusId] ?? "Reopen"
      });
    }
    setState(() {
      observationStatus = newStatusList;
      final statusExists =
          newStatusList.any((item) => item['id'] == newSelectedStatus);
      selectedStatus = statusExists ? newSelectedStatus : null;
      isStatusEnabled = newStatusEnabled;
      if (!statusExists) {
        print(
            '⚠️ selectedStatus "$newSelectedStatus" not found in dropdown list');
      }
    });
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

        // final matchedUser = allUsers.firstWhere(
        //   (user) => user.id == userId,
        //   orElse: () => User(id: 0, userName: ''),
        // );
        final matchedUser = allUsers.firstWhere(
          (user) => user.id == userId,
          orElse: () => User(
              id: userId,
              userName: cleanedUserName), // ✅ fallback me bhi name jaaye
        );

        String finalUserName = matchedUser.userName.isNotEmpty
            ? matchedUser.userName
            : cleanedUserName;

        return User(id: userId, userName: finalUserName);
      }).toList();

      // ✅ Fix is here — get int userId only
      // int createdBy = await SharedPrefsHelper.getUserId() ?? 0;
      // String createdBy = await SharedPrefsHelper.getUserName() ?? 'Unknown';
      // String createdBy = await SharedPrefsHelper.getUserName() ?? 'Unknown';
      int createdById = await SharedPrefsHelper.getUserId() ?? 0;
      String createdByName = await SharedPrefsHelper.getUserName() ?? 'Unknown';

      // int createdBy = await SharedPrefsHelper.getUserId() ?? 0;
      List<ActivityDTO> activities = [];

      final commentText =
          mentionsKey.currentState?.controller?.text.trim() ?? "";
      final plainComment =
          commentText.replaceAll(RegExp(r'\@\[(.*?)\]\((.*?)\)'), '').trim();

      bool hasMentions = selectedUsers.isNotEmpty;
      bool hasComment = plainComment.isNotEmpty;
      // print("activities413:$activities");
      // CASE 1 — Only mention(s)
      if (hasMentions && !hasComment) {
        for (var user in selectedUsers) {
          activities.add(ActivityDTO(
            id: 0,
            siteObservationID: editingUserId,
            actionID: SiteObservationActions.Assigned,
            actionName: "Assigned",
            comments: "",
            documentName: "",
            fromStatusID: fromStatus,
            toStatusID: toStatus,
            toStatusName: SiteObservationStatus.idToName[toStatus] ??
                "Unknown", // ✅ Add this
            assignedUserID: user.id,
            assignedUserName: user.userName,
            createdBy: createdById.toString(), // ✅ send as integer
            createdByName: createdByName,
            createdDate: DateTime.now(),
          ));
        }
      }

      // CASE 2 — Only comment
      else if (!hasMentions && hasComment) {
        activities.add(ActivityDTO(
          id: 0,
          siteObservationID: editingUserId,
          actionID: SiteObservationActions.Commented,
          actionName: "Commented",
          comments: plainComment,
          documentName: "",
          fromStatusID: fromStatus,
          toStatusID: toStatus,
          toStatusName: SiteObservationStatus.idToName[toStatus] ??
              "Unknown", // ✅ Add this
          assignedUserID: 0,
          // assignedUserName: '',
          // createdBy: createdBy, // ✅ integer
          createdBy: createdById.toString(),
          createdByName: createdByName,
          assignedUserName: createdByName,
          createdDate: DateTime.now(),
        ));
      }

      // CASE 3 — Both mention(s) and comment
      else if (hasMentions && hasComment) {
        for (var user in selectedUsers) {
          activities.add(ActivityDTO(
            id: 0,
            siteObservationID: editingUserId,
            actionID: SiteObservationActions.Assigned,
            actionName: "Assigned",
            comments: "",
            documentName: "",
            fromStatusID: fromStatus,
            toStatusID: toStatus,
            toStatusName: SiteObservationStatus.idToName[toStatus] ??
                "Unknown", // ✅ Add this
            assignedUserID: user.id,
            assignedUserName: user.userName,
            createdBy: createdById.toString(), // ✅ integer
            createdByName: createdByName,
            createdDate: DateTime.now(),
          ));
          // print("activities466:$activities");
        }

        activities.add(ActivityDTO(
          id: 0,
          siteObservationID: editingUserId,
          actionID: SiteObservationActions.Commented,
          actionName: "Commented",
          comments: plainComment,
          documentName: "",
          fromStatusID: fromStatus,
          toStatusID: toStatus,
          toStatusName: SiteObservationStatus.idToName[toStatus] ??
              "Unknown", // ✅ Add this
          assignedUserID: 0,
          assignedUserName: '',
          createdBy: createdById.toString(), // ✅ integer
          createdByName: createdByName,
          createdDate: DateTime.now(),
        ));
      }
      // print("activity483: $activities");
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

  // List<Map<String, String>> userList = [];

  fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      int projectID = widget.projectID;
      int? currentUserId =
          await SharedPrefsHelper.getUserId(); // 👈 Get logged-in user ID

      final response = await SiteObservationService().fetchUsersForList(
        projectId: projectID,
      );

      setState(() {
        userList = response
            .where((u) => u.id != currentUserId) // 👈 Exclude current user
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

  Future<void> loadSection() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // int? projectID = prefs.getInt('projectID');
    int projectID = widget.projectID;
    print(projectID);
    // print("widget:${widget.detail}");
    if (projectID != null) {
      try {
        List<SectionModel> sections = await getSectionsByProjectID(projectID);
        // print("sections:$sections");
        if (sections.isNotEmpty) {
          setState(() {
            areaLabel = sections[0].labelName;
            // print("areaLabel:$areaLabel");
          });
        }
      } catch (e) {
        print('Error fetching sections: $e');
      }
    }
  }

  Future<void> loadFloor() async {
    int projectID = widget.projectID;
    // print(projectID);
    if (projectID != null) {
      try {
        List<FloorModel> floors = await getFloorByProjectID(projectID);
        if (floors.isNotEmpty) {
          setState(() {
            floorLabel = floors[0].floorName;
          });
        }
      } catch (e) {
        print('Error fetching floors: $e');
      }
    }
  }

  Future<void> loadElement() async {
    int projectID = widget.projectID;

    if (projectID != null) {
      try {
        List<ElementModel> elements = await getElementByProjectID(projectID);
        if (elements.isNotEmpty) {
          setState(() {
            elementLabel = elements[0].labelName;
            print("elementLabel :$elementLabel");
          });
        }
      } catch (e) {
        print('Error fetching elements: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.detail.observationCode ?? 'No Code',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            // Add this line
            child: DropdownButtonFormField<String>(
              value: selectedStatus, // must be String
              hint: const Text("-- Status --"),
              isExpanded: true,
              items: observationStatus.map((status) {
                final idStr = status['id'].toString(); // String
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
                      if (newValue != null) {
                        final int newStatus = int.parse(newValue);

                        setState(() {
                          fromStatus = toStatus; // 👈 old becomes fromStatus
                          toStatus = newStatus; // 👈 selected becomes toStatus
                          selectedStatus = newValue;
                        });

                        debugPrint(
                            "📥 fromStatus: $fromStatus, toStatus: $toStatus");
                      }
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
      content: Portal(
        child: SizedBox(
          width: double.maxFinite,
          child: DefaultTabController(
            length: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  labelColor: Colors.black,
                  tabs: [
                    Tab(text: "Detail"),
                    Tab(text: "Attachment"),
                    Tab(text: "Activity"),
                  ],
                ),
                SizedBox(
                  height: 422,
                  width: 700,
                  child: TabBarView(
                    children: [
                      _buildDetailTab(),
                      _buildAttachmentTab(),
                      _buildActivityTab(), // contains FlutterMentions
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildDetailTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.detail.description ?? 'N/A',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
            },
            children: [
              _buildAlignedRow(
                  "Observation Date : ",
                  _formatDate(widget.detail.trancationDate),
                  "Created Date : ",
                  _formatDate(widget.detail.createdDate)),
              _buildAlignedRow(
                "Observation Type : ",
                widget.detail.observationType ?? 'N/A',
                "Issue Type : ",
                widget.detail.issueType ?? 'N/A',
              ),
              _buildAlignedRow(
                  "Created By : ",
                  widget.detail.createdByName ?? 'N/A',
                  "Due Date : ",
                  _formatDate(widget.detail.dueDate)),
              _buildAlignedRow(
                  "Activity : ",
                  widget.detail.activityName ?? 'N/A',
                  "$areaLabel : ",
                  widget.detail.sectionName ?? 'N/A'),
              _buildAlignedRow(
                  "$floorLabel : ",
                  widget.detail.floorName ?? 'N/A',
                  "Part : ",
                  widget.detail.partName ?? 'N/A'),
              _buildAlignedRow(
                  "$elementLabel : ",
                  widget.detail.elementName ?? 'N/A',
                  "Contractor : ",
                  widget.detail.contractorName ?? 'N/A'),
              _buildAlignedRow(
                  "Compliance Required : ",
                  widget.detail.complianceRequired ? 'True' : 'False',
                  "Escalation Required : ",
                  widget.detail.escalationRequired ? 'True' : 'False'),
            ],
          ),
          const SizedBox(height: 24), // spacing between detail and form
          // Root Cause Form below details
          _buildRootCauseForm(),
        ],
      ),
    );
  }

  TableRow _buildAlignedRow(
      String label1, String value1, String label2, String value2) {
    return TableRow(
      children: [
        _buildLabelValue(label1, value1),
        _buildLabelValue(label2, value2),
      ],
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    return date != null
        ? DateFormat('dd/MM/yyyy').format(date.toLocal())
        : 'N/A';
  }

  Widget _buildRootCauseForm() {
    return Form(
      key: _formKey, // <-- Form key yahan lagao
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Existing form fields (Dropdown, TextFormFields)
            if (selectedStatus ==
                    SiteObservationStatus.ReadyToInspect.toString() ||
                selectedStatus == SiteObservationStatus.Closed.toString()) ...[
              DropdownButtonFormField<RootCause>(
                value: selectedRootCause,
                decoration: const InputDecoration(
                  labelText: 'Select Root Cause',
                  border: OutlineInputBorder(),
                ),
                items: rootCauses.map((cause) {
                  return DropdownMenuItem<RootCause>(
                    value: cause,
                    child: Text(cause.rootCauseName),
                  );
                }).toList(),
                onChanged: (newValue) {
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

            // File upload section
            if (selectedStatus ==
                    SiteObservationStatus.ReadyToInspect.toString() ||
                selectedStatus == SiteObservationStatus.Closed.toString() ||
                selectedStatus == SiteObservationStatus.Reopen.toString()) ...[
              const Text(
                "Upload File",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    allowMultiple: false,
                    withData: true,
                  );

                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;

                    setState(() {
                      selectedFileName = file.name;
                    });

                    final uploadedFileName = await SiteObservationService()
                        .uploadFileAndGetFileName(file.name, file.bytes!);

                    if (uploadedFileName != null) {
                      setState(() {
                        uploadedFiles.add(uploadedFileName);
                      });
                    } else {
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

            // Message if form is hidden (adjust condition as per your logic)
            if (selectedStatus !=
                    SiteObservationStatus.ReadyToInspect.toString() &&
                selectedStatus != SiteObservationStatus.InProgress.toString() &&
                selectedStatus == SiteObservationStatus.Closed.toString() &&
                selectedStatus == SiteObservationStatus.Reopen.toString())
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "Root Cause Details are hidden for the current status.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            // Update Button with validation
            if (selectedStatus != SiteObservationStatus.Open.toString())
              ElevatedButton(
                onPressed: isButtonDisabled
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() {
                            isButtonDisabled = true;
                            isEditingRootCause = false;
                          });

                          UpdateSiteObservation updatedData =
                              await getUpdatedDataFromForm(uploadedFiles);
                          // print("🔁 Updated Data: $updatedData");

                          bool success = await SiteObservationService()
                              .updateSiteObservationByID(updatedData);

                          if (success) {
                            for (var fileName in uploadedFiles) {
                              widget.detail.activityDTO.add(
                                ActivityDTO(
                                  id: 0,
                                  siteObservationID: widget.detail.id,
                                  actionID: SiteObservationActions.DocUploaded,
                                  actionName: "DocUploaded",
                                  comments: '',
                                  documentName: fileName,
                                  fromStatusID: fromStatus,
                                  toStatusID: toStatus,
                                  assignedUserID: 0,
                                  assignedUserName: null,
                                  createdBy: userId.toString(),
                                  createdDate: DateTime.now(),
                                ),
                              );
                            }

                            setState(() {
                              uploadedFiles.clear();
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Update successful!')),
                            );

                            Navigator.of(context).pop(true);
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
          ],
        ),
      ),
    );
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

  String resolveUserName(dynamic value) {
    if (value == null) return 'Unknown';

    // Convert to string for consistency
    final val = value.toString();

    // Try to match ID
    final isId = int.tryParse(val) != null;
    if (isId) {
      final user = userList.firstWhere(
        (u) => u['id'].toString() == val,
        orElse: () => {'display': 'Unknown'},
      );
      return user['display'] ?? 'Unknown';
    } else {
      // Match by name (case-insensitive)
      final user = userList.firstWhere(
        (u) => (u['display'] as String).toLowerCase() == val.toLowerCase(),
        orElse: () => {'display': val}, // fallback to value itself
      );
      return user['display'] ?? val;
    }
  }

  Widget _buildAttachmentTab() {
    // return Portal(
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Upload Image Button
            ElevatedButton.icon(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);

                if (pickedFile != null) {
                  File imageFile = File(pickedFile.path);
                  final fileName = imageFile.path.split('/').last;
                  final fileBytes = await compressImage(imageFile);

                  if (fileBytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Compression failed")),
                    );
                    return;
                  }

                  final uploadedFileName =
                      await SiteObservationService().uploadFileAndGetFileName(
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
                          actionID: SiteObservationActions.DocUploaded,
                          actionName: "DocUploaded",
                          comments: '',
                          documentName: uploadedFileName,
                          fromStatusID: fromStatus,
                          toStatusID: toStatus,
                          assignedUserID: userId!,
                          assignedUserName: currentUserName,
                          createdBy: currentUserName!,
                          createdDate: DateTime.now(),
                        ),
                      );
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Upload failed.")),
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
                  setState(() {
                    showSaveAttachmentButton = false;
                  });
                  UpdateSiteObservation updatedData =
                      await getUpdatedDataFromForm(uploadedFiles);
                  bool success = await SiteObservationService()
                      .updateSiteObservationByID(updatedData);
                  if (success) {
                    final newDetail = (await widget.siteObservationService
                            .fetchGetSiteObservationMasterById(
                                widget.detail.id))
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
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 10),
                            Text("Failed to save attachment."),
                          ],
                        ),
                        backgroundColor: Colors.black87,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    setState(() {
                      showSaveAttachmentButton = true;
                    });
                  }
                },
                child: const Text("Save Attachment"),
              ),

            const SizedBox(height: 16),

            /// Show Uploaded Images
            widget.detail.activityDTO.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.detail.activityDTO
                        .where((activity) => activity.documentName.isNotEmpty)
                        .map((activity) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activity.actionName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                openImageModal(activity.documentName);
                              },
                              child: Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    isImage(activity.documentName)
                                        ? "$url/${activity.documentName}"
                                        : "assets/default-image.png",
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image,
                                                size: 50),
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
    );
    // );
  }

  Widget _buildActivityTab() {
    final activities = widget.detail.activityDTO;
    // print("activities :$activities");
    if (activities.isEmpty) {
      return const Center(child: Text("No activity recorded."));
    }
    Map<String, List<ActivityDTO>> groupedActivities = {};
    Set<int> usedIndexes = {};

    for (int i = 0; i < activities.length; i++) {
      if (usedIndexes.contains(i)) continue;

      final current = activities[i];
      final group = <ActivityDTO>[current];
      usedIndexes.add(i);

      for (int j = i + 1; j < activities.length; j++) {
        if (usedIndexes.contains(j)) continue;

        final other = activities[j];
        final timeDiff =
            (other.createdDate.difference(current.createdDate)).inSeconds.abs();
        final sameUser = other.createdByName == current.createdByName;

        if (timeDiff <= 5 && sameUser) {
          group.add(other);
          usedIndexes.add(j);
        }
      }
      final creator = current.createdByName ?? 'Unknown';
      final groupKey = "$creator|${current.createdDate.toIso8601String()}";
      groupedActivities[groupKey] = group;
    }
    String getStatusNameById(int id) {
      return SiteObservationStatus.idToName[id] ?? 'Unknown';
    }

    return StatefulBuilder(builder: (context, setState) {
      return Portal(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: groupedActivities.entries.map((entry) {
                    final acts = entry.value;
                    final first = acts.first;
                    final statusName = first.toStatusName ?? "Unknown";
                    print("🟡 toStatusID: ${first.toStatusID}");
                    print("statusName: $statusName");
                    // print("userList sample: ${userList.take(3).toList()}");
                    String userName = first.createdByName ??
                        (() {
                          if (first.createdBy != null && userList.isNotEmpty) {
                            final createdByStr =
                                first.createdBy.toString().toLowerCase();

                            final matchedUser = userList.firstWhere(
                              (user) {
                                final idMatch =
                                    user['id'].toString() == createdByStr;
                                final displayMatch =
                                    (user['display'] ?? '').toLowerCase() ==
                                        createdByStr;
                                final fullNameMatch =
                                    (user['full_name'] ?? '').toLowerCase() ==
                                        createdByStr;
                                return idMatch || displayMatch || fullNameMatch;
                              },
                              orElse: () => {},
                            );

                            if (matchedUser.isNotEmpty) {
                              return matchedUser['full_name'] ??
                                  matchedUser['display'] ??
                                  createdByStr;
                            }

                            // Fallback to createdBy string if no match
                            return createdByStr;
                          }
                          return "Unknown";
                        })();
                    final date =
                        first.createdDate.toLocal().toString().split(' ')[0];
                    String nameToShow =
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?';
                    // print('nameToShow: ${nameToShow[0].toUpperCase()}');
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.flag,
                                      size: 16, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Status: $statusName',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Text(nameToShow),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    userName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  date,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: List.generate(acts.length, (index) {
                                final activity = acts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            if (index != acts.length - 1)
                                              Expanded(
                                                child: Container(
                                                  width: 2,
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildActivityStep(
                                                  activity.actionName,
                                                  activity.comments ?? "",
                                                  null,
                                                  activity.assignedUserName,
                                                ),

                                                // YEH NAYA ADD KARO HAR ACTIVITY KE LIYE
                                                if (activity.actionName ==
                                                        'DocUploaded' &&
                                                    activity.documentName !=
                                                        null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 12),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          'DocUploaded',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 13),
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        Container(
                                                          height: 100,
                                                          width: 100,
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                                color: Colors
                                                                    .grey
                                                                    .shade300),
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
                                                                Image.network(
                                                              "$url/${activity.documentName}",
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context,
                                                                      error,
                                                                      stackTrace) =>
                                                                  const Icon(
                                                                      Icons
                                                                          .broken_image,
                                                                      size: 50),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ]),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: FlutterMentions(
                        key: mentionsKey,
                        maxLines: 5,
                        minLines: 2,
                        suggestionPosition: SuggestionPosition.Top,
                        suggestionListHeight: 150,
                        suggestionListDecoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4)
                          ],
                        ),
                        decoration: InputDecoration(
                          hintText: "Add comment and assign user...",
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        mentions: [
                          Mention(
                            trigger: '@',
                            style: const TextStyle(color: Colors.blue),
                            data: userList,
                            matchAll: true,
                            suggestionBuilder: (data) {
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(data['display'][0].toUpperCase()),
                                ),
                                title: Text(data['display']),
                                subtitle: Text(data['full_name']),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendActivityComment,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(70, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Send"),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActivityStep(
      String action, String comment, String? image, String? assignedTo) {
    Color badgeColor;
    switch (action) {
      case "Created":
        badgeColor = Colors.blue;
        break;
      case "DocUploaded":
        badgeColor = Colors.green;
        break;
      case "Assigned":
        badgeColor = Colors.orange;
        break;
      case "Commented":
        badgeColor = Colors.pink;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                assignedTo ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Text(
            // date.toLocal().toString().split('.')[0],
            // style: const TextStyle(color: Colors.grey, fontSize: 12),
            // ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            action,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        if (image != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Image.network(
              "your_url/$image",
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        if (comment.isNotEmpty) Text(comment),
      ],
    );
  }

  void openImageModal(String documentName) {
    final imageUrl = "$url/$documentName";

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
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

  bool isImage(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.webp');
  }
}
