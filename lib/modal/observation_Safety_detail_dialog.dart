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
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ObservationSafetyDetailDialog extends StatefulWidget {
  final GetSiteObservationMasterById detail;
  final SiteObservationService siteObservationService;
  final int siteObservationId;
  final String? createdBy;
  final int? activityId;
  final int projectID;

  const ObservationSafetyDetailDialog({
    super.key,
    required this.detail,
    required this.siteObservationService,
    required this.siteObservationId,
    required this.createdBy,
    required this.activityId,
    required this.projectID,
  });

  @override
  _ObservationSafetyDetailDialogState createState() =>
      _ObservationSafetyDetailDialogState();
}

class ObservationLoadingDialog extends StatelessWidget {
  const ObservationLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Loading observation..."),
          ],
        ),
      ),
    );
  }
}

class _ObservationSafetyDetailDialogState
    extends State<ObservationSafetyDetailDialog> {
  bool isLoading = false;
  int? selectedStatus;
  List<Map<String, String>> observationStatus = [];

  List<RootCause> rootCauses = [];
  // RootCause? selectedRootCause;
  int? selectedRootCauseId;
  bool isStatusEnabled = false;
  bool isEditingRootCause = false;
  bool isButtonDisabled = false;
  bool canEditRootCause = false;
  bool finalStatusEnabled = false;
  // bool collapsed = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController rootCauseController = TextEditingController();
  final TextEditingController rootcauseDescriptionController =
      TextEditingController();
  final TextEditingController materialCostController = TextEditingController();
  final TextEditingController labourCostController = TextEditingController();
  final TextEditingController reworkCostController = TextEditingController();
  final TextEditingController preventiveActionController =
      TextEditingController();
  final TextEditingController correctiveActionController =
      TextEditingController();
  final TextEditingController _activityCommentController =
      TextEditingController();
  GlobalKey<FlutterMentionsState> mentionsKey =
      GlobalKey<FlutterMentionsState>();

  final TextEditingController reopenRemarksController = TextEditingController();
  final TextEditingController closeRemarksController = TextEditingController();
  final TextEditingController inProgessRemarksController =
      TextEditingController();
  final TextEditingController inReadyToInspectRemarksController =
      TextEditingController();

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
  // String? areaLabel;
  // String? floorLabel;
  // String? pourLabel;
  // String? elementLabel;
  String areaLabel = "Block";
  String floorLabel = "Floor";
  String pourLabel = "Pour";
  String elementLabel = "Element";

  bool isSending = false;

  bool isReopenAction = false;
  bool isCloseAction = false;

  bool isRootCauseFileUpdateEnable =
      false; // 👈 Angular ka isRootCauseFileUpdateEnable

  bool isReopenRemarksVisible = false;
  bool isCloseRemarksVisible = false;
  bool inProgessRemarksVisible = false;
  bool inReadyToInspectRemarksVisible = false;
  bool isUpdateBtnVisible = false;
  bool collapsed = false;

  String selectedActionType = 'Comment';
  String mentionsPlaceholder = "Please add comment...";
  bool isMentionsEnabled = false;
  List<User> selectedMentions = [];

  static final MethodChannel _galleryChannel = MethodChannel('gallery_scanner');

  late void Function(void Function()) _activityTabSetState;
  late Future<void> _labelFuture;
  bool isFirstLoad = true;

  bool isCommentBoxDisabled = false;
  bool canUploadAttachments = false;
  // bool isObservationClosed = false;

  bool statusEnabled = false;
  bool textEnabled = false;
  bool actionEnabled = false;
  bool commentDisabled = false;

  @override
  void initState() {
    super.initState();
    currentDetail = widget.detail;
    _setupPage();
    _labelFuture = Future.wait([
      loadSection(),
      loadFloor(),
      loadPour(),
      loadElement(),
    ]);
  }

  Future<void> _setupPage() async {
    final statusId = widget.detail.statusID;

    if (statusId != 0) {
      selectedStatus = statusId; // Dropdown ke liye string chahiye
      fromStatus = statusId; // Current status id
      toStatus = statusId;
      await setObservationStatusDropdown(
        statusId,
        widget.detail.createdBy,
        widget.detail,
      );
    } else {
      selectedStatus = null;
      fromStatus = 0; // Ya default koi bhi status id rakh lo
      toStatus = 0;
    }
    await _loadRootCauses(); // wait for root causes to load before proceeding

    _initializeFormFields(); // now safe to initialize form fields with loaded data

    editingUserId = widget.siteObservationId;
    await initData(); // optionally await this if it’s async

    materialCostController.addListener(_updateReworkCost);
    labourCostController.addListener(_updateReworkCost);
    // setState(() {
    //   isRootCauseFileUpdateEnable = false;
    // });
  }

  void _updateReworkCost() {
    double material = double.tryParse(materialCostController.text) ?? 0;
    double labour = double.tryParse(labourCostController.text) ?? 0;

    double total = material + labour;

    reworkCostController.text = total.toStringAsFixed(2);
  }

  bool get isObservationClosed =>
      widget.detail.statusID == SiteObservationStatus.Closed;

  bool get isUploadDisabled {
    final isClosed = widget.detail.statusName?.toLowerCase() == 'closed';
    // final isActive = widget.detail.isActive == true;
    final userHasPermission = canUploadAttachments == true;

    return isClosed || !userHasPermission;
  }

  String? get attachmentRestrictionMessage {
    if (isObservationClosed) {
      return "Modification is not allowed as the observation status is closed.";
    }

    if (!canUploadAttachments) {
      return "You do not have sufficient access rights to modify this observation.";
    }

    return null; // no restriction
  }

  Future<void> initData() async {
    int projectID = widget.projectID;
    await fetchUsers();
    setState(() {
      // isMentionsEnabled = selectedActionType == 'Assign' && userList.isNotEmpty;
      // only enable mentions now if user selected 'Assign'
      isMentionsEnabled =
          (selectedActionType == 'Assign' || selectedActionType == 'Comment') &&
              userList.isNotEmpty;
    });
    userId = await SharedPrefsHelper.getUserId();
    currentUserName = await SharedPrefsHelper.getUserName();
  }

  void _initializeFormFields() {
    int rootCauseIDs = widget.detail.rootCauseID ?? 0;

    // default
    // selectedRootCauseId = null;

    // selectedStatus is int? now
    int statusInt = selectedStatus ?? 0;

    /// -------- OPEN --------
    if (statusInt == SiteObservationStatus.Open ||
        statusInt == SiteObservationStatus.Reopen) {
      if (rootCauseIDs != 0) selectedRootCauseId = rootCauseIDs;
    }

    // /// -------- ReadyToInspect / Closed --------
    // if (statusInt == SiteObservationStatus.ReadyToInspect ||
    //     statusInt == SiteObservationStatus.Closed) {
    //   selectedRootCauseId = null; // force reselect
    // }

    /// -------- Reopen --------
    if (statusInt == SiteObservationStatus.Reopen) {
      if (rootCauseIDs != 0) selectedRootCauseId = rootCauseIDs;
    }

    // text fields
    rootcauseDescriptionController.text =
        widget.detail.rootcauseDescription ?? '';
    materialCostController.text = widget.detail.materialCost?.toString() ?? '';
    labourCostController.text = widget.detail.labourCost?.toString() ?? '';
    reworkCostController.text = widget.detail.reworkCost?.toString() ?? '';
    preventiveActionController.text = widget.detail.preventiveActionTaken ?? '';
    correctiveActionController.text =
        widget.detail.corretiveActionToBeTaken ?? '';
  }

  ActivityDTO buildAssignedActivity({
    required int siteObservationID,
    required int assignedUserID,
  }) {
    return ActivityDTO(
      id: 0,
      siteObservationID: siteObservationID,
      actionID: SiteObservationActions.Assigned,
      actionName: 'Assigned',
      comments: '',
      documentName: '',
      fromStatusID: fromStatus,
      toStatusID: toStatus,
      assignedUserID: assignedUserID,
      createdBy: userId,
      createdDate: DateTime.now().toUtc(),
    );
  }

  ActivityDTO buildCommentActivity({
    required int siteObservationID,
    required String comment,
  }) {
    return ActivityDTO(
      id: 0,
      siteObservationID: siteObservationID,
      actionID: SiteObservationActions.Commented,
      actionName: 'Commented',
      comments: comment,
      documentName: '',
      fromStatusID: fromStatus,
      toStatusID: toStatus,
      assignedUserID: 0,
      createdBy: userId,
      createdDate: DateTime.now().toUtc(),
    );
  }

  Future<void> _loadRootCauses() async {
    setState(() => isLoading = true);

    try {
      int? companyId = await SharedPrefsHelper.getCompanyId();
      if (companyId == null) return;

      final data =
          await SiteObservationService().fatchRootCausesByActivityID(companyId);

      // ✅ STEP 1: dropdown items set
      setState(() {
        rootCauses = data;
      });

      // ✅ STEP 2: backend se aaya hua rootCauseID
      final backendRootCauseId = widget.detail.rootCauseID;

      // ✅ STEP 3: dropdown value TABHI set karo jab item exist kare
      if (backendRootCauseId != null &&
          rootCauses.any((e) => e.id == backendRootCauseId)) {
        setState(() {
          selectedRootCauseId = backendRootCauseId;
        });
      }
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
    int? rootCauseID = selectedRootCauseId;
    List<ActivityDTO> activities = [];

    int selectedStatusId =
        int.tryParse(selectedStatus.toString()) ?? SiteObservationStatus.Open;

    String? reopenRemarks;
    String? closeRemarks;
    String? inprogressRemarks;
    String? readytoinspectRemarks;

    /// ---------------- STATUS BASED REMARKS ----------------
    if (selectedStatusId == SiteObservationStatus.Reopen) {
      reopenRemarks = reopenRemarksController.text.trim();
    }

    if (selectedStatusId == SiteObservationStatus.Closed) {
      closeRemarks = closeRemarksController.text.trim();
    }

    if (selectedStatusId == SiteObservationStatus.InProgress) {
      inprogressRemarks = inProgessRemarksController.text.trim();
    }

    if (selectedStatusId == SiteObservationStatus.ReadyToInspect) {
      readytoinspectRemarks = inReadyToInspectRemarksController.text.trim();
    }

    /// ---------------- READY TO INSPECT ----------------
    if (selectedStatusId == SiteObservationStatus.ReadyToInspect) {
      activities.add(
        buildAssignedActivity(
          siteObservationID: id,
          assignedUserID: widget.detail.createdBy!,
        ),
      );

      if (readytoinspectRemarks?.isNotEmpty == true) {
        activities.add(
          buildCommentActivity(
            siteObservationID: id,
            comment: readytoinspectRemarks!,
          ),
        );
      }
    }

    /// ---------------- REOPEN ----------------
    else if (selectedStatusId == SiteObservationStatus.Reopen) {
      final assignedUsers =
          await SiteObservationService().fetchGetassignedusersforReopen(id);

      for (var user in assignedUsers) {
        activities.add(
          buildAssignedActivity(
            siteObservationID: id,
            assignedUserID: user.assignedUserID,
          ),
        );
      }

      if (reopenRemarks?.isNotEmpty == true) {
        activities.add(
          buildCommentActivity(
            siteObservationID: id,
            comment: reopenRemarks!,
          ),
        );
      }
    }

    /// ---------------- IN PROGRESS / CLOSED ----------------
    else if (selectedStatusId == SiteObservationStatus.InProgress ||
        selectedStatusId == SiteObservationStatus.Closed) {
      activities.add(
        buildAssignedActivity(
          siteObservationID: id,
          assignedUserID: widget.detail.createdBy!,
        ),
      );

      if (selectedStatusId == SiteObservationStatus.InProgress &&
          inprogressRemarks?.isNotEmpty == true) {
        activities.add(
          buildCommentActivity(
            siteObservationID: id,
            comment: inprogressRemarks!,
          ),
        );
      }

      if (selectedStatusId == SiteObservationStatus.Closed &&
          closeRemarks?.isNotEmpty == true) {
        activities.add(
          buildCommentActivity(
            siteObservationID: id,
            comment: closeRemarks!,
          ),
        );
      }
    }

    /// ---------------- FILE UPLOAD ----------------
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
          createdBy: userId,
          createdDate: DateTime.now().toUtc(),
        ),
      );
    }

    /// ---------------- FINAL MODEL ----------------
    return UpdateSiteObservation(
      id: id,
      rootCauseID: rootCauseID,
      rootcauseDescription: rootcauseDescriptionController.text,
      corretiveActionToBeTaken: correctiveActionController.text,
      preventiveActionTaken: preventiveActionController.text,
      materialCost: double.tryParse(materialCostController.text) ?? 0.0,
      labourCost: double.tryParse(labourCostController.text) ?? 0.0,
      reworkCost: double.tryParse(reworkCostController.text) ?? 0.0,
      statusID: selectedStatusId,
      reopenRemarks: reopenRemarks,
      closeRemarks: closeRemarks,
      inprogressRemarks: inprogressRemarks,
      readytoinspectRemarks: readytoinspectRemarks,
      lastModifiedBy: userId!,
      lastModifiedDate: DateTime.now().toUtc(),
      activityDTO: activities,
    );
  }

  // Future<UpdateSiteObservation> getUpdatedDataFromForm(
  //     List<String> uploadedFiles) async {
  //   int id = widget.detail.id;
  //   int rootCauseID = selectedRootCause?.id ?? 0;

  //   String? reopenRemarks;
  //   String? closeRemarks;
  //   String? inprogressRemarks;
  //   String? readytoinspectRemarks;

  //   List<ActivityDTO> activities = [];
  //   int selectedStatusId =
  //       int.tryParse(selectedStatus ?? '') ?? SiteObservationStatus.Open;

  //   if (selectedStatusId == SiteObservationStatus.Reopen) {
  //     reopenRemarks = reopenRemarksController.text;
  //   }

  //   if (selectedStatusId == SiteObservationStatus.Closed) {
  //     closeRemarks = closeRemarksController.text;
  //   }

  //   if (selectedStatusId == SiteObservationStatus.InProgress) {
  //     inprogressRemarks = inProgessRemarksController.text;
  //   }

  //   if (selectedStatusId == SiteObservationStatus.ReadyToInspect) {
  //     readytoinspectRemarks = inReadyToInspectRemarksController.text;
  //   }

  //   if (selectedStatusId == SiteObservationStatus.ReadyToInspect) {
  //     activities.add(
  //       ActivityDTO(
  //         id: 0,
  //         siteObservationID: id,
  //         actionID: SiteObservationActions.Assigned,
  //         actionName: 'Assigned',
  //         comments: '',
  //         documentName: '',
  //         fromStatusID: fromStatus,
  //         toStatusID: toStatus,
  //         assignedUserID: widget.detail.createdBy,
  //         assignedUserName: null,
  //         createdBy: userId,
  //         createdDate: DateTime.now(),
  //       ),
  //     );

  //     activities.add(
  //       ActivityDTO(
  //         id: 0,
  //         siteObservationID: id,
  //         actionID: SiteObservationActions.Assigned,
  //         actionName: 'Assigned',
  //         comments: '',
  //         documentName: '',
  //         fromStatusID: fromStatus,
  //         toStatusID: toStatus,
  //         assignedUserID: widget.detail.createdBy,
  //         assignedUserName: null,
  //         createdBy: userId,
  //         createdDate: DateTime.now(),
  //       ),
  //     );
  //   } else if (selectedStatusId == SiteObservationStatus.Reopen) {
  //     final assignedUsers =
  //         await SiteObservationService().fetchGetassignedusersforReopen(id);

  //     // Add an activity for each assigned user
  //     for (var user in assignedUsers) {
  //       activities.add(
  //         ActivityDTO(
  //           id: 0,
  //           siteObservationID: id,
  //           actionID: SiteObservationActions.Assigned,
  //           actionName: 'Assigned',
  //           comments: '',
  //           documentName: '',
  //           fromStatusID: fromStatus,
  //           toStatusID: toStatus,
  //           assignedUserID: user.assignedUserID,
  //           createdBy: userId,
  //           createdDate: DateTime.now(),
  //         ),
  //       );
  //     }
  //   }

  //   // Add file uploads if available
  //   for (String fileName in uploadedFiles) {
  //     activities.add(
  //       ActivityDTO(
  //         id: 0,
  //         siteObservationID: id,
  //         actionID: SiteObservationActions.DocUploaded,
  //         actionName: 'DocUploaded',
  //         comments: '',
  //         documentName: fileName,
  //         fromStatusID: fromStatus,
  //         toStatusID: toStatus,
  //         assignedUserID: userId!,
  //         assignedUserName: null,
  //         createdBy: userId,
  //         createdDate: DateTime.now(),
  //       ),
  //     );
  //   }

  //   print("inprogressRemarks,$inprogressRemarks");

  //   return UpdateSiteObservation(
  //     id: id,
  //     rootCauseID: rootCauseID,
  //     rootcauseDescription: rootcauseDescriptionController.text,
  //     corretiveActionToBeTaken: correctiveActionController.text,
  //     preventiveActionTaken: preventiveActionController.text,
  //     materialCost: double.tryParse(materialCostController.text) ?? 0.0,
  //     labourCost: double.tryParse(labourCostController.text) ?? 0.0,
  //     reworkCost: double.tryParse(reworkCostController.text) ?? 0.0,
  //     statusID: selectedStatusId,
  //     reopenRemarks: reopenRemarks,
  //     closeRemarks: closeRemarks,
  //     inprogressRemarks: inprogressRemarks,
  //     readytoinspectRemarks: readytoinspectRemarks,
  //     lastModifiedBy: userId!,
  //     lastModifiedDate: DateTime.now(),
  //     activityDTO: activities,
  //   );
  // }

  String getAttachmentStatusName(ActivityDTO activity) {
    final relatedActivities = widget.detail.activityDTO
        .where((a) => a.documentName == activity.documentName)
        .toList();

    if (relatedActivities.isEmpty) return 'Unknown';

    // Latest activity (createdDate ke basis pe)
    relatedActivities.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    final latestActivity = relatedActivities.first;

    // Web jaise approach
    return latestActivity.toStatusName ?? 'Unknown';
  }

  String getStatusNameFromId(String id) {
    final status = observationStatus.firstWhere(
      (e) => e['id'].toString() == id,
      orElse: () => {'name': 'Unknown'},
    );
    return status['name'] ?? 'Unknown';
  }

  // Future<void> _sendActivityComment() async {
  //   if (isSending) return;
  //   setState(() {
  //     isSending = true; // send start hone pe disable kar do
  //   });
  //   try {
  //     final markupText = mentionsKey.currentState?.controller!.markupText ?? "";
  //     final RegExp mentionRegex = RegExp(r'\@\[(.*?)\]\((.*?)\)');
  //     final Iterable<RegExpMatch> matches = mentionRegex.allMatches(markupText);

  //     List<User> selectedUsers = matches.map((match) {
  //       String rawIdStr = match.group(1)!;
  //       String rawUserName = match.group(2)!;

  //       String cleanedIdStr = rawIdStr.replaceAll('_', '');
  //       String cleanedUserName = rawUserName.replaceAll('_', '');

  //       int userId = int.tryParse(cleanedIdStr) ?? 0;

  //       // final matchedUser = allUsers.firstWhere(
  //       //   (user) => user.id == userId,
  //       //   orElse: () => User(id: 0, userName: ''),
  //       // );

  //       final matchedUser = allUsers.firstWhere(
  //         (user) => user.id == userId,
  //         orElse: () => User(
  //             id: userId,
  //             userName: cleanedUserName), // ✅ fallback me bhi name jaaye
  //       );

  //       String finalUserName = matchedUser.userName.isNotEmpty
  //           ? matchedUser.userName
  //           : cleanedUserName;

  //       return User(id: userId, userName: finalUserName);
  //     }).toList();

  //     // ✅ Fix is here — get int userId only
  //     // int createdBy = await SharedPrefsHelper.getUserId() ?? 0;
  //     // String createdBy = await SharedPrefsHelper.getUserName() ?? 'Unknown';
  //     // String createdBy = await SharedPrefsHelper.getUserName() ?? 'Unknown';
  //     int createdById = await SharedPrefsHelper.getUserId() ?? 0;
  //     String createdByName = await SharedPrefsHelper.getUserName() ?? 'Unknown';

  //     // int createdBy = await SharedPrefsHelper.getUserId() ?? 0;
  //     List<ActivityDTO> activities = [];

  //     final commentText =
  //         mentionsKey.currentState?.controller?.text.trim() ?? "";
  //     final plainComment =
  //         commentText.replaceAll(RegExp(r'\@\[(.*?)\]\((.*?)\)'), '').trim();

  //     bool hasMentions = selectedUsers.isNotEmpty;
  //     bool hasComment = plainComment.isNotEmpty;
  //     // CASE 1 — Only mention(s)
  //     if (hasMentions && !hasComment) {
  //       for (var user in selectedUsers) {
  //         activities.add(ActivityDTO(
  //           id: 0,
  //           siteObservationID: editingUserId,
  //           actionID: SiteObservationActions.Assigned,
  //           actionName: "Assigned",
  //           comments: "",
  //           documentName: "",
  //           fromStatusID: fromStatus,
  //           toStatusID: toStatus,
  //           toStatusName: SiteObservationStatus.idToName[toStatus] ??
  //               "Unknown", // ✅ Add this
  //           assignedUserID: user.id,
  //           assignedUserName: user.userName,
  //           createdBy: createdById, // ✅ send as integer
  //           createdByName: createdByName,
  //           createdDate: DateTime.now(),
  //         ));
  //       }
  //     }

  //     // CASE 2 — Only comment
  //     else if (!hasMentions && hasComment) {
  //       activities.add(ActivityDTO(
  //         id: 0,
  //         siteObservationID: editingUserId,
  //         actionID: SiteObservationActions.Commented,
  //         actionName: "Commented",
  //         comments: plainComment,
  //         documentName: "",
  //         fromStatusID: fromStatus,
  //         toStatusID: toStatus,
  //         toStatusName: SiteObservationStatus.idToName[toStatus] ??
  //             "Unknown", // ✅ Add this
  //         assignedUserID: 0,
  //         // assignedUserName: '',
  //         // createdBy: createdBy, // ✅ integer
  //         createdBy: createdById,
  //         createdByName: createdByName,
  //         assignedUserName: createdByName,
  //         createdDate: DateTime.now(),
  //       ));
  //     }

  //     // CASE 3 — Both mention(s) and comment
  //     else if (hasMentions && hasComment) {
  //       for (var user in selectedUsers) {
  //         activities.add(ActivityDTO(
  //           id: 0,
  //           siteObservationID: editingUserId,
  //           actionID: SiteObservationActions.Assigned,
  //           actionName: "Assigned",
  //           comments: "",
  //           documentName: "",
  //           fromStatusID: fromStatus,
  //           toStatusID: toStatus,
  //           toStatusName: SiteObservationStatus.idToName[toStatus] ??
  //               "Unknown", // ✅ Add this
  //           assignedUserID: user.id,
  //           assignedUserName: user.userName,
  //           createdBy: createdById, // ✅ integer
  //           createdByName: createdByName,
  //           createdDate: DateTime.now(),
  //         ));
  //       }

  //       activities.add(ActivityDTO(
  //         id: 0,
  //         siteObservationID: editingUserId,
  //         actionID: SiteObservationActions.Commented,
  //         actionName: "Commented",
  //         comments: plainComment,
  //         documentName: "",
  //         fromStatusID: fromStatus,
  //         toStatusID: toStatus,
  //         toStatusName: SiteObservationStatus.idToName[toStatus] ??
  //             "Unknown", // ✅ Add this
  //         assignedUserID: 0,
  //         assignedUserName: '',
  //         createdBy: createdById, // ✅ integer
  //         createdByName: createdByName,
  //         createdDate: DateTime.now(),
  //       ));
  //     }

  //     if (activities.isEmpty) {
  //       return;
  //     }

  //     bool success = await SiteObservationService().sendSiteObservationActivity(
  //       activities: activities,
  //       siteObservationID: editingUserId,
  //     );

  //     if (success) {
  //       mentionsKey.currentState?.controller?.clear();
  //       _activityCommentController.clear();

  //       setState(() {
  //         widget.detail.activityDTO.insertAll(0, activities);
  //       });
  //     } else {
  //       print("❌ Failed to post activity!");
  //     }
  //   } catch (e, st) {
  //     print(st);
  //   } finally {
  //     setState(() {
  //       isSending = false; // send complete hone ke baad enable kar do
  //     });
  //   }
  // }

  Future<void> _sendActivityComment() async {
    if (isSending) return;
    setState(() => isSending = true);

    try {
      // --- 1. Current user info ---
      final int currentUserId = await SharedPrefsHelper.getUserId() ?? 0;
      final String currentUserName =
          await SharedPrefsHelper.getUserName() ?? 'Unknown';

      // --- 2. Get markup text from FlutterMentions ---
      final markupText = mentionsKey.currentState?.controller?.markupText ?? '';

      final RegExp mentionRegex = RegExp(r'\@\[(.*?)\]\((.*?)\)');

      // --- 3. Extract mentioned users (ONLY for Assign mode) ---
      final matches = mentionRegex.allMatches(markupText);
      final List<User> selectedMentions = matches.map((m) {
        final id = int.tryParse(m.group(1)?.replaceAll('_', '') ?? '') ?? 0;
        final name = m.group(2)?.replaceAll('_', '') ?? '';
        return User(id: id, userName: name);
      }).toList();

      // --- 4. Build readable comment text ---
      // String commentText = markupText.replaceAllMapped(mentionRegex, (m) {
      //   return '@${m.group(2)}';
      // }).trim();
      String commentText = markupText
          // convert @[id](name) → @name
          .replaceAllMapped(mentionRegex, (m) {
            return '@${m.group(2)}';
          })
          // remove flutter_mentions styling __
          .replaceAll('__', '')
          .trim();

      bool hasComment = commentText.isNotEmpty;
      bool hasMentions = selectedMentions.isNotEmpty;

      if (!hasComment && !hasMentions) return;

      // --- 5. Prepare activities ---
      List<ActivityDTO> activities = [];

      // =========================
      // COMMENT MODE
      // =========================
      if (selectedActionType == 'Comment' && hasComment) {
        activities.add(ActivityDTO(
          id: 0,
          siteObservationID: editingUserId,
          actionID: SiteObservationActions.Commented,
          actionName: "Commented",
          comments: commentText, // contains @username text only
          documentName: "",
          assignedUserID: 0,
          assignedUserName: '',
          createdBy: currentUserId,
          createdByName: currentUserName,
          createdDate: DateTime.now().toUtc(),
          fromStatusID: fromStatus,
          toStatusID: toStatus,
          toStatusName: SiteObservationStatus.idToName[toStatus] ?? "Unknown",
        ));
      }

      // =========================
      // ASSIGN MODE
      // =========================
      else if (selectedActionType == 'Assign' && hasMentions) {
        for (var user in selectedMentions) {
          activities.add(ActivityDTO(
            id: 0,
            siteObservationID: editingUserId,
            actionID: SiteObservationActions.Assigned,
            actionName: "Assigned",
            comments: "",
            documentName: "",
            assignedUserID: user.id,
            assignedUserName: user.userName,
            createdBy: currentUserId,
            createdByName: currentUserName,
            createdDate: DateTime.now().toUtc(),
            fromStatusID: fromStatus,
            toStatusID: toStatus,
            toStatusName: SiteObservationStatus.idToName[toStatus] ?? "Unknown",
          ));
        }
      }

      if (activities.isEmpty) return;

      // --- 6. Send to API ---
      final bool success =
          await SiteObservationService().sendSiteObservationActivity(
        activities: activities,
        siteObservationID: editingUserId,
      );

      if (success) {
        // Clear input
        mentionsKey.currentState?.controller?.clear();
        _activityCommentController.clear();

        // Add new activities to top
        setState(() {
          widget.detail.activityDTO.insertAll(0, activities);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to post activity.")),
        );
      }
    } catch (e, st) {
      debugPrint("❌ Error in _sendActivityComment: $e\n$st");
    } finally {
      setState(() => isSending = false);
    }
  }

  Future<void> fetchUsers() async {
    try {
      final int flag = selectedActionType == 'Assign' ? 2 : 1;
      final response =
          await SiteObservationService().getUsersForSiteObservation(
        siteObservationId: widget.detail.id,
        flag: flag,
      );

      final currentUserId = await SharedPrefsHelper.getUserId();
      final userUploadDoc =
          response.where((u) => u.id == currentUserId).toList();

      if (flag == 1 &&
          userUploadDoc.isNotEmpty &&
          userUploadDoc.first.id == currentUserId) {
        canUploadAttachments = true;
      } else if (flag == 2 &&
          userUploadDoc.isNotEmpty &&
          userUploadDoc.first.id != currentUserId) {
        canUploadAttachments = true;
      } else {
        canUploadAttachments = false;
      }

      final creatorUserId = widget.detail.createdBy;

      // 🔥 Step 1: collect assigned usernames (exclude null/empty)
      final assignedUserNames = widget.detail.activityDTO
          .where((a) => a.actionID == SiteObservationActions.Assigned)
          .map((a) => a.assignedUserName!.toLowerCase().trim())
          .toSet();

      List<UserList> filteredUsers;

      if (selectedActionType == 'Assign') {
        // ASSIGN → all users except current + creator
        filteredUsers = response.where((u) {
          final notCurrentUser = u.id != currentUserId;
          final notCreator = creatorUserId == null || u.id != creatorUserId;
          return notCurrentUser && notCreator;
        }).toList();
      } else {
        // COMMENT → only assigned users, exclude current + creator
        filteredUsers = response.where((u) {
          final userNameNorm = u.userName.toLowerCase().trim();
          final isAssigned = assignedUserNames.contains(userNameNorm);
          final notCurrentUser = u.id != currentUserId;
          final notCreator = creatorUserId == null || u.id != creatorUserId;
          return isAssigned && notCurrentUser && notCreator;
        }).toList();
      }

      setState(() {
        userList = filteredUsers
            .map((u) => {
                  'id': u.id.toString(),
                  'display': u.userName,
                  'full_name': '${u.firstName} ${u.lastName}',
                })
            .toList();

        isMentionsEnabled = userList.isNotEmpty;

        // 🔥 Force FlutterMentions rebuild to reflect new data
        mentionsKey = GlobalKey<FlutterMentionsState>();
      });
    } catch (e) {
      debugPrint("fetchUsers error: $e");
    }
  }

  Future<void> loadSection() async {
    int projectID = widget.projectID;
    if (projectID != null) {
      try {
        List<SectionModel> sections = await widget.siteObservationService
            .getSectionsByProjectID(projectID);
        if (sections.isNotEmpty) {
          setState(() {
            areaLabel = sections[0].labelName;
          });
        }
      } catch (e) {
        print('Error fetching sections: $e');
      }
    }
  }

  Future<void> loadFloor() async {
    int projectID = widget.projectID;
    if (projectID != null) {
      try {
        List<FloorModel> floors =
            await widget.siteObservationService.getFloorByProjectID(projectID);
        if (floors.isNotEmpty) {
          setState(() {
            floorLabel = floors[0].labelName;
            print("floorLabel,$floorLabel");
          });
        }
      } catch (e) {
        print('Error fetching floors: $e');
      }
    }
  }

  Future<void> loadPour() async {
    int projectID = widget.projectID;
    // print("Saved at: $projectID");
    if (projectID != null) {
      try {
        List<PourModel> pours =
            await widget.siteObservationService.getPourByProjectID(projectID);
        if (pours.isNotEmpty) {
          setState(() {
            pourLabel = pours[0].labelName; // ✅ now it shows the label
            // pourName = pours[0].partName;   // optional: store the actual pour name
          });
        }
      } catch (e) {
        print('Error fetching pours: $e');
      }
    }
  }

  Future<void> loadElement() async {
    int projectID = widget.projectID;

    if (projectID != null) {
      try {
        List<ElementModel> elements = await widget.siteObservationService
            .getElementByProjectID(projectID);
        if (elements.isNotEmpty) {
          setState(() {
            elementLabel = elements[0].labelName;
          });
        }
      } catch (e) {
        print('Error fetching elements: $e');
      }
    }
  }

  Future<void> setObservationStatusDropdown(
    int statusId,
    int? createdBy,
    GetSiteObservationMasterById detail,
  ) async {
    int? userID = await SharedPrefsHelper.getUserId();

    final isAssign =
        detail.activityDTO.where((e) => e.assignedUserID == userID).toList();

    fromStatus = statusId == 0 ? SiteObservationStatus.Open : statusId;

    toStatus = fromStatus;

    List<Map<String, String>> newStatusList = [];
    bool newStatusEnabled = true;
    final editassignmentDetails = widget.detail.assignmentStatusDTO;

    // 🔹 DEFAULT ROOT CAUSE PERMISSION
    canEditRootCause = fromStatus == SiteObservationStatus.ReadyToInspect ||
        fromStatus == SiteObservationStatus.Closed;
    print("canEditRootCause, $canEditRootCause");
    // -------------------------------
    // 🔥 STATUS RULES
    // -------------------------------

    // ✅ FIRST TIME OPEN
    if (fromStatus == SiteObservationStatus.Open) {
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
    }

    // ✅ READY TO INSPECT – CREATOR
    else if (fromStatus == SiteObservationStatus.ReadyToInspect &&
        createdBy == userID &&
        isAssign.isEmpty) {
      newStatusList = [
        {
          "id": SiteObservationStatus.ReadyToInspect.toString(),
          "name": "Ready To Inspect"
        },
        {"id": SiteObservationStatus.Closed.toString(), "name": "Closed"},
        {"id": SiteObservationStatus.Reopen.toString(), "name": "Reopen"},
      ];
      // isRootCauseFileUpdateEnable = true;
      finalStatusEnabled = true; // ✅ correct
    }

    // ✅ READY TO INSPECT – OTHERS
    else if (fromStatus == SiteObservationStatus.ReadyToInspect) {
      newStatusList = [
        {
          "id": SiteObservationStatus.ReadyToInspect.toString(),
          "name": "Ready To Inspect"
        }
      ];
      newStatusEnabled = false;
    }

    // ✅ CLOSED
    else if (fromStatus == SiteObservationStatus.Closed) {
      newStatusList = [
        {"id": SiteObservationStatus.Closed.toString(), "name": "Closed"}
      ];
      newStatusEnabled = false;
      canEditRootCause = true;

      // isObservationClosed = true;
      // isCommentBoxDisabled = true;
    }

    // ✅ DEFAULT FLOW
    else {
      newStatusList = [
        {
          "id": SiteObservationStatus.InProgress.toString(),
          "name": "In Progress"
        },
        {
          "id": SiteObservationStatus.ReadyToInspect.toString(),
          "name": "Ready To Inspect"
        }
      ];
      // inProgessRemarksVisible = true;
    }

    // -------------------------------
    // 🔐 FINAL SAFETY
    // -------------------------------

    if (fromStatus == SiteObservationStatus.Closed) {
      statusEnabled = false;
      textEnabled = false;
      actionEnabled = false;
      commentDisabled = false;
      isStatusEnabled = false;
      finalStatusEnabled = false;
    }

    // -------------------------
    // 🟢 CASE 2: NOT CLOSED
    // -------------------------
    else {
      for (final element in editassignmentDetails) {
        if (element.assignedUserID == userID) {
          statusEnabled = true;
          textEnabled = true;
          actionEnabled = true;
          commentDisabled = true;
          isStatusEnabled = true;
          finalStatusEnabled = true;
          break;
        }
      }

      // ✅ CREATOR CASE
      if (createdBy == userID) {
        textEnabled = true;
        actionEnabled = true;
        commentDisabled = true;
        isStatusEnabled = false;
        // isStatusEnabled = fromStatus == SiteObservationStatus.ReadyToInspect;
      }
    }

    if (!newStatusList.any((e) => e['id'] == fromStatus.toString())) {
      newStatusList.insert(0, {
        "id": fromStatus.toString(),
        "name": SiteObservationStatus.idToName[fromStatus] ?? "Unknown"
      });
    }

    setState(() {
      observationStatus = newStatusList;
      selectedStatus = fromStatus;
      isStatusEnabled = finalStatusEnabled;
    });
  }

  Color getStatusBgColor(int? statusId) {
    switch (statusId) {
      case SiteObservationStatus.Open:
        return const Color(0xFFCF8310); // bg-opened

      case SiteObservationStatus.InProgress:
        return const Color(0xFFCAA122); // bg-inProgress

      case SiteObservationStatus.Closed:
        return const Color(0xFF0F830B); // bg-completed

      case SiteObservationStatus.ReadyToInspect:
        return const Color(0xFF6518AD); // bg-readyToInspect

      case SiteObservationStatus.Reopen:
        return const Color(0xFF2937FF); // bg-reopen

      default:
        return Colors.grey; // bg-default
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = media.size.height * 0.8;
          final width = media.size.width * 0.9;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: height,
              maxWidth: width,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  width: double.infinity,
                  color: getStatusBgColor(toStatus),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.detail.observationCode ?? 'No Code',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Angular jaisa
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedStatus, // int type
                          hint: const Text("-- Status --",
                              style: TextStyle(color: Colors.white)),
                          isExpanded: true,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.white),

                          // Selected text builder (same as tumhara)
                          selectedItemBuilder: (BuildContext context) {
                            print("🎯 selectedItemBuilder called");

                            return observationStatus.map<Widget>((status) {
                              final id =
                                  int.tryParse(status['id'].toString()) ??
                                      0; // safe int
                              final name = SiteObservationStatus.idToName[id] ??
                                  status['name'] ??
                                  'Unknown';
                              print("🎯 SELECTED ITEM -> id=$id name=$name");
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              );
                            }).toList();
                          },

                          decoration: InputDecoration(
                            isDense: false,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Colors.white)),
                          ),

                          items: observationStatus.map((status) {
                            final id =
                                int.tryParse(status['id'].toString()) ?? 0;
                            final name = SiteObservationStatus.idToName[id] ??
                                status['name'] ??
                                'Unknown';
                            print("📦 ITEM -> id=$id name=$name");
                            return DropdownMenuItem<int>(
                              value: id, // int type
                              child: Text(name,
                                  style: const TextStyle(color: Colors.black)),
                            );
                          }).toList(),

                          onChanged: isStatusEnabled
                              ? (newValue) {
                                  print(
                                      "✅ onChanged CALLED, newValue=$newValue");
                                  if (newValue == null) return;

                                  setState(() {
                                    selectedStatus = newValue; // now int
                                    toStatus = newValue;

                                    isUpdateBtnVisible = fromStatus != newValue;
                                    isRootCauseFileUpdateEnable =
                                        fromStatus != newValue;

                                    isReopenRemarksVisible = newValue ==
                                        SiteObservationStatus.Reopen;
                                    isCloseRemarksVisible = newValue ==
                                        SiteObservationStatus.Closed;
                                    inProgessRemarksVisible = newValue ==
                                        SiteObservationStatus.InProgress;
                                    inReadyToInspectRemarksVisible = newValue ==
                                        SiteObservationStatus.ReadyToInspect;

                                    canEditRootCause = newValue ==
                                            SiteObservationStatus
                                                .ReadyToInspect ||
                                        newValue ==
                                            SiteObservationStatus.Closed;

                                    collapsed = false;
                                  });
                                }
                              : null,

                          validator: (value) =>
                              value == null ? 'Please select a status' : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Padding(
                //   padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                //   child: Row(
                //     children: [
                //       Expanded(
                //         child: Text(
                //           widget.detail.observationCode ?? 'No Code',
                //           style: const TextStyle(fontWeight: FontWeight.bold),
                //         ),
                //       ),
                //       const SizedBox(width: 15),
                //       Expanded(
                //         child: DropdownButtonFormField<String>(
                //           value: selectedStatus,
                //           hint: const Text("-- Status --"),
                //           isExpanded: true,
                //           items: observationStatus.map((status) {
                //             final idStr = status['id'].toString();
                //             final id = int.tryParse(idStr);
                //             final name = SiteObservationStatus.idToName[id] ??
                //                 status['name'] ??
                //                 'Unknown';

                //             return DropdownMenuItem<String>(
                //               value: idStr,
                //               child: Text(name),
                //             );
                //           }).toList(),
                //           onChanged: isStatusEnabled
                //               ? (newValue) {
                //                   if (newValue == null) return;

                //                   final int selectedStatusInt =
                //                       int.parse(newValue);

                //                   setState(() {
                //                     // ✅ THIS IS IMPORTANT
                //                     // print('newValue861: $newValue');
                //                     selectedStatus = newValue;

                //                     // fromStatus = toStatus;
                //                     toStatus = selectedStatusInt;

                //                     isUpdateBtnVisible = true;
                //                     collapsed = false;
                //                     // print('fromStatus868: $fromStatus');
                //                     // print('toStatus869: $toStatus');

                //                     if (fromStatus != selectedStatusInt) {
                //                       print("in");
                //                       isUpdateBtnVisible = true;
                //                       isRootCauseFileUpdateEnable = true;
                //                     } else {
                //                       print("out");
                //                       isUpdateBtnVisible = false;
                //                       isRootCauseFileUpdateEnable = false;
                //                     }

                //                     if (selectedStatusInt ==
                //                         SiteObservationStatus.Reopen) {
                //                       isReopenRemarksVisible = true;
                //                       isCloseRemarksVisible = false;
                //                       inProgessRemarksVisible = false;
                //                       inReadyToInspectRemarksVisible = false;
                //                     } else if (selectedStatusInt ==
                //                         SiteObservationStatus.Closed) {
                //                       isReopenRemarksVisible = false;
                //                       isCloseRemarksVisible = true;
                //                       inProgessRemarksVisible = false;
                //                       inReadyToInspectRemarksVisible = false;
                //                     } else if (selectedStatusInt ==
                //                         SiteObservationStatus.InProgress) {
                //                       // print("In Progress Selected");
                //                       inProgessRemarksVisible = true;
                //                       isReopenRemarksVisible = false;
                //                       isCloseRemarksVisible = false;
                //                       inReadyToInspectRemarksVisible = false;
                //                     } else if (selectedStatusInt ==
                //                         SiteObservationStatus.ReadyToInspect) {
                //                       // print("In Progress Selected");
                //                       inProgessRemarksVisible = false;
                //                       isReopenRemarksVisible = false;
                //                       isCloseRemarksVisible = false;
                //                       inReadyToInspectRemarksVisible = true;
                //                     } else {
                //                       isReopenRemarksVisible = false;
                //                       isCloseRemarksVisible = false;
                //                       inProgessRemarksVisible = false;
                //                       inReadyToInspectRemarksVisible = false;
                //                     }

                //                     if (selectedStatusInt ==
                //                             SiteObservationStatus
                //                                 .ReadyToInspect ||
                //                         selectedStatusInt ==
                //                             SiteObservationStatus.Closed) {
                //                       print("ReadyToInspect/Closed IN");
                //                       canEditRootCause = true;
                //                       // isRootCauseFileUpdateEnable = true;
                //                     } else {
                //                       print("ReadyToInspect/Closed etc... OUT");
                //                       canEditRootCause = false;
                //                       // isRootCauseFileUpdateEnable = false;
                //                     }
                //                   });
                //                 }
                //               : null,
                //           validator: (value) {
                //             if (value == null || value.isEmpty) {
                //               return 'Please select a status';
                //             }
                //             return null;
                //           },
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                const SizedBox(height: 16),

                Expanded(
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: Colors.black,
                          tabs: [
                            Tab(text: "Detail"),
                            Tab(text: "Attachment"),
                            Tab(text: "Activity"),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildDetailTab(context), // ⬅️ Updated
                              _buildAttachmentTab(),
                              _buildActivityTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildTextIfNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty || value == 'N/A') {
      return const SizedBox.shrink(); // 👈 NO SPACE AT ALL
    }

    return Text(
      value,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _buildDetailTab(BuildContext context) {
    // final media = MediaQuery.of(context);
    // print("widget.detail.violationTypeName,${widget.detail.violationTypeName}");
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            //   minHeight: media.size.height * 0.4,
            //   maxHeight: media.size.height * 0.8,
            ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTextIfNotEmpty(widget.detail.observationNameWithCategory),
              // const SizedBox(height: 16),

              // ✅ Use this single method repeatedly — smart layout
              _buildResponsiveRow(
                  context,
                  "Observation Date :",
                  _formatDate(widget.detail.trancationDate),
                  "Created Date :",
                  _formatDate(widget.detail.createdDate)),
              _buildResponsiveRow(
                  context,
                  "Observation Type :",
                  widget.detail.observationType ?? 'N/A',
                  "Issue Type :",
                  widget.detail.issueType ?? 'N/A'),
              _buildResponsiveRow(
                  context,
                  "Created By :",
                  widget.detail.observationRaisedBy ?? 'N/A',
                  "Due Date :",
                  _formatDate(widget.detail.dueDate)),
              _buildResponsiveRow(
                  context,
                  "Activity :",
                  widget.detail.activityName ?? 'N/A',
                  "$areaLabel :",
                  widget.detail.sectionName ?? 'N/A'),
              _buildResponsiveRow(
                  context,
                  "$floorLabel :",
                  widget.detail.floorName ?? 'N/A',
                  "$pourLabel :",
                  widget.detail.partName ?? 'N/A'),
              _buildResponsiveRow(
                  context,
                  "$elementLabel :",
                  widget.detail.elementName ?? 'N/A',
                  "Contractor :",
                  widget.detail.contractorName ?? 'N/A'),
              _buildResponsiveRow(
                  context,
                  "Compliance Required :",
                  widget.detail.complianceRequired ? 'Yes' : 'No',
                  "Escalation Required :",
                  widget.detail.escalationRequired ? 'Yes' : 'No'),

              _buildResponsiveRow(
                context,
                "Observed By :",
                widget.detail.observedByName,
                "Violation Type :",
                widget.detail.violationTypeName ?? 'N/A',
              ),

              buildPairRow(
                context,
                label1: "Observation Description :",
                value1: widget.detail.description,
              ),
              buildPairRow(
                context,
                label1: "Action To Be Taken :",
                value1: widget.detail.actionToBeTaken,
              ),
              buildPairRow(
                context,
                label1: "Assigned Users :",
                value1: widget.detail.assignedUsersName,
              ),

              // ⭐ NEW FIELDS — 2-per-row with condition
              buildPairRow(
                context,
                label1: "Root Cause :",
                value1: widget.detail.rootCauseName,
                label2: "Rework Cost :",
                value2: widget.detail.reworkCost,
              ),

              buildPairRow(
                context,
                label1: "Rootcause Description :",
                value1: widget.detail.rootcauseDescription,
              ),

              buildPairRow(
                context,
                label1: "Preventive Action To Be Taken :",
                value1: widget.detail.preventiveActionTaken,
              ),

              buildPairRow(
                context,
                label1: "Corrective Action To Be Taken :",
                value1: widget.detail.corretiveActionToBeTaken,
              ),
              buildPairRow(
                context,
                label1: "Closure Date :",
                value1: _formatDate(widget.detail.lastModifiedDate),
                value1Color: Colors.green,
              ),

              buildPairRow(
                context,
                label1: "Close Remarks :",
                value1: widget.detail.closeRemarks,
                value1Color: Colors.green,
              ),

              // buildPairRow(
              //   context,
              //   label1: "Reopen Remarks :",
              //   value1: widget.detail.reopenRemarks,
              //   value1Color: Colors.red,
              // ),
              Column(
                children: [
                  if (widget.detail.reopenRemarks != null &&
                      widget.detail.reopenRemarks!.trim().isNotEmpty &&
                      widget.detail.statusName.toLowerCase() == 'reopen') ...[
                    buildPairRow(
                      context,
                      label1: "Reopen Remarks:",
                      value1: widget.detail.reopenRemarks,
                      value1Color: Colors.red,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // ✅ Your existing form
              _buildRootCauseForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPairRow(
    BuildContext context, {
    required String label1,
    String? value1,
    Color? value1Color, // 👈 ADD
    String? label2,
    String? value2,
    Color? value2Color, // 👈 ADD
  }) {
    final has1 = value1 != null &&
        value1.trim().isNotEmpty &&
        value1.trim() != '0' &&
        value1.trim() != '0.0';

    final has2 = value2 != null &&
        value2.trim().isNotEmpty &&
        value2.trim() != '0' &&
        value2.trim() != '0.0';

    if (!has1 && !has2) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (has1)
            _buildDetailRow(
              label1,
              value1!,
              valueColor: value1Color,
            ),
          if (has2)
            _buildDetailRow(
              label2!,
              value2!,
              valueColor: value2Color,
            ),
          const SizedBox(height: 8),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (has1)
            Expanded(
              child: _buildDetailRow(
                label1,
                value1!,
                valueColor: value1Color,
              ),
            ),
          if (has1 && has2) const SizedBox(width: 10),
          if (has2)
            Expanded(
              child: _buildDetailRow(
                label2!,
                value2!,
                valueColor: value2Color,
              ),
            ),
        ],
      ),
    );
  }

  // Widget _buildResponsiveRow(
  //   BuildContext context,
  //   String label1,
  //   String value1,
  //   String label2,
  //   String value2,
  // ) {
  //   final screenWidth = MediaQuery.of(context).size.width;
  //   final isMobile = screenWidth < 600;

  //   if (isMobile) {
  //     // MOBILE: 1 item per row (stacked vertically)
  //     return Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _buildDetailRow(label1, value1),
  //         const SizedBox(height: 6), // consistent vertical spacing
  //         _buildDetailRow(label2, value2),
  //         const SizedBox(height: 6),
  //       ],
  //     );
  //   } else {
  //     // TABLET: 2 items in a row (like table)
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 6.0),
  //       child: Row(
  //         children: [
  //           Expanded(child: _buildDetailRow(label1, value1)),
  //           const SizedBox(width: 12),
  //           Expanded(child: _buildDetailRow(label2, value2)),
  //         ],
  //       ),
  //     );
  //   }
  // }
  Widget _buildResponsiveRow(
    BuildContext context,
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // MOBILE: stacked vertically with uniform spacing
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(label1, value1),
          const SizedBox(height: 6), // consistent vertical spacing
          _buildDetailRow(label2, value2),
          const SizedBox(height: 6), // consistent vertical spacing
        ],
      );
    } else {
      // TABLET/DESKTOP: horizontal row with consistent spacing
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Expanded(child: _buildDetailRow(label1, value1)),
            const SizedBox(width: 12), // consistent horizontal spacing
            Expanded(child: _buildDetailRow(label2, value2)),
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Text(
                value,
                style: TextStyle(
                  color: valueColor ?? (isDark ? Colors.white : Colors.black),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    return date != null
        ? DateFormat('dd/MM/yyyy hh:mm').format(date.toLocal())
        : 'N/A';
  }

  Widget _buildTripleRow(BuildContext context, Widget a, Widget b, Widget c) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Column(
        children: [
          a,
          const SizedBox(height: 10),
          b,
          const SizedBox(height: 10),
          c,
          const SizedBox(height: 10),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
          const SizedBox(width: 12),
          Expanded(child: c),
        ],
      );
    }
  }

  Widget _buildRootCauseForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= ROOT CAUSE SECTION (UNCHANGED) =================
            if (isRootCauseFileUpdateEnable &&
                canEditRootCause &&
                !collapsed) ...[
              DropdownButtonFormField<int>(
                value: selectedRootCauseId,
                decoration: const InputDecoration(
                  labelText: 'Select Root Cause',
                  border: OutlineInputBorder(),
                ),
                items: rootCauses.map((cause) {
                  return DropdownMenuItem<int>(
                    value: int.tryParse(cause.id.toString()), // ensure int
                    child: Text(cause.rootCauseName),
                  );
                }).toList(),
                onChanged: (newId) {
                  setState(() {
                    selectedRootCauseId = newId;
                  });
                },
                validator: (value) =>
                    value == null ? 'Root Cause is required' : null,
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: rootcauseDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Root Cause Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),
              _buildTripleRow(
                context,
                TextFormField(
                  controller: materialCostController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Material Cost",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Material cost required" : null,
                ),
                TextFormField(
                  controller: labourCostController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Labour Cost",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Labour cost required" : null,
                ),
                TextFormField(
                  controller: reworkCostController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Total Rework Cost",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: preventiveActionController,
                decoration: const InputDecoration(
                  labelText: 'Preventive Action To Be Taken',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: correctiveActionController,
                decoration: const InputDecoration(
                  labelText: 'Corrective Action To Be Taken',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),

              // ================= FILE UPLOAD (UNCHANGED) =================
              if (isRootCauseFileUpdateEnable) ...[
                const SizedBox(height: 16),
                const Text("Upload File",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                // ElevatedButton(
                //   onPressed: () async {
                //     FilePickerResult? result =
                //         await FilePicker.platform.pickFiles(
                //       allowMultiple: true,
                //       withData: true,
                //     );

                //     if (result != null && result.files.isNotEmpty) {
                //       final file = result.files.first;

                //       setState(() {
                //         selectedFileName = file.name;
                //       });

                //       final uploadedFileName = await SiteObservationService()
                //           .uploadFileAndGetFileName(file.name, file.bytes!);

                //       if (uploadedFileName != null) {
                //         setState(() {
                //           uploadedFiles.add(uploadedFileName);
                //         });
                //       }
                //       else {
                //         ScaffoldMessenger.of(context).showSnackBar(
                //           const SnackBar(content: Text("File upload failed")),
                //         );
                //       }
                //     } else {
                //       print("No file selected");
                //     }
                //   },
                //   child: const Text("Choose File"),
                // ),
                ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                      withData: true,
                    );

                    // 1️⃣ No file selected
                    if (result == null || result.files.isEmpty) {
                      print("No file selected");
                      return;
                    }

                    // 2️⃣ Loop through selected files
                    for (var file in result.files) {
                      // Safety check
                      if (file.bytes == null) continue;

                      setState(() {
                        selectedFileName = file.name;
                      });

                      final uploadedFileName = await SiteObservationService()
                          .uploadFileAndGetFileName(
                        file.name,
                        file.bytes!,
                      );

                      if (uploadedFileName != null) {
                        setState(() {
                          uploadedFiles.add(uploadedFileName);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to upload ${file.name}"),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Choose File"),
                ),

                // if (selectedFileName != null) ...[
                //   const SizedBox(height: 8),
                //   Text(
                //     "Selected file: $selectedFileName",
                //     style: const TextStyle(fontWeight: FontWeight.w600),
                //   ),
                // ],

                if (uploadedFiles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Uploaded Files",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (var file in uploadedFiles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file,
                              color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              file,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                uploadedFiles.remove(file);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 16),
              ],
            ],

            // ================= 🔥 REMARKS (FIXED – ROOT CAUSE SEPARATE) =================

            if (isReopenRemarksVisible) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: reopenRemarksController,
                decoration: const InputDecoration(
                  labelText: 'Reopen Remarks',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Reopen Remarks required' : null,
              ),
            ],

            if (isCloseRemarksVisible) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: closeRemarksController,
                decoration: const InputDecoration(
                  labelText: 'Close Remarks',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Close Remarks required' : null,
              ),
            ],
            if (inProgessRemarksVisible) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: inProgessRemarksController,
                decoration: const InputDecoration(
                  labelText: 'In Progress Remarks',
                  border: OutlineInputBorder(),
                ),
                // validator: (v) =>
                //     v == null || v.isEmpty ? 'In Progress required' : null,
              ),
            ],

            if (inReadyToInspectRemarksVisible) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: inReadyToInspectRemarksController,
                decoration: const InputDecoration(
                  labelText: 'In Ready To Inspect',
                  border: OutlineInputBorder(),
                ),
                // validator: (v) => v == null || v.isEmpty
                //     ? 'In Ready To Inspect required'
                //     : null,
              ),
            ],
            const SizedBox(height: 16),
            // ================= UPDATE BUTTON (UNCHANGED) =================
            if (isRootCauseFileUpdateEnable && isUpdateBtnVisible)
              Center(
                child: SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.update, // 👈 update icon
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: isButtonDisabled
                        ? null
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              setState(() {
                                isButtonDisabled = true;
                                isEditingRootCause = false;
                              });
                              // return;
                              UpdateSiteObservation updatedData =
                                  await getUpdatedDataFromForm(uploadedFiles);
                              // return;
                              bool success = await SiteObservationService()
                                  .updateSiteObservationByID(updatedData);

                              if (success) {
                                for (var fileName in uploadedFiles) {
                                  widget.detail.activityDTO.add(
                                    ActivityDTO(
                                      id: 0,
                                      siteObservationID: widget.detail.id,
                                      actionID:
                                          SiteObservationActions.DocUploaded,
                                      actionName: "DocUploaded",
                                      comments: '',
                                      documentName: fileName,
                                      fromStatusID: fromStatus,
                                      toStatusID: toStatus,
                                      assignedUserID: 0,
                                      assignedUserName: null,
                                      createdBy: userId,
                                      createdDate: DateTime.now().toUtc(),
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
                                Navigator.of(context)
                                    .pop(true); // ✅ dialog result
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Update failed! Please try again.')),
                                );
                                setState(() {
                                  isButtonDisabled = false;
                                });
                              }
                            }
                          },

                    // 🎨 MODERN STYLE
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
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

  Future<bool> requestMediaPermission() async {
    // 🔥 Android + iOS sab ke liye
    return true;
  }

  Future<void> refreshGallery(String path) async {
    try {
      await _galleryChannel.invokeMethod('scanFile', {'path': path});
    } catch (e) {
      debugPrint("Gallery refresh error: $e");
    }
  }

  Future<void> _saveImageToGallery(String tempPath, String fileName) async {
    await _galleryChannel.invokeMethod('saveToGallery', {
      'path': tempPath,
      'fileName': fileName,
    });
  }

  Future<void> downloadImage(String fileName) async {
    try {
      final dio = Dio();

      // 1️⃣ Download to TEMP directory (allowed)
      final tempDir = await getTemporaryDirectory();
      final tempPath = "${tempDir.path}/$fileName";

      await dio.download("$url/$fileName", tempPath);

      // 2️⃣ Save to Gallery using MediaStore
      await _saveImageToGallery(tempPath, fileName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image downloaded & saved to Gallery"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Download error: $e");
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
            /// 🔴 CLOSED MESSAGE ONLY
            if (attachmentRestrictionMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  attachmentRestrictionMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

            /// Upload Image Button
            if (!isObservationClosed && canUploadAttachments)
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
                    // final int effectiveStatus = widget.detail.statusID ?? 0;
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
                            createdByName: currentUserName,
                            createdDate: DateTime.now().toUtc(),
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
                            Text(
                              "Uploaded By: ${activity.createdByName}",
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54),
                            ),
                            Text(
                              "Status: ${getAttachmentStatusName(activity)}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.blueGrey,
                              ),
                            ),
                            SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                openImageModal(
                                    activity.documentName); // preview
                              },
                              child: Stack(
                                children: [
                                  Container(
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
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image,
                                                size: 50),
                                      ),
                                    ),
                                  ),

                                  /// 🔽 Download Icon Overlay
                                  Positioned(
                                    right: 6,
                                    bottom: 6,
                                    child: InkWell(
                                      onTap: () {
                                        downloadImage(activity.documentName);
                                      },
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.black54,
                                        child: const Icon(
                                          Icons.download,
                                          size: 16,
                                          color: Colors.white,
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
    if (activities.isEmpty) {
      return const Center(child: Text("No activity recorded."));
    }

    // 🔹 Group activities by user + 5-sec window (original logic)
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

    // 🔹 Sort groups Ascending (latest group first)
    final sortedGroupEntries = groupedActivities.entries.toList()
      ..sort((a, b) {
        final int aFirstId = a.value.first.id ?? 0; // 👈 fallback
        final int bFirstId = b.value.first.id ?? 0;

        return bFirstId.compareTo(aFirstId); // DESC
      });

    return StatefulBuilder(builder: (context, setState) {
      return Portal(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: sortedGroupEntries.map((entry) {
                    int _actionPriority(String action) {
                      switch (action) {
                        case 'Created':
                          return 1;
                        case 'DocUploaded':
                          return 2;
                        case 'Assigned':
                          return 3;
                        case 'Commented':
                          return 4;
                        case 'In Progress':
                          return 5;
                        case 'Closed':
                          return 6;
                        default:
                          return 99;
                      }
                    }

                    final acts = [...entry.value]..sort((a, b) {
                        final p1 = _actionPriority(a.actionName ?? '');
                        final p2 = _actionPriority(b.actionName ?? '');

                        if (p1 != p2) {
                          return p1.compareTo(p2); // action order
                        }
                        return a.createdDate.compareTo(
                            b.createdDate); // time inside same action
                      });

                    if (acts.isEmpty) return const SizedBox.shrink();

                    final first = acts.first;
                    final statusName = first.toStatusName ?? "Unknown";

                    String userName = first.createdByName ?? "Unknown";
                    final dateTime = first.createdDate.toLocal();
                    final date =
                        DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
                    String nameToShow =
                        (userName.trim().isNotEmpty ? userName.trim()[0] : '?')
                            .toUpperCase();

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
                            // 🔹 Status at top of card
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
                                                  activity.assignedUserName ??
                                                      activity.createdByName,
                                                ),
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
                                                          child: isImage(activity
                                                                  .documentName)
                                                              ? GestureDetector(
                                                                  onTap: () {
                                                                    openImageModal(
                                                                        activity
                                                                            .documentName);
                                                                  },
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    child: Image
                                                                        .network(
                                                                      "$url/${activity.documentName}",
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      errorBuilder: (context,
                                                                              error,
                                                                              stackTrace) =>
                                                                          const Icon(
                                                                              Icons.broken_image,
                                                                              size: 50),
                                                                    ),
                                                                  ),
                                                                )
                                                              : ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                  child: Image
                                                                      .asset(
                                                                    "assets/default-image.png",
                                                                    fit: BoxFit
                                                                        .cover,
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
            // --------------------------- Your Dropdown + Mentions UI ---------------------------
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isObservationClosed && actionEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedActionType,
                          onChanged: actionEnabled
                              ? (String? newValue) async {
                                  if (newValue == null) return;
                                  setState(() {
                                    selectedActionType = newValue;
                                    _activityCommentController.clear();
                                    mentionsKey.currentState?.controller
                                        ?.clear();
                                    selectedMentions.clear();
                                    isMentionsEnabled = false;
                                  });
                                  await fetchUsers();
                                }
                              : null,
                          items: ['Comment', 'Assign'].map((action) {
                            return DropdownMenuItem(
                                value: action, child: Text(action));
                          }).toList(),
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),
                  // ---------------------------
                  // FlutterMentions
                  // ---------------------------
                  if (!isObservationClosed && textEnabled)
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 270),
                        child: FlutterMentions(
                          key: mentionsKey,
                          maxLines: 3,
                          minLines: 1,
                          suggestionPosition: SuggestionPosition.Top,
                          suggestionListHeight: 270,
                          decoration: InputDecoration(
                            hintText: selectedActionType == 'Assign'
                                ? "Enter '@' to assign users..."
                                : "Enter '@' to mention assigned users...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          mentions: [
                            Mention(
                              trigger: '@',
                              data: isMentionsEnabled ? userList : [], // ✅ SAFE
                              style: const TextStyle(color: Colors.blue),
                              suggestionBuilder: (data) {
                                final display = data['display'] ?? '';
                                if (display.isEmpty)
                                  return const SizedBox.shrink();
                                return ListTile(title: Text(display));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),
                  if (!isObservationClosed && commentDisabled)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: isSending ? null : _sendActivityComment,
                      ),
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
      case "In Progress":
        badgeColor = const Color.fromARGB(255, 207, 179, 84);
        break;
      case "Closed":
        badgeColor = const Color.fromARGB(255, 3, 172, 59);
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

// New Code
