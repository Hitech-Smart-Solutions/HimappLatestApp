import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/model/page_permission.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/model/company_model.dart';
import 'package:himappnew/model/project_model.dart';
import 'package:himappnew/service/company_service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:collection/collection.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:dio/dio.dart';
// import 'dart:io';

import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'package:intl/intl.dart';
// import 'package:media_scanner/media_scanner.dart';
// import 'package:device_info_plus/device_info_plus.dart';

class SiteObservationQuality extends StatefulWidget {
  final String companyName;
  final ProjectService _projectService;
  final SiteObservationService _siteObservationService;

  final PagePermission pagePermission;

  const SiteObservationQuality({
    super.key,
    required this.companyName,
    required ProjectService projectService,
    required SiteObservationService siteObservationService,
    required this.pagePermission, // 🔥
  })  : _projectService = projectService,
        _siteObservationService = siteObservationService;

  @override
  _SiteObservationState createState() => _SiteObservationState();
}

class _SiteObservationState extends State<SiteObservationQuality> {
  // List<String> items = []; // Project names list
  Project? selectedProject;
  List<Project> projectList = [];

  String? selectedCompany;
  List<Company> companies = []; // Company names list

  List<SiteObservation> observations = []; // Dummy data
  String? selectedItem;

  bool isLoading = true; // Loading indicator
  bool showObservations = true; // Toggle observations
  TextEditingController _dateController = TextEditingController();
  String? selectedIssueType;
  List<IssueType> issueTypes = [];

  int? selectedActivityId;
  List<Activities> activitieList = [];
  // List<Activities> activities = [];
  int? companyId;

  String? selectedObservation;
  List<Observation> observationsList = [];

  String? selectedObservationType;
  List<ObservationType> observationTypeList = [];

  int? selectedAreaId;
  List<Area> areaList = [];

  int? selectedPartId;
  List<Part> partList = [];

  int? selectedFloorId;
  List<Floor> floorList = [];

  int? selectedElementId;
  List<Elements> elementList = [];

  // String? selectedContractor;
  int? selectedContractorId;
  Party? selectedContractor;
  List<Party> ContractorList = [];

  // String? selectedUser;
  List<String> selectedUsers = [];
  List<UserList> userList = [];
  List<UserList> selectedMultiUsers = []; // Selected users (multi-select)
  List<UserList> selectedUserObjects = [];
  List<MultiSelectItem<UserList>> userItems = [];
  List<AssignmentStatusDTO> assignmentList = [];

  bool isComplianceRequired = false; // Compliance toggle state
  bool isEscalationRequired = false; // Escalation toggle state

  List<SiteObservationActivity> activityList = [];

  TextEditingController observationDescriptionController =
      TextEditingController();
  // TextEditingController userDescriptionController = TextEditingController();
  TextEditingController actionToBeTakenController = TextEditingController();
  TextEditingController reworkCostController = TextEditingController();
  TextEditingController observedByController = TextEditingController();
  final TextEditingController _dateDueDateController = TextEditingController();

  final CompanyService _companyService = CompanyService(); // Company service
  final _formKey = GlobalKey<FormState>();
  bool isFormReady = false;
  bool isUploading = false;
  String? selectedFileName;
  List<String> uploadedFiles = [];
  int? selectedObservationTypeId;
  int? selectedIssueTypeId;

  bool _isSubmitting = false;

  static final MethodChannel _galleryChannel = MethodChannel('gallery_scanner');

  final uiDateFormat = 'dd/MM/yyyy HH:mm';
  int? creatorId;

  bool get isToggleEnabled {
    // NCR + IssueTypeId = 1 → always disabled
    if (selectedIssueTypeId == 1 && selectedIssueType == 'NCR') {
      return false;
    }

    // No observation selected yet → allow toggle
    if (selectedObservationTemplateId == null) {
      return true;
    }

    // Find observation by ID (IMPORTANT)
    final selectedObs = observationsList.firstWhereOrNull(
      (obs) => obs.id == selectedObservationTemplateId,
    );

    if (selectedObs == null) return true;

    // Disable toggle only for Good Practice
    return selectedObs.observationTypeID != goodPracticeObservationTypeId;
  }

  int get goodPracticeObservationTypeId {
    final goodPracticeType = observationTypeList.firstWhereOrNull(
      (e) => e.name.toLowerCase().contains('good practice'),
    );
    return goodPracticeType?.id ?? -1;
  }

  bool get isDueDateEnabled {
    if (!isComplianceRequired) {
      return false;
    }

    if (selectedIssueTypeId == 1 && selectedIssueType == 'NCR') {
      return selectedObservationTemplateId != null;
    }

    if (selectedObservationTemplateId == null) {
      return true;
    }

    final selectedObs = observationsList.firstWhereOrNull(
      (obs) => obs.id == selectedObservationTemplateId,
    );

    if (selectedObs == null) return true;

    return selectedObs.observationTypeID != goodPracticeObservationTypeId;
  }

  int? observedById;

  bool isUserSelectionEnabled = true;
  bool actionToBeTakenEnabled = true;
  bool isDraft = true;
  bool isLoadingObservationForm = true;
  String? areaLabel;
  late Future<List<NCRObservation>> futureObservations;
  int selectedObservationId = 0;
  bool isEditMode = false;
  // bool isDueDateEnabled = true;
  // bool isToggleEnabled = true;
  SiteObservation? selectedObservationForView;
  GetSiteObservationMasterById? _currentObservation;
  List<ActivityDTO> activityDTOList = [];
  bool isDraftObservation = false;

  int? siteObservationId; // 🔥 DB record ID (SAVE vs UPDATE)
  int? selectedObservationTemplateId; // 🔥 dropdown (searchable) ID
  String? selectedObservationText; // 🔥 UI only

  String url = AppSettings.url;

  // List<ActivityDTO> activities = detail.activityDTO;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // userItems = userList
    //     .map((user) => MultiSelectItem<User>(user, user.userName))
    //     .toList();
    debugPrint("🔐 canAdd = ${widget.pagePermission.canAdd}");
    debugPrint("🔐 canEdit = ${widget.pagePermission.canEdit}");
    debugPrint("🔐 canView = ${widget.pagePermission.canView}");
  }

  Future<void> _initializeData() async {
    await fetchCompanies();
    await fetchProjects();
    if (selectedProject != null) {
      await fetchSiteObservationsQuality(selectedProject!.id);
      await fetchAreaList(selectedProject!.id);
      await fetchFloorList(selectedProject!.id);
      await fetchPartList(selectedProject!.id);
      await fetchElementList(selectedProject!.id);
    }

    // Then load all static or unrelated data
    fetchObservationType();
    fetchIssueTypes();
    fetchActivities();
    fetchObservations();
    fetchContractorList();
    fetchUserList();

    final fetchedUsers = await fetchUserList();
    setState(() {
      userList = fetchedUsers;
      userItems = userList
          .map((user) => MultiSelectItem<UserList>(user, user.userName))
          .toList();
    });
    if (!isEditMode) {
      _dateController.text =
          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    }

    // futureObservations = widget._siteObservationService
    // _loadObservationFromServer(widget.de);
  }

  String formatDateForApi(DateTime date) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(date);
  }

  String? formatDateForApiNullable(String? dateText) {
    if (dateText == null || dateText.trim().isEmpty) {
      return null; // ✅ draft safe
    }

    final date = DateFormat(uiDateFormat).parse(dateText);
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(date);
  }

  String getAttachmentStatusName(
      ActivityDTO activity, GetSiteObservationMasterById detail) {
    final relatedActivities = detail.activityDTO
        .where((a) => a.documentName == activity.documentName)
        .toList();

    if (relatedActivities.isEmpty) return 'Unknown';

    // Latest activity (createdDate ke basis pe)
    relatedActivities.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    final latestActivity = relatedActivities.first;

    return latestActivity.toStatusName ?? 'Unknown';
  }

  // Fetch issue types from the service
  Future<void> fetchIssueTypes() async {
    setState(() => isLoading = true);
    try {
      List<IssueType> fetchedIssueTypes = await widget._siteObservationService
          .fetchIssueTypes(selectedObservationTypeId ?? 0);
      setState(() {
        issueTypes = fetchedIssueTypes;
        fetchedIssueTypes
            .forEach((e) => print('IssueType: ${e.id} - ${e.name}'));
      });
    } catch (e) {
      print('Error fetching issue types: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Fetch Activities from the service
  Future<void> fetchActivities() async {
    int? companyId = await SharedPrefsHelper.getCompanyId();
    if (companyId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<Activities> fetchedActivities = await widget._siteObservationService
          .fetchActivities(companyId, ScreenTypes.Quality);

      setState(() {
        activitieList = fetchedActivities;
        selectedActivityId = null;
      });
    } catch (e) {
      debugPrint('Error fetching activities: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch observations from the service
  Future<void> fetchObservations() async {
    int? companyId = await SharedPrefsHelper.getCompanyId();
    if (companyId == null) {
      return; // Exit the method if companyId is null
    }
    setState(() {
      isLoading = true;
    });
    try {
      List<Observation> fetchedObservations =
          await widget._siteObservationService.fetchObservations(
        companyId,
        ScreenTypes.Quality,
        selectedIssueTypeId ?? 0,
      );

      setState(() {
        observationsList = fetchedObservations;

        // 🛑 Do NOT auto-select first observation
        selectedObservation = null;
        selectedObservationTemplateId = null;

        // print("Fetched Observations count: ${fetchedObservations.length}");
        // fetchedObservations.forEach(
        //     (obs) => print("Observation: ${obs.observationDisplayText}"));
      });
    } catch (e) {
      print('Error fetching Observation: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<void> fetchObservations() async {
  //   int? companyId = await SharedPrefsHelper.getCompanyId();
  //   if (companyId == null) return;

  //   setState(() => isLoading = true);

  //   try {
  //     List<Observation> fetchedObservations =
  //         await widget._siteObservationService.fetchObservations(
  //       companyId,
  //       ScreenTypes.Quality,
  //       selectedIssueTypeId ?? 0,
  //     );

  //     setState(() {
  //       observationsList = fetchedObservations;

  //       // ✅ First-time selection set karo
  //       if (observationsList.isNotEmpty) {
  //         selectedObservationTemplateId = observationsList[0].id;
  //         selectedObservation = observationsList[0].observationDescription;
  //         selectedObservationText = observationsList[0].observationDisplayText;
  //         isComplianceRequired = observationsList[0].complianceRequired;
  //         isEscalationRequired = observationsList[0].escalationRequired;
  //         actionToBeTakenController.text =
  //             observationsList[0].actionToBeTaken ?? '';
  //       } else {
  //         selectedObservationTemplateId = null;
  //         selectedObservation = null;
  //       }
  //     });
  //   } catch (e) {
  //     print('Error fetching Observations: $e');
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }

// Fetch ObservationsType from the service
  Future<void> fetchObservationType() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<ObservationType> fetchedObservationType =
          await widget._siteObservationService.fetchObservationType();
      setState(() {
        observationTypeList = fetchedObservationType;
        observationTypeList.forEach(
            (e) => print('observationTypeList268: ${e.id} - ${e.name}'));
      });
    } catch (e) {
      print('Error fetching ObservationType: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch Area from the service
  Future<void> fetchAreaList(int projectId) async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Area> fetchedArea =
          await widget._siteObservationService.fetchAreaList(projectId);
      setState(() {
        areaList = fetchedArea;
        selectedAreaId = null; // ✅ default blank
      });
    } catch (e) {
      print('Error fetching Area: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch Floor from the service
  Future<void> fetchFloorList(int projectId) async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Floor> fetchedFloor =
          await widget._siteObservationService.fetchFloorList(projectId);
      setState(() {
        floorList = fetchedFloor;
        selectedFloorId = null; // ✅ blank by default
      });
    } catch (e) {
      print('Error fetching Floor: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch Floor from the service
  Future<void> fetchPartList(int projectId) async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Part> fetchedPart =
          await widget._siteObservationService.fetchPartList(projectId);

      final seen = <String>{};
      partList = fetchedPart.where((part) {
        final name = part.partName.trim().toLowerCase();
        return seen.add(name);
      }).toList();

      selectedPartId = null; // ✅ nothing pre-selected
    } catch (e) {
      print('Error fetching Part: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch Element from the service
  Future<void> fetchElementList(int projectId) async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Elements> fetchedElement =
          await widget._siteObservationService.fetchElementList(projectId);

      final seen = <String>{};
      final uniqueElements = fetchedElement.where((element) {
        final name = element.elementName.trim().toLowerCase();
        return seen.add(name);
      }).toList();

      setState(() {
        elementList = uniqueElements;
        selectedElementId = null; // ✅ no auto select
      });
    } catch (e) {
      print('Error fetching Element: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch Contractor from the service
  Future<void> fetchContractorList() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedContractor =
          await widget._siteObservationService.fetchContractorList();

      // ✅ A–Z sort by partyName
      fetchedContractor.sort(
        (a, b) =>
            a.partyName.toLowerCase().compareTo(b.partyName.toLowerCase()),
      );

      Party? matchedContractor;

      if (selectedContractorId != null) {
        for (final c in fetchedContractor) {
          if (c.id == selectedContractorId) {
            matchedContractor = c;
            break;
          }
        }
      }

      setState(() {
        ContractorList = fetchedContractor;
        selectedContractor = matchedContractor; // ✅ safe
      });
    } catch (e) {
      debugPrint('❌ Error fetching Contractor: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<List<User>> fetchUserList() async {
  //   try {
  //     int? currentUserId = await SharedPrefsHelper.getUserId();

  //     List<User> fetchedUsers =
  //         await widget._siteObservationService.fetchUserList();

  //     List<User> uniqueUsers = [];
  //     Set<String> userNames = {};

  //     for (var user in fetchedUsers) {
  //       if (!userNames.contains(user.userName) && user.id != currentUserId) {
  //         uniqueUsers.add(user);
  //         userNames.add(user.userName);
  //       }
  //     }

  //     return uniqueUsers; // ✅ return the list instead of setting state
  //   } catch (e) {
  //     return [];
  //   }
  // }

  // New code
  Future<List<UserList>> fetchUserList() async {
    try {
      final int? currentUserId = await SharedPrefsHelper.getUserId();
      final int? localCreatorId = creatorId;

      final fetchedUsers =
          await widget._siteObservationService.getUsersForSiteObservation(
        siteObservationId: siteObservationId ?? 0,
        flag: 2, // assign = 2, comment = 1
      );

      debugPrint('🟢 API USERS COUNT => ${fetchedUsers.length}');
      debugPrint('👤 currentUserId => $currentUserId');
      debugPrint('👑 creatorId => $localCreatorId');

      final List<UserList> filteredUsers = [];

      for (final user in fetchedUsers) {
        // remove logged-in user
        if (user.id == currentUserId) continue;

        // remove creator (Angular logic match)
        if (localCreatorId != null &&
            currentUserId != localCreatorId &&
            user.id == localCreatorId) continue;

        filteredUsers.add(user);
      }

      debugPrint('🟡 FINAL USERS COUNT => ${filteredUsers.length}');
      return filteredUsers;
    } catch (e) {
      debugPrint('❌ fetchUserList ERROR => $e');
      return [];
    }
  }

  void _submitForm({bool isDraft = false}) async {
    bool isFormValid = _formKey.currentState?.validate() ?? false;

    // ✅ Only validate user if dropdown is enabled
    bool isUserValidationRequired = isEditMode && isUserSelectionEnabled;
    bool isUserSelected = selectedUserObjects.isNotEmpty;

    if (isFormValid && (!isUserValidationRequired || isUserSelected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            duration: Duration(seconds: 2),
            content: Text(isDraft ? 'Saving as Draft...' : 'Submitting...')),
      );

      await submitForm(isDraft: isDraft);
    } else {
      String errorMessage = '';

      if (!isFormValid) {
        errorMessage = 'Please fill all required fields correctly.';
      } else if (isUserValidationRequired && !isUserSelected) {
        errorMessage = 'Please select at least one user.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  // Fetch company list
  Future<void> fetchCompanies() async {
    int? userId = await SharedPrefsHelper.getUserId();
    try {
      final companyList = await _companyService.fetchCompanies(userId!);
      setState(() {
        companies = companyList;
        selectedCompany = companies.isNotEmpty ? companies[0].name : null;
      });
      if (selectedCompany != null) {
        fetchProjects();
      }
    } catch (e) {
      print("Error fetching companies: $e");
    }
  }

  Future<void> fetchProjects() async {
    try {
      int? userId = await SharedPrefsHelper.getUserId();
      int? companyId = await SharedPrefsHelper.getCompanyId();
      if (userId == null || companyId == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      List<Project> projects = await widget._projectService.fetchProject(
        userId,
        companyId,
      );
      setState(() {
        projectList = projects; // ✅ Keep full Project objects
        selectedProject = projects.isNotEmpty ? projects[0] : null;
        isLoading = false;
      });
      if (projects.isNotEmpty) {
        await SharedPrefsHelper.saveProjectID(projects[0].id);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching projects: $e");
    }
  }

// Fetch Observations
  Future<void> fetchSiteObservationsQuality(int projectId) async {
    setState(() => isLoading = true);
    try {
      final fetched =
          await widget._siteObservationService.fetchSiteObservationsQuality(
        projectId: projectId,
        sortColumn: 'ID desc',
        pageSize: 10,
        pageIndex: 0,
        isActive: true,
      );
      if (fetched.isEmpty) {
        // Table1 is empty, so no observations
        setState(() => observations = []);
      } else {
        setState(() => observations = fetched);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching labours: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

// Form validation logic
  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Start Date is required';
    }
    return null;
  }

  String? _validateIssueType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Issue Type is required';
    }
    return null;
  }

  String? _validateActivity(int? value) {
    if (value == null) {
      return 'Activity is required';
    }
    return null;
  }

  String? _validateObservation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Observation is required';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Observation Description is required';
    }
    return null;
  }

  String? _validateObservedBy(String? value) {
    if (value == null || value.isEmpty) {
      return 'Observed By is required';
    }
    return null;
  }

  // String? _validateUser(String? value) {
  //   if (value == null || value.isEmpty) {
  //     return 'User Description is required';
  //   }
  //   return null;
  // }

  String? _validateDueDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Due Date is required';
    }
    return null;
  }

  String? _validateObservationType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Observation Type is required';
    }
    return null;
  }

  String? _validateArea(String? value) {
    if (value == null || value.isEmpty) {
      return 'Area is required';
    }
    return null;
  }

  String? _validateFloor(String? value) {
    if (value == null || value.isEmpty) {
      return 'Floor is required';
    }
    return null;
  }

  String? _validatePart(String? value) {
    if (value == null || value.isEmpty) {
      return 'Part is required';
    }
    return null;
  }

  String? _validateElement(String? value) {
    if (value == null || value.isEmpty) {
      return 'Element is required';
    }
    return null;
  }

  String? _validateContractor(int? value) {
    if (value == null) {
      return 'Please select a contractor';
    }
    return null;
  }

  String? _validateAssigned(String? value) {
    if (value == null || value.isEmpty) {
      return 'Assigned To is required';
    }
    return null;
  }

  // Future<bool> requestMediaPermission() async {
  //   if (!Platform.isAndroid) return true;

  //   // Android 13+ and even below: safe to proceed
  //   final status = await Permission.storage.status;

  //   if (status.isGranted || status.isLimited) {
  //     return true;
  //   }

  //   final result = await Permission.storage.request();
  //   return result.isGranted;
  // }
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

  // Function to show the date picker
  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller, {
    required bool allowFuture,
  }) async {
    final DateTime now = DateTime.now();
    DateTime initialDate = now;
    // ✅ If already selected → use it
    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy HH:mm').parse(controller.text);
      } catch (_) {
        initialDate = now;
      }
    }

    // RULES:
    // allowFuture = false  → Start Date
    // allowFuture = true   → Due Date

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: allowFuture
          ? now
          : DateTime(2000), // Start Date = allow past, Due Date = block past
      lastDate: allowFuture
          ? DateTime(2101)
          : now, // Start Date = block future, Due Date = allow future
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          controller.text = DateFormat(uiDateFormat).format(finalDateTime);
          // _recalculateDueDate();

          // // 🔴 DEBUG ONLY WHEN DUE DATE CHANGES
          // if (controller == _dateDueDateController) {
          //   debugPrint('========== DUE DATE CHANGED ==========');
          //   debugPrint('DUE RAW: ${controller.text}');
          //   debugPrint('START RAW: ${_dateController.text}');

          //   try {
          //     final start =
          //         DateFormat(uiDateFormat).parse(_dateController.text);
          //     final due = DateFormat(uiDateFormat).parse(controller.text);

          //     debugPrint('START PARSED: $start');
          //     debugPrint('DUE PARSED: $due');
          //     debugPrint('isDueBeforeStart: ${due.isBefore(start)}');
          //   } catch (e) {
          //     debugPrint('❌ DATE PARSE ERROR: $e');
          //   }

          //   debugPrint('=====================================');
          // }
        });
      }
    }
  }

  Future<void> loadSection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? projectID = prefs.getInt('projectID');

    if (projectID != null) {
      try {
        // List<SectionModel> sections = await getSectionsByProjectID(projectID);
        List<SectionModel> sections = await widget._siteObservationService
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

  void onFileUploadSuccess(
    String uploadedFileName, {
    required bool isDraft,
    String? fileName,
    String? fileContentType,
    String? filePath,
  }) async {
    if (uploadedFileName.trim().isEmpty) return;

    int? userID = await SharedPrefsHelper.getUserId();
    if (userID == null || userID == 0) return;

    int statusIdToSend = isDraft
        ? SiteObservationStatus.Draft
        : (selectedObservationTypeId == 1
            ? SiteObservationStatus.Closed
            : SiteObservationStatus.Open);

    final observationIdToSend = siteObservationId;

    final fileAlreadyExists =
        activityList.any((a) => a.documentName == uploadedFileName) ||
            activityDTOList.any((dto) => dto.documentName == uploadedFileName);

    if (fileAlreadyExists) {
      return;
    }
    // 🔵 Add to UI list
    final newActivity = SiteObservationActivity(
      id: 0,
      siteObservationID: observationIdToSend == 0 ? null : observationIdToSend,
      actionID: SiteObservationActions.DocUploaded,
      comments: '',
      documentName: uploadedFileName,
      fileName: fileName,
      fileContentType: fileContentType,
      filePath: filePath,
      fromStatusID: statusIdToSend,
      toStatusID: statusIdToSend,
      assignedUserID: userID,
      createdBy: userID,
      createdDate: formatDateForApi(DateTime.now()),
    );

    // 🔵 Add to DTO list (important!)
    final dtoActivity = ActivityDTO(
      id: 0,
      siteObservationID: observationIdToSend,
      actionID: SiteObservationActions.DocUploaded,
      actionName: "Document Uploaded",
      comments: '',
      documentName: uploadedFileName,
      fileName: fileName,
      fileContentType: fileContentType,
      filePath: filePath,
      fromStatusID: statusIdToSend,
      toStatusID: statusIdToSend,
      assignedUserID: userID ?? 0,
      assignedUserName: null,
      createdBy: userID,
      createdByName: userID.toString(),
      createdDate: DateTime.now(),
    );

    setState(() {
      activityList.add(newActivity); // For UI
      activityDTOList.add(dtoActivity); // For API
      uploadedFiles.add(uploadedFileName);
      selectedFileName = uploadedFileName;
    });
  }

  Future<void> submitForm({bool isDraft = false}) async {
    // 🔒 SUBMIT TIME DATE VALIDATION ONLY
    if (_dateController.text.isNotEmpty &&
        _dateDueDateController.text.isNotEmpty) {
      // ✅ clear any "Submitting..." snackbar instantly
      ScaffoldMessenger.of(context).clearSnackBars();
      try {
        final startDate = DateFormat(uiDateFormat).parse(_dateController.text);
        final dueDate =
            DateFormat(uiDateFormat).parse(_dateDueDateController.text);

        if (dueDate.isBefore(startDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 2), // ⚡ fast
              content: Text(
                'Due time can not be less than observation time',
              ),
            ),
          );
          setState(() => _isSubmitting = false);
          return; // ⛔ HARD STOP – API CALL NAHI JAYEGI
        }
      } catch (e) {
        debugPrint('❌ DATE PARSE ERROR: $e');
        setState(() => _isSubmitting = false);
        return;
      }
    }

    // 🔐 NOW lock submit
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      String observationDescription = observationDescriptionController.text;
      String actionToBeTaken = actionToBeTakenController.text;

      int? projectID = await SharedPrefsHelper.getProjectID();
      int? companyID = await SharedPrefsHelper.getCompanyId();
      int? userID = await SharedPrefsHelper.getUserId();

      if (projectID == null || companyID == null || userID == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❗ Missing user or project information')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final selectedObservedBy = ObservationConstants.observedBy.firstWhere(
        (item) => item['id'] == observedById,
        orElse: () => {"id": 0, "observedBy": ""},
      )['id'] as int;

      final String? dueDateValue =
          isDueDateEnabled && _dateDueDateController.text.isNotEmpty
              ? _dateDueDateController.text
              : null;

      final observationIdToSend =
          (siteObservationId != null && siteObservationId! > 0)
              ? siteObservationId
              : null;

      int fromStatusID = isDraft
          ? SiteObservationStatus.Draft
          : ((siteObservationId != null && siteObservationId! > 0)
              ? SiteObservationStatus.Draft
              : SiteObservationStatus.Open);

      int toStatusID = isDraft
          ? SiteObservationStatus.Draft
          : (!isComplianceRequired
              ? SiteObservationStatus.Closed
              : SiteObservationStatus.Open);

      // ----------------------------
      // Null-safe lookups for Observation / Type / Issue
      // ----------------------------
      final selectedObservationObj = observationsList.firstWhere(
        (o) => o.observationDisplayText.trim() == selectedObservation?.trim(),
        orElse: () => observationsList.isNotEmpty
            ? observationsList.first
            : throw Exception('No Observation found'),
      );

      final selectedObservationTypeObj = observationTypeList.firstWhere(
        (o) => o.name.trim() == selectedObservationType?.trim(),
        orElse: () => observationTypeList.isNotEmpty
            ? observationTypeList.first
            : throw Exception('No ObservationType found'),
      );

      final selectedIssueTypeObj = issueTypes.firstWhere(
        (o) => o.name.trim() == selectedIssueType?.trim(),
        orElse: () => issueTypes.isNotEmpty
            ? issueTypes.first
            : throw Exception('No IssueType found'),
      );

      // ----------------------------
      // Build Activity List
      // ----------------------------
      List<SiteObservationActivity> finalActivityList = [];

      // Old + New DocUploaded
      finalActivityList.addAll(activityList
          .where((a) => a.actionID == SiteObservationActions.DocUploaded)
          .map((a) {
        return SiteObservationActivity(
          id: a.id,
          siteObservationID: a.siteObservationID,
          actionID: a.actionID,
          comments: a.comments,
          documentName: a.documentName,
          fileName: a.fileName,
          fileContentType: a.fileContentType,
          filePath: a.filePath,
          fromStatusID: isDraft ? a.fromStatusID : fromStatusID,
          toStatusID: isDraft ? a.toStatusID : toStatusID,
          assignedUserID: a.assignedUserID,
          createdBy: a.createdBy,
          createdDate: a.createdDate,
        );
      }));

      // Created action
      if (!finalActivityList
          .any((a) => a.actionID == SiteObservationActions.Created)) {
        finalActivityList.add(SiteObservationActivity(
          id: 0,
          siteObservationID: observationIdToSend,
          actionID: SiteObservationActions.Created,
          comments: '',
          documentName: '',
          fromStatusID: fromStatusID,
          toStatusID: toStatusID,
          assignedUserID: userID,
          createdBy: userID,
          createdDate: formatDateForApi(DateTime.now()),
        ));
      }

      // Assigned actions
      for (var username in selectedUsers.toSet()) {
        final user = userList.firstWhere((u) => u.userName == username);
        if (!finalActivityList.any((a) =>
            a.actionID == SiteObservationActions.Assigned &&
            a.assignedUserID == user.id)) {
          finalActivityList.add(SiteObservationActivity(
            id: 0,
            siteObservationID: observationIdToSend,
            actionID: SiteObservationActions.Assigned,
            comments: '',
            documentName: '',
            fromStatusID: fromStatusID,
            toStatusID: toStatusID,
            assignedUserID: user.id,
            createdBy: userID,
            createdDate: formatDateForApi(DateTime.now()),
          ));
        }
      }

      // Remove invalid
      finalActivityList
          .removeWhere((a) => a.fromStatusID == null || a.toStatusID == null);

      // ----------------------------
      // Build SiteObservationModel safely
      // ----------------------------
      SiteObservationModel commonFields = SiteObservationModel(
        uniqueID: const Uuid().v4(),
        id: siteObservationId ?? 0,
        siteObservationCode: "",
        trancationDate: formatDateForApi(DateTime.now().toUtc()),
        observationRaisedBy: userID,
        observationID: selectedObservationObj.id,
        observationTypeID: selectedObservationTypeObj.id,
        issueTypeID: selectedIssueTypeObj.id,
        dueDate: formatDateForApiNullable(dueDateValue),
        observationDescription: observationDescription,
        userDescription: '',
        complianceRequired: isComplianceRequired,
        escalationRequired: isEscalationRequired,
        actionToBeTaken: actionToBeTaken,
        companyID: companyID,
        projectID: projectID,
        functionID: ScreenTypes.Quality,
        activityID: selectedActivityId!,
        observedBy: selectedObservedBy,
        sectionID: selectedAreaId!,
        floorID: selectedFloorId!,
        partID: selectedPartId!,
        elementID: selectedElementId!,
        contractorID: selectedContractorId!,
        reworkCost: 0,
        comments: 'string',
        rootCauseID: 0,
        corretiveActionToBeTaken: '',
        preventiveActionTaken: '',
        statusID: toStatusID,
        isActive: true,
        createdBy: userID,
        createdDate: formatDateForApi(DateTime.now().toUtc()),
        lastModifiedBy: userID,
        lastModifiedDate: formatDateForApi(DateTime.now().toUtc()),
        siteObservationActivity: finalActivityList,
      );

      bool success = false;

      if (siteObservationId == null || siteObservationId == 0) {
        success = await widget._siteObservationService
            .submitSiteObservation(commonFields);
      } else {
        SiteObservationUpdateDraftModel updateModel =
            SiteObservationUpdateDraftModel(
          id: commonFields.id,
          dueDate: commonFields.dueDate,
          observationDescription: commonFields.observationDescription,
          complianceRequired: commonFields.complianceRequired,
          escalationRequired: commonFields.escalationRequired,
          actionToBeTaken: commonFields.actionToBeTaken,
          activityID: commonFields.activityID,
          sectionID: commonFields.sectionID,
          floorID: commonFields.floorID,
          partID: commonFields.partID,
          elementID: commonFields.elementID,
          contractorID: commonFields.contractorID,
          observedBy: commonFields.observedBy,
          statusID: commonFields.statusID,
          lastModifiedBy: commonFields.lastModifiedBy,
          lastModifiedDate: commonFields.lastModifiedDate,
          activityDTO: finalActivityList
              .map((a) => ActivityDTO(
                    id: a.id,
                    siteObservationID: a.siteObservationID,
                    actionID: a.actionID,
                    actionName: getActionNameFromID(a.actionID),
                    comments: a.comments,
                    documentName: a.documentName,
                    fileName: a.fileName,
                    fileContentType: a.fileContentType,
                    filePath: a.filePath,
                    fromStatusID: a.fromStatusID!,
                    toStatusID: a.toStatusID!,
                    assignedUserID:
                        a.assignedUserID != 0 ? a.assignedUserID : userID!,
                    assignedUserName: a.assignedUserName,
                    createdBy: a.createdBy != 0 ? a.createdBy : userID!,
                    createdByName: a.createdByName,
                    createdDate: DateTime.parse(a.createdDate),
                  ))
              .toList(),
        );

        success = await widget._siteObservationService
            .updateSiteObservationDraft(updateModel);
      }

      if (success) {
        _resetForm();
        setState(() {
          showObservations = true;
        });
        await fetchSiteObservationsQuality(projectID);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Operation Successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Submission failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString().replaceAll('"', '')}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

// Helper function for actionName
  String getActionNameFromID(int actionID) {
    switch (actionID) {
      case SiteObservationActions.Created:
        return 'Created';
      case SiteObservationActions.Assigned:
        return 'Assigned';
      case SiteObservationActions.DocUploaded:
        return 'DocUploaded';
      default:
        return 'Unknown';
    }
  }

  // 1️⃣ Load observation from server
  // 1️⃣ Update _loadObservationFromServer to accept int ID instead of object
  Future<void> _loadObservationFromServer(int observationId) async {
    try {
      // 🔹 Fetch full observation from server
      final observationList = await widget._siteObservationService
          .fetchGetSiteObservationMasterById(observationId);

      if (observationList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Observation not found')),
        );
        return;
      }
      // creatorId = observationList.first.createdBy;
      // 🔹 Take the first observation
      final fullObservation = observationList.first;

      // 🔹 Convert UTC date to local for UI
      if (fullObservation.trancationDate != null) {
        final localDate = fullObservation.trancationDate.toLocal();
        _dateController.text = DateFormat(uiDateFormat).format(localDate);
      }

      // 🔹 Set initial dropdown ID
      setState(() {
        creatorId = fullObservation.createdBy; // ✅ SAFE
        siteObservationId = fullObservation.id;
        selectedObservationTemplateId = fullObservation.id;
        showObservations = false;
      });

      // 🔹 Load rest of the form (dropdown, controllers, etc.)
      await _loadDataAndObservation(fullObservation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to load observation: $e')),
      );
    }
  }

// 2️⃣ _loadDataAndObservation stays same, now fullObservation is already object
  Future<void> _loadDataAndObservation(
      GetSiteObservationMasterById observation) async {
    // ================= BASIC PREFILL =================
    selectedObservationType = observation.observationType;
    selectedObservationTypeId = observation.observationTypeID;
    selectedIssueType = observation.issueType;
    isDraftObservation = observation.statusID == SiteObservationStatus.Draft;

    await fetchIssueTypes();

    final foundIssue = issueTypes.firstWhere(
      (e) => e.name == selectedIssueType,
      orElse: () => IssueType(id: 0, name: '', observationTypeID: 0),
    );

    selectedIssueTypeId = foundIssue.id;
    selectedIssueType = foundIssue.name;

    // ================= OBSERVATION DROPDOWN =================
    if (selectedIssueTypeId != 0) {
      await fetchObservations();

      /// ✅ Backend templateId nahi deta
      /// isliye pehle TEXT se match
      Observation? foundObs = observationsList.firstWhereOrNull(
        (o) =>
            o.observationDisplayText.trim().toLowerCase() ==
            observation.observationNameWithCategory.trim().toLowerCase(),
      );

      /// ✅ Agar list me nahi mila → add kar do (STABLE ID ke sath)
      if (foundObs == null) {
        foundObs = Observation(
          id: observation.id, // ❗ TEMP -1 ❌  |  REAL ID ✅
          observationTypeID: selectedObservationTypeId ?? 0,
          issueTypeID: selectedIssueTypeId ?? 0,
          observationDisplayText: observation.observationNameWithCategory,
          observationDescription: observation.description,
          complianceRequired: observation.complianceRequired,
          escalationRequired: observation.escalationRequired,
          dueTimeInHrs: 0,
          actionToBeTaken: observation.actionToBeTaken,
          lastModifiedBy: '',
          lastModifiedDate: DateTime.now().toIso8601String(),
        );

        observationsList.add(foundObs);
      }

      /// ✅ SINGLE SOURCE OF TRUTH
      setState(() {
        selectedObservationTemplateId = foundObs!.id;
        selectedObservationText = foundObs.observationDisplayText;

        // ❗ VERY IMPORTANT
        selectedObservation = foundObs.observationDescription;

        observationDescriptionController.text =
            foundObs.observationDescription ?? '';

        isComplianceRequired = foundObs.complianceRequired;
        isEscalationRequired = foundObs.escalationRequired;

        actionToBeTakenController.text = foundObs.actionToBeTaken ?? '';
      });

      /// 🔥 THIS WAS MISSING
      _recalculateDueDate();
    } else {
      observationsList.clear();
      selectedObservation = null;
      setState(() {});
      return;
    }

    // ================= OTHER FIELDS =================
    selectedActivityId =
        activitieList.any((a) => a.id == observation.activityID)
            ? observation.activityID
            : null;

    final observedName = observation.observedByName;
    final matchedObservedBy = ObservationConstants.observedBy.firstWhere(
      (item) =>
          (item['observedBy'] as String).toLowerCase() ==
          observedName.toLowerCase(),
      orElse: () => const {"id": 0, "observedBy": ""},
    );
    observedById = matchedObservedBy['id'] as int;

    selectedAreaId = areaList.any((a) => a.id == observation.sectionID)
        ? observation.sectionID
        : null;
    selectedFloorId = floorList.any((f) => f.id == observation.floorID)
        ? observation.floorID
        : null;
    selectedPartId = partList.any((p) => p.id == observation.partID)
        ? observation.partID
        : null;
    selectedElementId = elementList.any((e) => e.id == observation.elementID)
        ? observation.elementID
        : null;

    try {
      selectedContractor = ContractorList.firstWhere(
        (c) => c.id == observation.contractorID,
      );
      selectedContractorId = selectedContractor!.id;
    } catch (_) {
      selectedContractor = null;
      selectedContractorId = null;
    }

    // ================= USERS =================
    final fetchedUsers = await fetchUserList();
    userList = fetchedUsers;

    final assignedUsernames = observation.assignmentStatusDTO
        .map((e) => e.assignedUserName?.toLowerCase().trim())
        .where((e) => e != null && e.isNotEmpty)
        .toSet();

    selectedUserObjects = userList.where((user) {
      return assignedUsernames.contains(user.userName.toLowerCase().trim());
    }).toList();

    selectedUsers = selectedUserObjects.map((u) => u.userName).toList();

    // ================= FILES =================
    uploadedFiles = observation.activityDTO
        .where((a) => a.documentName != null && a.documentName!.isNotEmpty)
        .map((a) => a.documentName!)
        .toList();

    if (uploadedFiles.isNotEmpty) {
      selectedFileName = uploadedFiles.first;
    }

    activityDTOList = observation.activityDTO;
    populateActivityListFromDTO(activityDTOList);

    setState(() {
      selectedObservationId = observation.id;
      isUserSelectionEnabled = observation.observationTypeID != 1;
    });

    // ================= DEBUG =================
    debugPrint("✔ Dropdown IDs: ${observationsList.map((e) => e.id).toList()}");
    debugPrint("✔ Selected ID: $selectedObservationTemplateId");
    debugPrint("✔ Selected Text: $selectedObservationText");

    debugPrint("=== EDIT PREFILL ===");
    debugPrint("TemplateId: $selectedObservationTemplateId");
    debugPrint("Text: $selectedObservationText");
    debugPrint("Compliance: $isComplianceRequired");
    debugPrint("Escalation: $isEscalationRequired");
  }

  void populateActivityListFromDTO(List<ActivityDTO> dtoList) {
    activityList = dtoList.map((dto) {
      return SiteObservationActivity(
        id: dto.id ?? 0,
        siteObservationID: dto.siteObservationID,
        actionID: dto.actionID ?? 0,
        comments: dto.comments,
        documentName: dto.documentName ?? '',
        fileName: dto.fileName,
        fileContentType: dto.fileContentType,
        filePath: dto.filePath,
        fromStatusID: dto.fromStatusID ?? 0,
        toStatusID: dto.toStatusID ?? 0,
        assignedUserID: dto.assignedUserID ?? 0,
        assignedUserName: dto.assignedUserName,
        createdBy: dto.createdBy ?? 0,
        createdByName: dto.createdByName,
        createdDate: dto.createdDate.toIso8601String(),
      );
    }).toList();
  }

  void _resetForm() {
    _formKey.currentState?.reset();

    setState(() {
      // _dateController.clear();
      selectedObservationId = 0;
      selectedObservation = null; // Or null based on your logic
      selectedObservationType = null;
      selectedIssueType = null;
      selectedActivityId = null;
      selectedAreaId = null;
      selectedFloorId = null;
      selectedPartId = null;
      selectedElementId = null;
      // selectedContractorId = null;
      selectedContractor = null; // ⭐⭐ THIS LINE ⭐⭐
      selectedContractorId = null;
      actionToBeTakenController.clear();
      // reworkCostController.clear();
      observationDescriptionController.clear();
      // userDescriptionController.clear();
      uploadedFiles.clear();
      selectedFileName = null;
      isComplianceRequired = false;
      isEscalationRequired = false;
      _dateDueDateController.clear();
      observedById = null;
      observationsList = [];
      issueTypes = [];
      selectedUsers.clear();
      selectedUserObjects.clear();
      activityList = [];
      // isEditMode = false;
    });
  }

// start date value change reset logic
  bool _hasStartDateDependentData() {
    return selectedObservationType != null ||
        selectedIssueType != null ||
        selectedObservationTemplateId != null ||
        observationDescriptionController.text.trim().isNotEmpty ||
        _dateDueDateController.text.trim().isNotEmpty ||
        actionToBeTakenController.text.trim().isNotEmpty;
  }

  void _resetOnStartDateChange() {
    selectedObservationType = null;
    selectedObservationTypeId = 0;

    selectedIssueType = null;
    selectedIssueTypeId = 0;

    selectedObservation = null;
    selectedObservationTemplateId = null;

    observationsList = [];
    issueTypes = [];

    observationDescriptionController.clear();
    _dateDueDateController.clear();
    actionToBeTakenController.clear();

    isComplianceRequired = false;
    isEscalationRequired = false;
  }

  Future<bool> _showStartDateResetAlert(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Change Observation Date'),
            content: Text(
              'Changing the Observation Date will reset Observation and related fields.Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _onStartDateTap(BuildContext context) async {
    String oldValue = _dateController.text;

    await _selectDate(
      context,
      _dateController,
      allowFuture: false,
    );

    // ⛔ User cancelled OR same date
    if (_dateController.text.isEmpty || _dateController.text == oldValue) {
      return;
    }

    // 🔕 First time OR no dependent data → no alert, no reset
    if (oldValue.isEmpty || !_hasStartDateDependentData()) {
      return;
    }

    // ⚠️ Data exists → alert
    bool proceed = await _showStartDateResetAlert(context);
    if (!proceed) {
      // 🔁 revert old date
      _dateController.text = oldValue;
      return;
    }

    // ✅ User confirmed → reset
    setState(() {
      _resetOnStartDateChange();
    });
  }

// Issue Type value chnage reset logic
  bool shouldResetFields() {
    return !isDraftObservation && isEditMode;
  }

  bool _hasDependentDataFilled() {
    return observationDescriptionController.text.trim().isNotEmpty ||
        _dateDueDateController.text.trim().isNotEmpty ||
        actionToBeTakenController.text.trim().isNotEmpty;
  }

  void _applyIssueTypeChange(String? newValue) {
    setState(() {
      selectedIssueType = newValue;

      final selectedIssue = issueTypes.firstWhereOrNull(
        (e) => e.name == newValue,
      );

      if (selectedIssue != null) {
        selectedIssueTypeId = selectedIssue.id;
        fetchObservations();
      } else {
        selectedIssueTypeId = 0;
        observationsList = [];
      }

      // 🔁 Reset only when NOT draft
      if (!isDraftObservation && isEditMode) {
        _resetDependentFields();
      }
    });
  }

  void _resetDependentFields() {
    _dateDueDateController.clear();
    observationDescriptionController.clear();
    actionToBeTakenController.clear();

    isComplianceRequired = false;
    isEscalationRequired = false;

    selectedObservation = null;
    selectedObservationTemplateId = null;
  }

  Future<bool> _showResetAlert(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Change Issue Type'),
            content: Text(
                'Changing the Issue Type will reset Observation and related fields. Do you want to continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

// 🔧 1. Switch Row: Ek label aur switch
  Widget _buildToggleRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: isToggleEnabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

// 🔧 2. Responsive Layout (mobile/tablet)
  Widget _buildToggleSwitches(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      // 📱 Mobile view: stacked
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggleRow("Compliance Required", isComplianceRequired, (value) {
            setState(() {
              isComplianceRequired = value;

              if (!isComplianceRequired) {
                _dateDueDateController.text = '';
              } else {
                // 🔥 SINGLE SOURCE OF TRUTH
                _recalculateDueDate();
              }
            });
          }),
          _buildToggleRow("Escalation Required", isEscalationRequired, (value) {
            setState(() {
              isEscalationRequired = value;
            });
          }),
        ],
      );
    } else {
      // 💻 Tablet view: side-by-side
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildToggleRow("Compliance Required", isComplianceRequired,
                (value) {
              setState(() {
                isComplianceRequired = value;
                if (!isComplianceRequired) {
                  // disable + clear due date
                  _dateDueDateController.text = '';
                } else {
                  _recalculateDueDate();
                }
              });
            }),
          ),
          Expanded(
            child: _buildToggleRow("Escalation Required", isEscalationRequired,
                (value) {
              setState(() {
                isEscalationRequired = value;
              });
            }),
          ),
        ],
      );
    }
  }

  Widget _buildAttachmentItem(
      ActivityDTO activity, GetSiteObservationMasterById detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(activity.actionName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            "Uploaded By: ${activity.createdByName}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            "Status: ${getAttachmentStatusName(activity, detail)}",
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // 🔹 Image fixed size
              GestureDetector(
                onTap: () => openImageModal(activity.documentName),
                child: Container(
                  height: 120, // fixed height
                  width: 120, // fixed width
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
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
                          const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 🔹 Download button aligned with image
              IconButton(
                icon: const Icon(Icons.download, size: 28, color: Colors.blue),
                onPressed: () => downloadImage(activity.documentName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _userHeader(String initial, String name, String date) {
  //   return Row(
  //     children: [
  //       CircleAvatar(
  //         radius: 18,
  //         backgroundColor: Colors.blue.shade100,
  //         child: Text(
  //           initial,
  //           style: const TextStyle(
  //             fontWeight: FontWeight.bold,
  //             color: Colors.blue,
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 10),
  //       Expanded(
  //         child: Text(
  //           name,
  //           style: const TextStyle(
  //             fontWeight: FontWeight.bold,
  //             fontSize: 14,
  //           ),
  //         ),
  //       ),
  //       Text(
  //         date,
  //         style: const TextStyle(
  //           fontSize: 11,
  //           color: Colors.grey,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildActivityItem(List<ActivityDTO> activities) {
    final sortedActivities = [...activities]
      ..sort((a, b) => a.createdDate.compareTo(b.createdDate));

    final latestActivity = sortedActivities.last;
    final first = sortedActivities.first;

    final userInitial =
        (first.createdByName != null && first.createdByName!.isNotEmpty)
            ? first.createdByName![0].toUpperCase()
            : '?';

    final date = first.createdDate?.toLocal().toString().split('.').first ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 USER HEADER
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue.withOpacity(0.15),
                    child: Text(
                      userInitial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      first.createdByName ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 🔹 CARD LEVEL STATUS
              if (latestActivity.fromStatusName != null ||
                  latestActivity.toStatusName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_alt,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "${latestActivity.fromStatusName ?? '-'} → ${latestActivity.toStatusName ?? '-'}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // 🔹 ALL ACTIONS
              ...sortedActivities.map((activity) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action name
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: activity.actionName == 'Assign'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activity.actionName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: activity.actionName == 'Assign'
                              ? Colors.green
                              : Colors.blue,
                        ),
                      ),
                    ),

                    // Assigned user
                    if (activity.assignedUserName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Chip(
                          label: Text(
                            activity.assignedUserName!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),

                    // Comment
                    if ((activity.comments ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          activity.comments!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),

                    // Attachment
                    if (activity.documentName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 60, // height chhoti rakho
                              width: 60, // width proportional rakho
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  isImage(activity.documentName)
                                      ? "$url/${activity.documentName}"
                                      : "assets/default-image.png",
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),
                    if (activity != sortedActivities.last)
                      const Divider(height: 16),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  List<UserList> getAssignedUsersForActivity(
    ActivityDTO activity,
    List<ActivityDTO> allActivities,
    List<UserList> userMasterList,
  ) {
    final assignActivities = allActivities.where((a) {
      final sameAction = a.actionName == 'Assign';
      final sameCreator = a.createdBy == activity.createdBy;
      return sameAction && sameCreator; // ignore time diff for now
    }).toList();

    return assignActivities
        .map((a) => userMasterList.firstWhere(
              (u) => u.id.toString() == a.assignedUserID.toString(),
              orElse: () => UserList(
                id: 0,
                userName: '',
                firstName: 'Unknown',
                lastName: '',
              ),
            ))
        .toList();
  }

  // List<UserList> getAssignedUsersForActivity(ActivityDTO activity) {
  //   // widget.detail.activityDTO instead of detail.activityDTO
  //   final assignActivities = widget.detail.activityDTO.where((a) {
  //     final sameAction = a.actionName == 'Assign';
  //     final sameTime =
  //         (a.createdDate.difference(activity.createdDate)).inSeconds.abs() <= 5;
  //     final sameCreator = a.createdBy == activity.createdBy;
  //     return sameAction && sameTime && sameCreator;
  //   }).toList();

  //   final users = assignActivities
  //       .map((a) => userMasterList.firstWhere(
  //             (u) => u.id == a.assignedUserID,
  //             orElse: () => UserList(
  //               id: 0,
  //               userName: '',
  //               firstName: 'Unknown',
  //               lastName: '',
  //             ),
  //           ))
  //       .toList();

  //   return users;
  // }
  int SHIFT_START_HOUR = 9;
  int SHIFT_END_HOUR = 17;
  bool isNonWorkingDay(DateTime date) {
    // Sunday example
    return date.weekday == DateTime.sunday;
  }

  DateTime calculateWorkingDueDate(DateTime start, int dueHours) {
    const int SHIFT_START = 9;
    const int SHIFT_END = 19;
    const int FIXED_MINUTE = 0; // 🔥 Angular behaviour

    int remaining = dueHours;
    DateTime current = start;

    while (remaining > 0) {
      // Skip Sunday
      if (current.weekday == DateTime.sunday) {
        current = DateTime(
          current.year,
          current.month,
          current.day + 1,
          SHIFT_START,
          FIXED_MINUTE,
        );
        continue;
      }

      // Before shift
      if (current.hour < SHIFT_START) {
        current = DateTime(
          current.year,
          current.month,
          current.day,
          SHIFT_START,
          FIXED_MINUTE,
        );
      }

      // After shift
      if (current.hour >= SHIFT_END) {
        current = DateTime(
          current.year,
          current.month,
          current.day + 1,
          SHIFT_START,
          FIXED_MINUTE,
        );
        continue;
      }

      final available = SHIFT_END - current.hour;

      if (remaining <= available) {
        current = current.add(Duration(hours: remaining));
        remaining = 0;
      } else {
        remaining -= available;
        current = DateTime(
          current.year,
          current.month,
          current.day + 1,
          SHIFT_START,
          FIXED_MINUTE,
        );
      }
    }

    return current;
  }

//Due Date Logic
  void _recalculateDueDate() {
    // 1️⃣ Compliance OFF → clear
    if (!isComplianceRequired) {
      _dateDueDateController.text = '';
      return;
    }

    // 2️⃣ Observation OR Date missing
    if (_dateController.text.isEmpty || selectedObservationTemplateId == null) {
      _dateDueDateController.text = '';
      return;
    }

    // 3️⃣ Find observation BY ID (IMPORTANT FIX)
    final selectedObs = observationsList.firstWhereOrNull(
      (obs) => obs.id == selectedObservationTemplateId,
    );

    debugPrint("Matched Observation: ${selectedObs?.observationDisplayText}");
    debugPrint("Matched DueHrs: ${selectedObs?.dueTimeInHrs}");

    if (selectedObs == null) {
      _dateDueDateController.text = '';
      return;
    }

    // 4️⃣ dueTimeInHrs check
    if (selectedObs.dueTimeInHrs == 0) {
      _dateDueDateController.text = '';
      return;
    }

    // 5️⃣ Calculate due date ✅
    try {
      DateTime startDate = DateFormat(uiDateFormat).parse(_dateController.text);

      DateTime dueDate = calculateWorkingDueDate(
        startDate,
        selectedObs.dueTimeInHrs,
      );

      _dateDueDateController.text = DateFormat(uiDateFormat).format(dueDate);

      debugPrint("=== RECALCULATE DUE DATE ===");
      debugPrint("ComplianceRequired: $isComplianceRequired");
      debugPrint("StartDateText: ${_dateController.text}");
      debugPrint("_dateDueDateController.text: ${_dateDueDateController.text}");
      debugPrint("SelectedTemplateId: $selectedObservationTemplateId");
    } catch (e) {
      _dateDueDateController.text = '';
    }
  }

  String _formatDate(DateTime? date) {
    return date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal())
        : 'N/A';
  }

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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget buildPairRow(
    BuildContext context, {
    required String label1,
    String? value1,
    String? label2,
    String? value2,
    Color valueColor = Colors.black87, // ✅ ADD THIS
  }) {
    final has1 = value1?.trim().isNotEmpty == true && value1 != 'N/A';
    final has2 = value2?.trim().isNotEmpty == true && value2 != 'N/A';

    if (!has1 && !has2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (has1)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label1,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value1!,
                      style: TextStyle(color: valueColor), // ✅ USED HERE
                    ),
                  ),
                ],
              ),
            ),
          if (has1 && has2) const SizedBox(width: 12),
          if (has2)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label2!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value2!,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
        ],
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

  Future<void> _openObservationDetailPopup(int observationId) async {
    try {
      // 1️⃣ Fetch observation detail
      // final observationList = await widget._siteObservationService
      //     .fetchGetSiteObservationMasterById(observationId);
      final observationList = await widget._siteObservationService
          .fetchGetSiteObservationMasterById(observationId);

      if (observationList.isEmpty || !mounted) return;

      final detail = observationList.first;
      debugPrint("Observation Detail: $detail", wrapWidth: 1024);

      // 2️⃣ Fetch all users for this observation (UserList)
      // final userMasterList =
      //     await widget._siteObservationService.getUsersForSiteObservation(
      //   siteObservationId: detail.id,
      //   flag: 1, // backend me kya flag expect ho raha hai, uske hisaab se
      // );
      // for (var a in detail.activityDTO) {
      //   debugPrint(
      //       "Activity: ${a.actionName}, AssignedUserID: ${a.assignedUserID}, CreatedBy: ${a.createdBy}");
      // }

      // 3️⃣ Local function to get assigned users for an activity
      Map<String, List<ActivityDTO>> groupedActivities = {};
      Set<int> usedIndexes = {};

      for (int i = 0; i < detail.activityDTO.length; i++) {
        if (usedIndexes.contains(i)) continue;

        final current = detail.activityDTO[i];
        final group = <ActivityDTO>[current];
        usedIndexes.add(i);

        for (int j = i + 1; j < detail.activityDTO.length; j++) {
          if (usedIndexes.contains(j)) continue;

          final other = detail.activityDTO[j];
          final sameUser = other.createdBy == current.createdBy;
          final timeDiff = (other.createdDate.difference(current.createdDate))
              .inSeconds
              .abs();

          if (sameUser && timeDiff <= 5) {
            group.add(other);
            usedIndexes.add(j);
          }
        }

        groupedActivities['$i'] = group;
      }

      // 4️⃣ Show Dialog
      showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 1000,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Observation Details (View Only)',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context, true))
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildTextIfNotEmpty(
                            detail.observationNameWithCategory,
                          ),
                          // const SizedBox(height: 6),
                          // ✅ SAME METHOD AS DETAIL TAB
                          _buildResponsiveRow(
                            context,
                            "Observation Date :",
                            _formatDate(detail.trancationDate),
                            "Created Date :",
                            _formatDate(detail.createdDate),
                          ),

                          _buildResponsiveRow(
                            context,
                            "Observation Type :",
                            detail.observationType ?? 'N/A',
                            "Issue Type :",
                            detail.issueType ?? 'N/A',
                          ),

                          _buildResponsiveRow(
                            context,
                            "Created By :",
                            detail.observationRaisedBy ?? 'N/A',
                            "Due Date :",
                            _formatDate(detail.dueDate),
                          ),

                          _buildResponsiveRow(
                            context,
                            "Activity :",
                            detail.activityName ?? 'N/A',
                            "Block :",
                            detail.sectionName ?? 'N/A',
                          ),

                          _buildResponsiveRow(
                            context,
                            "Floor :",
                            detail.floorName ?? 'N/A',
                            "Pour :",
                            detail.partName ?? 'N/A',
                          ),

                          _buildResponsiveRow(
                            context,
                            "Element :",
                            detail.elementName ?? 'N/A',
                            "Contractor :",
                            detail.contractorName ?? 'N/A',
                          ),

                          _buildResponsiveRow(
                            context,
                            "Compliance Required :",
                            detail.complianceRequired ? 'Yes' : 'No',
                            "Escalation Required :",
                            detail.escalationRequired ? 'Yes' : 'No',
                          ),

                          buildPairRow(
                            context,
                            label1: "Observed By :",
                            value1: detail.observedByName,
                          ),

                          buildPairRow(
                            context,
                            label1: "Observation Description :",
                            value1: detail.description,
                          ),

                          buildPairRow(
                            context,
                            label1: "Action To Be Taken :",
                            value1: detail.actionToBeTaken,
                          ),
                          buildPairRow(
                            context,
                            label1: "Assigned Users :",
                            value1: detail.assignedUsersName,
                          ),

                          const SizedBox(height: 16),

                          _rootCauseSection(detail),
                          const SizedBox(height: 12),
                          ExpansionTile(
                            title: Text(
                              "Attachments (${detail.activityDTO.where((a) => a.documentName.isNotEmpty).length})",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            initiallyExpanded: false,
                            children: detail.activityDTO
                                .where((activity) =>
                                    activity.documentName.isNotEmpty)
                                .map((activity) =>
                                    _buildAttachmentItem(activity, detail))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          ExpansionTile(
                            title: Text(
                              "Activities (${detail.activityDTO.length})",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            children: groupedActivities.values
                                .map((acts) => _buildActivityItem(acts))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to load details')));
    }
  }

// Popup row for date (if valid)
  // Widget _popupDateRowIfValid(String label, DateTime? date) {
  //   if (date == null) return const SizedBox.shrink();
  //   return _popupRow(label, "${date.toLocal()}".split(' ')[0]);
  // }

  Widget _rootCauseSection(GetSiteObservationMasterById observation) {
    final widgets = <Widget>[];
    print("observation.reworkCost:${observation.reworkCost}");
    void addIfValid(String label, dynamic value) {
      if (value == null) return;

      // Numeric check
      if (value is num && value == 0) return;

      // String check
      if (value is String &&
          (value.trim().isEmpty ||
              value == 'N/A' ||
              value == '0' ||
              value == '0.0')) return;

      // Add widget
      widgets.add(
        buildPairRow(
          context,
          label1: "$label :",
          value1: value.toString(),
        ),
      );
    }

    // 🔹 Normal fields
    addIfValid("Root Cause Name", observation.rootCauseName);
    addIfValid("Rework Cost", observation.reworkCost);
    addIfValid("Root Cause Description", observation.rootcauseDescription);
    addIfValid(
        "Corrective Action To Be Taken", observation.corretiveActionToBeTaken);
    addIfValid("Preventive Action Taken", observation.preventiveActionTaken);

    // 🔴 Reopen Remarks (only when Reopen)
    if (observation.statusID == SiteObservationStatus.Reopen &&
        observation.reopenRemarks != null &&
        observation.reopenRemarks!.trim().isNotEmpty) {
      widgets.add(
        buildPairRow(
          context,
          label1: "Reopen Remarks :",
          value1: observation.reopenRemarks,
          valueColor: Colors.red,
        ),
      );
    }

    // 🟢 Closure Remarks (only when Closed)
    if (observation.statusID == SiteObservationStatus.Closed &&
        observation.closeRemarks != null &&
        observation.closeRemarks!.trim().isNotEmpty) {
      widgets.add(
        buildPairRow(
          context,
          label1: "Closure Date:",
          value1: _formatDate(observation.lastModifiedDate),
          valueColor: Colors.green,
        ),
      );
      widgets.add(
        buildPairRow(
          context,
          label1: "Closure Remarks :",
          value1: observation.closeRemarks,
          valueColor: Colors.green,
        ),
      );
    }

    // 👉 Agar kuch bhi nahi hai → pura section hide
    if (widgets.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(thickness: 1),
          const Text(
            'Root Cause (View Only)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...widgets,
        ],
      ),
    );
  }

  void _removeUploadedFile(String fileName) {
    setState(() {
      uploadedFiles.remove(fileName);

      activityList.removeWhere(
        (a) => a.documentName == fileName,
      );

      activityDTOList.removeWhere(
        (dto) => dto.documentName == fileName,
      );

      if (selectedFileName == fileName) {
        selectedFileName = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!showObservations) {
          // 👇 Reset form values
          _resetForm();
          isEditMode = false;
          // 👇 Switch back to observations list
          setState(() {
            showObservations = true;
          });
          return false;
        }
        if (selectedObservationForView != null) {
          // 🔴 Non-draft view se back
          setState(() {
            selectedObservationForView = null;
            showObservations = false;
          });
          return false;
        }
        return true; // Default: allow back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Site Observation - Quality'),
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showObservations)
                DropdownButton<Project>(
                  isExpanded: true,
                  hint: Text("Select a project"),
                  value: selectedProject,
                  items: projectList.map((project) {
                    return DropdownMenuItem<Project>(
                      value: project,
                      child: Text(project.name),
                    );
                  }).toList(),
                  onChanged: (Project? newProject) async {
                    if (newProject != null) {
                      setState(() {
                        selectedProject = newProject;
                        isFormReady = false;
                      });
                      await SharedPrefsHelper.saveProjectID(newProject.id);
                      await fetchSiteObservationsQuality(newProject.id);
                      await fetchAreaList(newProject.id);
                      await fetchFloorList(newProject.id);
                      await fetchPartList(newProject.id);
                      await fetchElementList(newProject.id);
                    }
                    setState(() {
                      isFormReady = true;
                    });
                  },
                ),
              SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            showObservations
                                ? (observations.isEmpty
                                    ? Center(
                                        child: Text(
                                          "No Observations Available",
                                          style: TextStyle(
                                              fontSize: 18, color: Colors.grey),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: observations.length,
                                        itemBuilder: (context, index) {
                                          SiteObservation observation =
                                              observations[index];
                                          bool isDark =
                                              Theme.of(context).brightness ==
                                                  Brightness.dark;

                                          return InkWell(
                                            onTap: () {
                                              if (observation.observationStatus
                                                      .toLowerCase() ==
                                                  'draft') {
                                                // 🟢 Open editable form
                                                setState(() {
                                                  showObservations = false;
                                                  _loadObservationFromServer(
                                                      observation.id);
                                                  selectedObservationForView =
                                                      null;
                                                });
                                              } else {
                                                _openObservationDetailPopup(
                                                    observation.id);
                                              }
                                            },
                                            child: Card(
                                              color: isDark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade100,
                                              elevation: 3,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: BorderSide.none,
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      observation
                                                          .siteObservationCode,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: isDark
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      'Observation Type: ',
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.color,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: observation
                                                                          .observationType ??
                                                                      'N/A',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyMedium,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      'Issue Type: ',
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.color,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: observation
                                                                          .issueType ??
                                                                      'N/A',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyMedium,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      'Status: ',
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.color,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: observation
                                                                          .observationStatus ??
                                                                      'N/A',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyMedium,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      'Project: ',
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.color,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: observation
                                                                          .projectName ??
                                                                      'N/A',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyMedium,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      'Date: ',
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.color,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: observation
                                                                              .transactionDate !=
                                                                          null
                                                                      ? DateFormat('MM/dd/yyyy').format(observation
                                                                          .transactionDate
                                                                          .toLocal())
                                                                      : 'N/A',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyMedium,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      'Is Overdue: ',
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.color,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: observation
                                                                          .isoverdue ??
                                                                      'N/A',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyMedium,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      observation
                                                          .observationDescription,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.black87,
                                                      ),
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.visible,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ))
                                : Card(
                                    margin: EdgeInsets.only(top: 8),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              controller: _dateController,
                                              decoration: InputDecoration(
                                                labelText: 'Start Date',
                                                hintText:
                                                    'Select a date and time',
                                                border: OutlineInputBorder(),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                      Icons.calendar_today),
                                                  onPressed: isEditMode
                                                      ? () => _onStartDateTap(
                                                          context)
                                                      : null,
                                                ),
                                              ),
                                              readOnly: true,
                                            ),

                                            SizedBox(height: 20),
                                            DropdownButtonFormField<String>(
                                              value: observationTypeList.any(
                                                      (e) =>
                                                          e.name ==
                                                          selectedObservationType)
                                                  ? selectedObservationType
                                                  : null,
                                              onChanged: (!isDraftObservation &&
                                                      isEditMode)
                                                  ? (String? newValue) {
                                                      setState(() {
                                                        selectedObservationType =
                                                            newValue;
                                                        final selected =
                                                            observationTypeList
                                                                .firstWhereOrNull(
                                                          (e) =>
                                                              e.name ==
                                                              newValue,
                                                        );
                                                        if (selected != null) {
                                                          selectedObservationTypeId =
                                                              selected.id;
                                                          isUserSelectionEnabled =
                                                              true;
                                                          actionToBeTakenEnabled =
                                                              true;
                                                          fetchIssueTypes();
                                                        } else {
                                                          selectedObservationTypeId =
                                                              0;
                                                          issueTypes = [];
                                                        }
                                                        selectedIssueType =
                                                            null;
                                                        selectedIssueTypeId = 0;
                                                        selectedObservation =
                                                            null;
                                                        observationsList = [];
                                                        issueTypes = [];
                                                        observationDescriptionController
                                                            .text = '';
                                                        _dateDueDateController
                                                            .text = '';
                                                        isComplianceRequired =
                                                            false;
                                                        isEscalationRequired =
                                                            false;
                                                        actionToBeTakenController
                                                            .text = '';
                                                      });
                                                    }
                                                  : null,
                                              decoration: InputDecoration(
                                                labelText: 'Observation Type',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator:
                                                  _validateObservationType,
                                              items: observationTypeList
                                                  .map((observationType) {
                                                return DropdownMenuItem<String>(
                                                  value: observationType.name,
                                                  child: Text(
                                                      observationType.name),
                                                );
                                              }).toList(),
                                            ),
                                            SizedBox(height: 20),

                                            // DropdownButtonFormField<String>(
                                            //   value: issueTypes.any((e) =>
                                            //           e.name ==
                                            //           selectedIssueType)
                                            //       ? selectedIssueType
                                            //       : null,
                                            //   onChanged: (!isDraftObservation &&
                                            //           isEditMode)
                                            //       ? (String? newValue) {
                                            //           setState(() {
                                            //             selectedIssueType =
                                            //                 newValue;

                                            //             try {
                                            //               final selectedIssue =
                                            //                   issueTypes
                                            //                       .firstWhere(
                                            //                 (element) =>
                                            //                     element.name ==
                                            //                     newValue,
                                            //               );
                                            //               selectedIssueTypeId =
                                            //                   selectedIssue.id;
                                            //               fetchObservations();
                                            //             } catch (e) {
                                            //               selectedIssueTypeId =
                                            //                   0;
                                            //               observationsList = [];
                                            //               selectedObservation =
                                            //                   null;
                                            //             }
                                            //           });
                                            //         }
                                            //       : null,
                                            //   decoration: InputDecoration(
                                            //     labelText: 'Issue Type',
                                            //     border: OutlineInputBorder(),
                                            //   ),
                                            //   items:
                                            //       issueTypes.map((issueType) {
                                            //     return DropdownMenuItem<String>(
                                            //       value: issueType.name,
                                            //       child: Text(issueType.name),
                                            //     );
                                            //   }).toList(),
                                            // ),
                                            // DropdownButtonFormField<String>(
                                            //   value: issueTypes.any((e) =>
                                            //           e.name ==
                                            //           selectedIssueType)
                                            //       ? selectedIssueType
                                            //       : null,
                                            //   onChanged: (!isDraftObservation &&
                                            //           isEditMode)
                                            //       ? (String? newValue) async {
                                            //           bool proceed = true;

                                            //           if (selectedIssueType !=
                                            //               null) {
                                            //             proceed =
                                            //                 await _showResetAlert(
                                            //                     context);
                                            //           }

                                            //           if (!proceed) return;

                                            //           setState(() {
                                            //             selectedIssueType =
                                            //                 newValue;

                                            //             final selectedIssue =
                                            //                 issueTypes
                                            //                     .firstWhereOrNull(
                                            //               (e) =>
                                            //                   e.name ==
                                            //                   newValue,
                                            //             );

                                            //             if (selectedIssue !=
                                            //                 null) {
                                            //               selectedIssueTypeId =
                                            //                   selectedIssue.id;
                                            //               fetchObservations();
                                            //             } else {
                                            //               selectedIssueTypeId =
                                            //                   0;
                                            //               observationsList = [];
                                            //             }

                                            //             if (shouldResetFields()) {
                                            //               _resetDependentFields();
                                            //             }
                                            //           });
                                            //         }
                                            //       : null,
                                            //   decoration: InputDecoration(
                                            //     labelText: 'Issue Type',
                                            //     border: OutlineInputBorder(),
                                            //   ),
                                            //   items:
                                            //       issueTypes.map((issueType) {
                                            //     return DropdownMenuItem<String>(
                                            //       value: issueType.name,
                                            //       child: Text(issueType.name),
                                            //     );
                                            //   }).toList(),
                                            // ),
                                            DropdownButtonFormField<String>(
                                              value: issueTypes.any((e) =>
                                                      e.name ==
                                                      selectedIssueType)
                                                  ? selectedIssueType
                                                  : null,
                                              onChanged: (!isDraftObservation &&
                                                      isEditMode)
                                                  ? (String? newValue) async {
                                                      // 🔕 First time / empty → no alert
                                                      if (!_hasDependentDataFilled()) {
                                                        _applyIssueTypeChange(
                                                            newValue);
                                                        return;
                                                      }

                                                      // ⚠️ Data filled → show alert
                                                      bool proceed =
                                                          await _showResetAlert(
                                                              context);
                                                      if (!proceed) return;

                                                      _applyIssueTypeChange(
                                                          newValue);
                                                    }
                                                  : null,
                                              decoration: InputDecoration(
                                                labelText: 'Issue Type',
                                                border: OutlineInputBorder(),
                                              ),
                                              items:
                                                  issueTypes.map((issueType) {
                                                return DropdownMenuItem<String>(
                                                  value: issueType.name,
                                                  child: Text(issueType.name),
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 20),

                                            DropdownSearch<Observation>(
                                              items: observationsList,
                                              selectedItem: observationsList
                                                  .firstWhereOrNull(
                                                (o) =>
                                                    o.id ==
                                                    selectedObservationTemplateId,
                                              ),
                                              itemAsString: (Observation o) =>
                                                  o.observationDisplayText,
                                              enabled: !isDraftObservation &&
                                                  isEditMode &&
                                                  selectedIssueTypeId != null &&
                                                  observationsList.isNotEmpty,
                                              popupProps: PopupProps.menu(
                                                showSearchBox: true,
                                                searchFieldProps:
                                                    TextFieldProps(
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Search Observation...',
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                              ),
                                              dropdownDecoratorProps:
                                                  DropDownDecoratorProps(
                                                dropdownSearchDecoration:
                                                    InputDecoration(
                                                  labelText:
                                                      'Select Observation',
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                              onChanged:
                                                  (Observation? selected) {
                                                if (selected == null) return;

                                                setState(() {
                                                  selectedObservationText =
                                                      selected
                                                          .observationDisplayText;
                                                  selectedObservationTemplateId =
                                                      selected.id;
                                                  selectedObservation = selected
                                                      .observationDescription;
                                                  observationDescriptionController
                                                      .text = selected
                                                          .observationDescription ??
                                                      '';
                                                  isComplianceRequired =
                                                      selected
                                                          .complianceRequired;
                                                  isEscalationRequired =
                                                      selected
                                                          .escalationRequired;
                                                  actionToBeTakenController
                                                      .text = selected
                                                          .actionToBeTaken ??
                                                      '';

                                                  // fetchObservations ke andar
                                                });
                                                _recalculateDueDate();
                                              },
                                            ),

                                            SizedBox(height: 20),
                                            TextFormField(
                                              controller:
                                                  observationDescriptionController,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'Observation Description',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              validator: _validateDescription,
                                            ),
                                            SizedBox(height: 20),
                                            TextFormField(
                                              controller:
                                                  _dateDueDateController,
                                              enabled: isDueDateEnabled,
                                              decoration: InputDecoration(
                                                labelText: 'Due Date',
                                                hintText: 'Select a date',
                                                border: OutlineInputBorder(),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                      Icons.calendar_today),
                                                  onPressed: () {
                                                    _selectDate(context,
                                                        _dateDueDateController,
                                                        allowFuture: true);
                                                  },
                                                ),
                                              ),
                                              readOnly: true,
                                              // validator: _validateDueDate,
                                            ),
                                            // TextFormField(
                                            //   controller:
                                            //       _dateDueDateController,
                                            //   decoration: InputDecoration(
                                            //     labelText: 'Due Date',
                                            //     border: OutlineInputBorder(
                                            //       borderRadius:
                                            //           BorderRadius.circular(8),
                                            //     ),
                                            //   ),
                                            //   // validator: _validateDescription,
                                            //   enabled:
                                            //       actionToBeTakenEnabled, // 🔑 Use your flag here
                                            // ),
                                            SizedBox(height: 20),

                                            _buildToggleSwitches(context),

                                            SizedBox(height: 20),
                                            DropdownButtonFormField<int>(
                                              value: selectedActivityId,
                                              onChanged: (int? newValue) {
                                                setState(() {
                                                  selectedActivityId = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Select Activity',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: _validateActivity,
                                              items: activitieList
                                                  .map((Activities activity) {
                                                return DropdownMenuItem<int>(
                                                  value: activity.id, // ✅ ID
                                                  child: Text(activity
                                                      .activityName), // ✅ Name show
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 20),
                                            DropdownButtonFormField<int>(
                                              value: observedById,
                                              decoration: InputDecoration(
                                                labelText: 'Observed By',
                                                border: OutlineInputBorder(),
                                              ),
                                              items: ObservationConstants
                                                  .observedBy
                                                  .map((item) {
                                                return DropdownMenuItem<int>(
                                                  value: item['id'] as int,
                                                  child: Text(item['observedBy']
                                                      as String),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  observedById = value;
                                                });
                                              },
                                            ),

                                            SizedBox(height: 20),
                                            DropdownButtonFormField<int>(
                                              value: selectedAreaId,
                                              onChanged: (int? newValue) {
                                                setState(() {
                                                  selectedAreaId = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Choose Area',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null) {
                                                  return 'Area is required';
                                                }
                                                return null;
                                              },
                                              items: areaList.map((Area area) {
                                                return DropdownMenuItem<int>(
                                                  value: area.id, // ✅ ID
                                                  child: Text(area
                                                      .sectionName), // UI me name
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 20),

                                            DropdownButtonFormField<int>(
                                              value: selectedFloorId,
                                              onChanged: (int? newValue) {
                                                setState(() {
                                                  selectedFloorId = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Choose Floor',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null) {
                                                  return 'Floor is required';
                                                }
                                                return null;
                                              },
                                              items:
                                                  floorList.map((Floor floor) {
                                                return DropdownMenuItem<int>(
                                                  value: floor.id, // ✅ ID
                                                  child: Text(floor
                                                      .floorName), // 👁 UI name
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 20),
                                            // Dropdown for Select Part

                                            DropdownButtonFormField<int>(
                                              value: selectedPartId,
                                              onChanged: (int? newValue) {
                                                setState(() {
                                                  selectedPartId = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Choose Part',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null) {
                                                  return 'Part is required';
                                                }
                                                return null;
                                              },
                                              items: partList.map((Part part) {
                                                return DropdownMenuItem<int>(
                                                  value: part.id, // ✅ ID
                                                  child: Text(
                                                      part.partName), // 👁 Name
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 20),
                                            // Dropdown for Select Element
                                            DropdownButtonFormField<int>(
                                              value: selectedElementId,
                                              onChanged: (int? newValue) {
                                                setState(() {
                                                  selectedElementId = newValue;
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Element Name',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null) {
                                                  return 'Element is required';
                                                }
                                                return null;
                                              },
                                              items: elementList
                                                  .map((Elements element) {
                                                return DropdownMenuItem<int>(
                                                  value: element.id, // ✅ ID
                                                  child: Text(element
                                                      .elementName), // 👁 Name
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 20),
                                            // Dropdown for Select Contractor Name
                                            // DropdownButtonFormField<int>(
                                            //   value: selectedContractorId,
                                            //   onChanged: (int? newValue) {
                                            //     setState(() {
                                            //       selectedContractorId =
                                            //           newValue;
                                            //     });
                                            //   },
                                            //   decoration: InputDecoration(
                                            //     labelText: 'Contractor Name',
                                            //     border: OutlineInputBorder(),
                                            //   ),
                                            //   validator: _validateContractor,
                                            //   items: ContractorList.map<
                                            //           DropdownMenuItem<int>>(
                                            //       (Party contractor) {
                                            //     return DropdownMenuItem<int>(
                                            //       value: contractor
                                            //           .id, // Ensure this is a String
                                            //       child: Text(
                                            //           contractor.partyName),
                                            //     );
                                            //   }).toList(),
                                            // ),

                                            DropdownSearch<Party>(
                                              items: ContractorList,
                                              itemAsString: (Party c) =>
                                                  c.partyName,

                                              selectedItem:
                                                  selectedContractor, // ✅ OBJECT pass karo

                                              popupProps: PopupProps.menu(
                                                showSearchBox: true,
                                                searchFieldProps:
                                                    TextFieldProps(
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        "Search contractor...",
                                                  ),
                                                ),
                                              ),

                                              dropdownDecoratorProps:
                                                  DropDownDecoratorProps(
                                                dropdownSearchDecoration:
                                                    InputDecoration(
                                                  labelText: 'Contractor Name',
                                                  hintText: 'Select Contractor',
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),

                                              onChanged: (Party? value) {
                                                setState(() {
                                                  selectedContractor =
                                                      value; // ✅ object
                                                  selectedContractorId =
                                                      value?.id; // ✅ id
                                                });
                                              },

                                              validator: (Party? value) {
                                                if (value == null) {
                                                  return 'Contractor Name is required';
                                                }
                                                return null;
                                              },
                                            ),

                                            SizedBox(height: 20),
                                            // MultiSelect for Assigned Users
                                            IgnorePointer(
                                              ignoring: !isUserSelectionEnabled,
                                              child: Opacity(
                                                opacity: isUserSelectionEnabled
                                                    ? 1.0
                                                    : 0.5,
                                                child: MultiSelectDialogField<
                                                    UserList>(
                                                  items: userList
                                                      .map(
                                                        (user) =>
                                                            MultiSelectItem<
                                                                UserList>(
                                                          user,
                                                          user.userName,
                                                        ),
                                                      )
                                                      .toList(),
                                                  initialValue:
                                                      selectedUserObjects,
                                                  title:
                                                      const Text("Assigned To"),
                                                  selectedItemsTextStyle:
                                                      const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                  itemsTextStyle:
                                                      const TextStyle(
                                                          fontSize: 16),
                                                  searchable: true,
                                                  buttonText: const Text(
                                                      "Select Users"),
                                                  onConfirm: (List<UserList>
                                                      selected) {
                                                    setState(() {
                                                      selectedUserObjects =
                                                          selected;
                                                      selectedUsers = selected
                                                          .map(
                                                              (u) => u.userName)
                                                          .toList();
                                                    });
                                                  },
                                                  chipDisplay:
                                                      MultiSelectChipDisplay(
                                                    onTap: (UserList user) {
                                                      setState(() {
                                                        selectedUserObjects
                                                            .remove(user);
                                                        selectedUsers =
                                                            selectedUserObjects
                                                                .map((u) =>
                                                                    u.userName)
                                                                .toList();
                                                      });
                                                    },
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            TextFormField(
                                              controller:
                                                  actionToBeTakenController,
                                              decoration: InputDecoration(
                                                labelText: 'Action to be Taken',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              // validator: _validateDescription,
                                              enabled:
                                                  actionToBeTakenEnabled, // 🔑 Use your flag here
                                            ),

                                            SizedBox(height: 20),
                                            // 🔽 File Upload Section just like TextFormField
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "Upload File",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                SizedBox(
                                                  width: double
                                                      .infinity, // ✅ Make button full width like form field
                                                  child: ElevatedButton.icon(
                                                    icon:
                                                        Icon(Icons.upload_file),
                                                    label: Text("Choose File"),
                                                    onPressed: () async {
                                                      FilePickerResult? result =
                                                          await FilePicker
                                                              .platform
                                                              .pickFiles(
                                                        allowMultiple: false,
                                                        withData: true,
                                                      );

                                                      if (result != null &&
                                                          result.files
                                                              .isNotEmpty) {
                                                        final file =
                                                            result.files.first;

                                                        if (mounted) {
                                                          setState(() {
                                                            isUploading = true;
                                                            selectedFileName = file
                                                                .name; // Show filename immediately after picking file
                                                          });
                                                        }

                                                        final uploadedFileName =
                                                            await SiteObservationService()
                                                                .uploadFileAndGetFileName(
                                                                    file.name,
                                                                    file.bytes!);

                                                        if (mounted) {
                                                          setState(() {
                                                            isUploading = false;
                                                          });
                                                        }

                                                        if (uploadedFileName !=
                                                            null) {
                                                          onFileUploadSuccess(
                                                              uploadedFileName,
                                                              isDraft: isDraft);
                                                        } else {
                                                          if (mounted) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                  content: Text(
                                                                      "❌ File upload failed")),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 16),
                                                      backgroundColor:
                                                          Colors.blue,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (selectedFileName !=
                                                    null) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    "Selected file: $selectedFileName",
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ],
                                                if (isUploading) ...[
                                                  const SizedBox(height: 8),
                                                  const LinearProgressIndicator(), // 👈 Better for full-width than Circular
                                                ],
                                                if (uploadedFiles
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 16),
                                                  const Text(
                                                    "Uploaded Files:",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  // for (var name
                                                  //     in uploadedFiles)
                                                  //   Text("📄 $name",
                                                  //       style: const TextStyle(
                                                  //           color:
                                                  //               Colors.green)),
                                                  for (var name
                                                      in uploadedFiles)
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 4),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .insert_drive_file,
                                                              color:
                                                                  Colors.green),
                                                          const SizedBox(
                                                              width: 8),

                                                          // File name
                                                          Expanded(
                                                            child: Text(
                                                              name,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .green,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),

                                                          // 🔴 REMOVE ICON (only this new)
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red),
                                                            onPressed: () {
                                                              _removeUploadedFile(
                                                                  name);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                ],
                                              ],
                                            ),

                                            // Row(
                                            //   mainAxisAlignment:
                                            //       MainAxisAlignment
                                            //           .spaceBetween,
                                            //   children: [
                                            //     Expanded(
                                            //       child: ElevatedButton(
                                            //         onPressed: _isSubmitting
                                            //             ? null
                                            //             : () {
                                            //                 if (_formKey
                                            //                         .currentState
                                            //                         ?.validate() ??
                                            //                     false) {
                                            //                   _submitForm(
                                            //                       isDraft:
                                            //                           true);
                                            //                 }
                                            //               },
                                            //         style: ElevatedButton
                                            //             .styleFrom(
                                            //           backgroundColor:
                                            //               Colors.grey,
                                            //           shape:
                                            //               RoundedRectangleBorder(
                                            //             borderRadius:
                                            //                 BorderRadius
                                            //                     .circular(8),
                                            //           ),
                                            //         ),
                                            //         child: _isSubmitting
                                            //             ? const SizedBox(
                                            //                 height: 20,
                                            //                 width: 20,
                                            //                 child:
                                            //                     CircularProgressIndicator(
                                            //                   strokeWidth: 2,
                                            //                   color:
                                            //                       Colors.white,
                                            //                 ),
                                            //               )
                                            //             : const Text(
                                            //                 'Save as Draft'),
                                            //       ),
                                            //     ),
                                            //     const SizedBox(width: 12),
                                            //     Expanded(
                                            //       child: ElevatedButton(
                                            //         onPressed: _isSubmitting
                                            //             ? null
                                            //             : () {
                                            //                 if (_formKey
                                            //                         .currentState
                                            //                         ?.validate() ??
                                            //                     false) {
                                            //                   _submitForm(
                                            //                       isDraft:
                                            //                           false);
                                            //                 }
                                            //               },
                                            //         style: ElevatedButton
                                            //             .styleFrom(
                                            //           backgroundColor:
                                            //               Colors.blue,
                                            //           shape:
                                            //               RoundedRectangleBorder(
                                            //             borderRadius:
                                            //                 BorderRadius
                                            //                     .circular(8),
                                            //           ),
                                            //         ),
                                            //         child: _isSubmitting
                                            //             ? const SizedBox(
                                            //                 height: 20,
                                            //                 width: 20,
                                            //                 child:
                                            //                     CircularProgressIndicator(
                                            //                   strokeWidth: 2,
                                            //                   color:
                                            //                       Colors.white,
                                            //                 ),
                                            //               )
                                            //             : const Text('Submit'),
                                            //       ),
                                            //     ),
                                            //   ],
                                            // ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // Save as Draft
                                                Expanded(
                                                  child:
                                                      widget.pagePermission
                                                              .canAdd
                                                          ? ElevatedButton(
                                                              onPressed:
                                                                  _isSubmitting
                                                                      ? null
                                                                      : () {
                                                                          if (_formKey.currentState?.validate() ??
                                                                              false) {
                                                                            _submitForm(isDraft: true);
                                                                          }
                                                                        },
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors.grey,
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                              ),
                                                              child: _isSubmitting
                                                                  ? const SizedBox(
                                                                      height:
                                                                          20,
                                                                      width: 20,
                                                                      child:
                                                                          CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                    )
                                                                  : const Text('Save as Draft'),
                                                            )
                                                          : const SizedBox(),
                                                ),

                                                const SizedBox(width: 12),

                                                // Submit
                                                Expanded(
                                                  child:
                                                      widget.pagePermission
                                                              .canAdd
                                                          ? ElevatedButton(
                                                              onPressed:
                                                                  _isSubmitting
                                                                      ? null
                                                                      : () {
                                                                          if (_formKey.currentState?.validate() ??
                                                                              false) {
                                                                            _submitForm(isDraft: false);
                                                                          }
                                                                        },
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors.blue,
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                              ),
                                                              child: _isSubmitting
                                                                  ? const SizedBox(
                                                                      height:
                                                                          20,
                                                                      width: 20,
                                                                      child:
                                                                          CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2,
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                    )
                                                                  : const Text('Submit'),
                                                            )
                                                          : const SizedBox(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: widget.pagePermission.canAdd
                    ? FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            if (!showObservations) {
                              _resetForm();
                              isEditMode = false;
                              isDraftObservation = false;
                            } else {
                              isEditMode = true;
                              isDraftObservation = false;
                              _dateController.text =
                                  DateFormat('dd/MM/yyyy HH:mm')
                                      .format(DateTime.now());
                            }
                            showObservations = !showObservations;
                          });
                        },
                        backgroundColor: Colors.blue,
                        child: Icon(showObservations ? Icons.add : Icons.list),
                      )
                    : const SizedBox(), // ❌ Add permission nahi → FAB bhi nahi
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String title, String value, {required bool isDark}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$title: ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
// New Code New Code ...
