import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:himappnew/constants.dart';
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

class SiteObservationQuality extends StatefulWidget {
  final String companyName;
  final ProjectService _projectService;
  final SiteObservationService _siteObservationService;

  const SiteObservationQuality({
    super.key,
    required this.companyName,
    required ProjectService projectService,
    required SiteObservationService siteObservationService,
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

  String? selectedActivities;
  List<Activities> activitieList = [];
  // List<Activities> activities = [];
  int? companyId;

  String? selectedObservation;
  List<Observation> observationsList = [];

  String? selectedObservationType;
  List<ObservationType> observationTypeList = [];

  String? selectedArea;
  List<Area> areaList = [];

  String? selectedPart;
  List<Part> partList = [];

  String? selectedFloor;
  List<Floor> floorList = [];

  String? selectedElement;
  List<Elements> elementList = [];

  String? selectedContractor;
  List<Party> ContractorList = [];

  // String? selectedUser;
  List<String> selectedUsers = [];
  List<User> userList = [];
  List<User> selectedMultiUsers = []; // Selected users (multi-select)
  List<User> selectedUserObjects = [];
  List<MultiSelectItem<User>> userItems = [];
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

  bool get isToggleEnabled {
    if (selectedIssueTypeId == 1 && selectedIssueType == 'NCR') {
      return false;
    }
    if (selectedObservation == null || selectedObservation!.isEmpty) {
      return true; // toggle enabled
    }

    // Find selected Observation from the list
    final selectedObs = observationsList.firstWhereOrNull(
      (obs) => obs.observationDescription == selectedObservation,
    );
    if (selectedObs == null) return true;

    // Compare using observationTypeID
    return selectedObs.observationTypeID != goodPracticeObservationTypeId;
  }

  int get goodPracticeObservationTypeId {
    final goodPracticeType = observationTypeList.firstWhereOrNull(
      (e) => e.name.toLowerCase().contains('good practice'),
    );
    return goodPracticeType?.id ?? -1;
  }

  bool get isDueDateEnabled {
    if (selectedIssueTypeId == 1 && selectedIssueType == 'NCR') {
      return false;
    }
    if (selectedObservation == null || selectedObservation!.isEmpty) {
      return true; // enable by default
    }

    final selectedObs = observationsList.firstWhereOrNull(
      (obs) => obs.observationDescription == selectedObservation,
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
  @override
  void initState() {
    super.initState();
    _initializeData();
    // userItems = userList
    //     .map((user) => MultiSelectItem<User>(user, user.userName))
    //     .toList();
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
          .map((user) => MultiSelectItem<User>(user, user.userName))
          .toList();
    });
    if (!isEditMode) {
      _dateController.text =
          DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()); // Local time
    }
    // futureObservations = widget._siteObservationService
    // _loadObservationFromServer(widget.de);
  }

  String formatDateForApi(DateTime date) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(date);
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
    if (companyId == null) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      List<Activities> fetchedActivities = await widget._siteObservationService
          .fetchActivities(companyId, ScreenTypes.Quality);
      setState(() {
        activitieList = fetchedActivities;
        selectedActivities = null;
      });
    } catch (e) {
      print('Error fetching activities: $e');
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
        selectedObservation = null;
        if (observationsList.isNotEmpty) {
          selectedIssueTypeId = observationsList[0].issueTypeID;
        } else {
          selectedObservation = null; // If no Observation, keep it null
        }
      });
    } catch (e) {
      print('Error fetching Observation: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
        selectedArea = null; // ✅ Don't auto-select any area
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
        selectedFloor = null; // ✅ Don't auto-select any floor
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
        return seen.add(name); // Only add if not already in Set
      }).toList();
      selectedPart = null; // Ensure nothing is pre-selected on load
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
        final name = element.elementName.trim();
        return seen.add(name);
      }).toList();

      setState(() {
        elementList = uniqueElements;
        selectedElement = null;
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
      List<Party> fetchedContractor =
          await widget._siteObservationService.fetchContractorList();
      setState(() {
        ContractorList = fetchedContractor;
        selectedContractor = null;
      });
    } catch (e) {
      print('Error fetching Contractor: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<User>> fetchUserList() async {
    try {
      int? currentUserId = await SharedPrefsHelper.getUserId();

      List<User> fetchedUsers =
          await widget._siteObservationService.fetchUserList();

      List<User> uniqueUsers = [];
      Set<String> userNames = {};

      for (var user in fetchedUsers) {
        if (!userNames.contains(user.userName) && user.id != currentUserId) {
          uniqueUsers.add(user);
          userNames.add(user.userName);
        }
      }

      return uniqueUsers; // ✅ return the list instead of setting state
    } catch (e) {
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

  String? _validateActivity(String? value) {
    if (value == null || value.isEmpty) {
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

  String? _validateContractor(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contractor Name is required';
    }
    return null;
  }

  String? _validateAssigned(String? value) {
    if (value == null || value.isEmpty) {
      return 'Assigned To is required';
    }
    return null;
  }

  // Function to show the date picker
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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
          controller.text =
              DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
        });
      }
    }
  }

  Future<void> loadSection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? projectID = prefs.getInt('projectID');

    if (projectID != null) {
      try {
        List<SectionModel> sections = await getSectionsByProjectID(projectID);
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

    final observationIdToSend = selectedObservationId;

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
        return;
      }

      final selectedObservedBy = ObservationConstants.observedBy.firstWhere(
        (item) => item['id'] == observedById,
        orElse: () => {"id": 0, "observedBy": ""},
      )['id'] as int;

      final String? dueDateValue;

      if (isDueDateEnabled) {
        if (_dateDueDateController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❗ Please select a due date')),
          );
          return;
        }
        dueDateValue = _dateDueDateController.text;
      } else {
        dueDateValue = null;
      }

      final observationIdToSend = selectedObservationId;

      // int statusIdToSend = isDraft
      //     ? SiteObservationStatus.Draft
      //     : (selectedObservationTypeId == 1
      //         ? SiteObservationStatus.Closed
      //         : SiteObservationStatus.Open);

      int fromStatusID = isDraft
          ? SiteObservationStatus.Draft
          : (selectedObservationId != 0
              ? SiteObservationStatus.Draft
              : SiteObservationStatus.Open);

      int toStatusID = isDraft
          ? SiteObservationStatus.Draft
          : (selectedObservationTypeId == 1
              ? SiteObservationStatus.Closed
              : SiteObservationStatus.Open);

      List<SiteObservationActivity> finalActivityList = [];

      // ✅ Step 1: Add OLD DocUploaded images
      // finalActivityList.addAll(activityList.where((a) =>
      //     a.actionID == SiteObservationActions.DocUploaded && a.id != 0));

      // // ✅ Step 2: Add NEW DocUploaded images
      // finalActivityList.addAll(activityList.where((a) =>
      //     a.actionID == SiteObservationActions.DocUploaded && a.id == 0));

      // ✅ Step 1: Add OLD DocUploaded images, override status for final submit
      finalActivityList.addAll(activityList
          .where((a) =>
              a.actionID == SiteObservationActions.DocUploaded && a.id != 0)
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
          // override only if NOT draft
          fromStatusID: isDraft ? a.fromStatusID : fromStatusID,
          toStatusID: isDraft ? a.toStatusID : toStatusID,
          assignedUserID: a.assignedUserID,
          createdBy: a.createdBy,
          createdDate: a.createdDate,
        );
      }));

// ✅ Step 2: Add NEW DocUploaded images, override status for final submit
      finalActivityList.addAll(activityList
          .where((a) =>
              a.actionID == SiteObservationActions.DocUploaded && a.id == 0)
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

      bool alreadyCreated = finalActivityList.any(
        (a) => a.actionID == SiteObservationActions.Created,
      );

      if (!alreadyCreated) {
        finalActivityList.add(SiteObservationActivity(
          id: 0,
          siteObservationID: observationIdToSend,
          actionID: SiteObservationActions.Created,
          comments: '',
          documentName: '',
          fromStatusID: fromStatusID,
          toStatusID: toStatusID,
          assignedUserID: userID ?? 0,
          createdBy: userID ?? 0,
          createdDate: formatDateForApi(DateTime.now()),
        ));
      }

      for (var username in selectedUsers.toSet()) {
        final user = userList.firstWhere((u) => u.userName == username);
        bool alreadyAssigned = finalActivityList.any(
          (a) =>
              a.actionID == SiteObservationActions.Assigned &&
              a.assignedUserID == user.id,
        );

        if (!alreadyAssigned) {
          finalActivityList.add(SiteObservationActivity(
            id: 0,
            siteObservationID: observationIdToSend,
            actionID: SiteObservationActions.Assigned,
            comments: '',
            documentName: '',
            fromStatusID: fromStatusID,
            toStatusID: toStatusID,
            assignedUserID: user.id,
            createdBy: userID ?? 0,
            createdDate: formatDateForApi(DateTime.now()),
          ));
        }
      }

      // ✅ Step 3: Add Created action if not already submitted
      if (!activityList.any(
          (a) => a.id != 0 && a.actionID == SiteObservationActions.Created)) {
        final created = activityList.firstWhere(
          (a) => a.actionID == SiteObservationActions.Created,
          orElse: () => SiteObservationActivity(
            id: -1,
            actionID: SiteObservationActions.Created,
            comments: '',
            documentName: '',
            fromStatusID: fromStatusID,
            toStatusID: toStatusID,
            assignedUserID: userID ?? 0,
            createdBy: userID ?? 0,
            createdDate: formatDateForApi(DateTime.now()),
          ),
        );
        if (created.id == 0 &&
            created.actionID == SiteObservationActions.Created) {
          finalActivityList.add(created);
        }
      }

      // ✅ Step 4: Add Assigned action if not already submitted
      if (!activityList.any(
          (a) => a.id != 0 && a.actionID == SiteObservationActions.Assigned)) {
        final assigned = activityList.firstWhere(
          (a) => a.actionID == SiteObservationActions.Assigned,
          orElse: () => SiteObservationActivity(
            id: -1,
            actionID: SiteObservationActions.Assigned,
            comments: '',
            documentName: '',
            fromStatusID: fromStatusID,
            toStatusID: toStatusID,
            assignedUserID: userID ?? 0,
            createdBy: userID ?? 0,
            createdDate: formatDateForApi(DateTime.now()),
          ),
        );
        if (assigned.id == 0 &&
            assigned.actionID == SiteObservationActions.Assigned) {
          finalActivityList.add(assigned);
        }
      }
      // ✅ Step 5: Remove invalid entries
      finalActivityList.removeWhere((a) =>
          a.actionID == 0 ||
          a.fromStatusID == null ||
          a.toStatusID == null ||
          a.createdBy == null);

      // ✅ Step 6: Log for debugging
      debugPrint(
          "📦 Final activityList to send (Draft/Submit): ${finalActivityList.length}");

      activityDTOList = finalActivityList.map((activity) {
        return ActivityDTO(
          id: activity.id,
          siteObservationID: activity.siteObservationID,
          actionID: activity.actionID,
          actionName: getActionNameFromID(activity.actionID),
          comments: activity.comments,
          documentName: activity.documentName,
          fileName: activity.fileName,
          fileContentType: activity.fileContentType,
          filePath: activity.filePath,
          fromStatusID:
              (activity.fromStatusID != 0 && activity.fromStatusID != null)
                  ? activity.fromStatusID
                  : fromStatusID,
          toStatusID: (activity.toStatusID != 0 && activity.toStatusID != null)
              ? activity.toStatusID
              : toStatusID,
          assignedUserID: activity.assignedUserID != 0
              ? activity.assignedUserID
              : userID ?? 0,
          assignedUserName: activity.assignedUserName,
          createdBy: activity.createdBy != 0 ? activity.createdBy : userID ?? 0,
          createdByName: activity.createdByName,
          createdDate: DateTime.parse(activity.createdDate),
        );
      }).toList();
      for (var dto in activityDTOList) {
        print(
            "📝 Draft Activity -> actionID: ${dto.actionID}, id: ${dto.id}, doc: ${dto.documentName}");
      }

      SiteObservationModel commonFields = SiteObservationModel(
        uniqueID: const Uuid().v4(),
        id: selectedObservationId,
        siteObservationCode: "",
        trancationDate: formatDateForApi(DateTime.now().toUtc()),
        observationRaisedBy: userID,
        observationID: observationsList
            .firstWhere((o) => o.observationDescription == selectedObservation)
            .id,
        observationTypeID: observationTypeList
            .firstWhere(
                (observation) => observation.name == selectedObservationType)
            .id,
        issueTypeID: issueTypes
            .firstWhere((issueType) => issueType.name == selectedIssueType)
            .id,
        dueDate: (dueDateValue != null && dueDateValue.isNotEmpty)
            ? dueDateValue
            : formatDateForApi(DateTime.now().toUtc()),
        observationDescription: observationDescription,
        userDescription: '',
        complianceRequired: isComplianceRequired,
        escalationRequired: isEscalationRequired,
        actionToBeTaken: actionToBeTaken,
        companyID: companyID,
        projectID: projectID,
        functionID: ScreenTypes.Quality,
        activityID: activitieList
            .firstWhere((a) => a.activityName == selectedActivities)
            .id,
        observedBy: selectedObservedBy,
        sectionID:
            areaList.firstWhere((area) => area.sectionName == selectedArea).id,
        floorID: floorList
            .firstWhere((floor) => floor.floorName == selectedFloor)
            .id,
        partID: partList.firstWhere((part) => part.partName == selectedPart).id,
        elementID: elementList
            .firstWhere((element) => element.elementName == selectedElement)
            .id,
        contractorID:
            ContractorList.firstWhere((c) => c.partyName == selectedContractor)
                .id,
        reworkCost: 0,
        comments: 'string',
        rootCauseID: 0,
        corretiveActionToBeTaken: 'Corrective action here',
        preventiveActionTaken: 'Preventive action here',
        statusID: toStatusID,
        isActive: true,
        createdBy: userID,
        createdDate: formatDateForApi(DateTime.now().toUtc()),
        lastModifiedBy: userID,
        lastModifiedDate: formatDateForApi(DateTime.now().toUtc()),
        siteObservationActivity: finalActivityList,
      );
      for (var dto in activityDTOList) {
        if (dto.actionID == SiteObservationActions.DocUploaded) {
          debugPrint("📁 DocUploaded => "
              "id: ${dto.id}, "
              "doc: ${dto.documentName}, "
              "fromStatusID: ${dto.fromStatusID}, "
              "toStatusID: ${dto.toStatusID}");
        }
      }
      bool success = false;

      if (selectedObservationId == 0) {
        debugPrint("commonFields: ${commonFields.toJson()}");
        debugPrint(const JsonEncoder.withIndent('  ').convert(activityDTOList));
        // return; // Debugging line, remove when ready
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
          activityDTO: activityDTOList,
        );

        Map<int, String> actionNames = {
          1: "Created",
          2: "Assigned",
          3: "DocUploaded",
        };

        for (var dto in activityDTOList) {
          final name = actionNames[dto.actionID] ?? 'Unknown';
          debugPrint("📝 $name => "
              "id: ${dto.id}, "
              "doc: ${dto.documentName}, "
              "assignedUserID: ${dto.assignedUserID}, "
              "fromStatusID: ${dto.fromStatusID}, "
              "toStatusID: ${dto.toStatusID}, "
              "createdBy: ${dto.createdBy}, "
              "createdDate: ${dto.createdDate}");
        }
        debugPrint("updateModel: $updateModel.toJson()");
        debugPrint(const JsonEncoder.withIndent('  ').convert(updateModel));
        // return;
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
          SnackBar(content: Text('❌ Submission failed without specific error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString().replaceAll('"', '')}')),
      );
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

  Future<void> _loadObservationFromServer(int observationId) async {
    try {
      final observationList = await widget._siteObservationService
          .fetchGetSiteObservationMasterById(observationId);

      if (observationList.isNotEmpty) {
        final observation = observationList.first;

        if (observation.trancationDate != null) {
          // 👇 Convert UTC to Local + Use T format
          final localDate = observation.trancationDate.toLocal();
          _dateController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(localDate);
        }

        setState(() {
          showObservations = false;
        });

        _loadDataAndObservation(observation);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Observation not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to load observation: $e')),
      );
    }
  }

  Future<void> _loadDataAndObservation(
      GetSiteObservationMasterById observation) async {
    print("Loading observation: $observation - ${observation.description}");

    selectedObservationType = observation.observationType;
    selectedObservationTypeId = observation.observationTypeID;
    selectedIssueType = observation.issueType ?? '';
    isDraftObservation = observation.statusID == SiteObservationStatus.Draft;

    await fetchIssueTypes();

    final foundIssue = issueTypes.firstWhere(
      (e) => e.name == selectedIssueType,
      orElse: () => IssueType(id: 0, name: '', observationTypeID: 0),
    );
    selectedIssueTypeId = foundIssue.id;
    selectedIssueType = foundIssue.name;

    setState(() {});

    if (selectedIssueTypeId != 0) {
      await fetchObservations();
    } else {
      observationsList = [];
      selectedObservation = null;
      setState(() {});
      return;
    }

    final foundObs = observationsList.firstWhere(
      (o) => o.observationDescription == observation.description,
      orElse: () => Observation(
        id: 0,
        observationTypeID: 0,
        issueTypeID: 0,
        observationDescription: '',
        complianceRequired: false,
        escalationRequired: false,
        dueTimeInHrs: 0,
        actionToBeTaken: '',
        lastModifiedBy: '',
        lastModifiedDate: DateTime.now().toIso8601String(),
      ),
    );

    if (isDraftObservation) {
      selectedObservation = observation.description;
      observationDescriptionController.text = observation.description;
      isComplianceRequired = observation.complianceRequired ?? false;
      isEscalationRequired = observation.escalationRequired ?? false;
      actionToBeTakenController.text = observation.actionToBeTaken ?? '';
    } else if (foundObs.id != 0) {
      selectedObservation = foundObs.observationDescription;
      observationDescriptionController.text = foundObs.observationDescription;
      isComplianceRequired = foundObs.complianceRequired;
      isEscalationRequired = foundObs.escalationRequired;
      actionToBeTakenController.text = foundObs.actionToBeTaken ?? '';
    }

    // ✅ Due Date Calculation Fix
    try {
      DateTime startDate;

      if (_dateController.text.isNotEmpty) {
        startDate = DateFormat('yyyy-MM-dd HH:mm').parse(_dateController.text);
      } else {
        final createdDate = observation.activityDTO.isNotEmpty
            ? observation.activityDTO.last.createdDate
            : null;

        startDate =
            (createdDate ?? DateTime.now()).toLocal(); // ✅ Convert to local
        _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(startDate);
      }

      int? hoursToAdd;

      if (isDraftObservation) {
        if (observation.dueDate != null) {
          DateTime dueDate =
              observation.dueDate!.toLocal(); // ✅ Convert to local
          _dateDueDateController.text =
              DateFormat("yyyy-MM-dd HH:mm").format(dueDate);

          hoursToAdd = dueDate.difference(startDate).inHours;
        } else {
          hoursToAdd = foundObs.dueTimeInHrs;
        }
      } else {
        hoursToAdd = foundObs.dueTimeInHrs;
      }

      if (observation.dueDate == null &&
          hoursToAdd != null &&
          hoursToAdd != 0) {
        final dueDate = startDate.add(Duration(hours: hoursToAdd));
        _dateDueDateController.text =
            DateFormat("yyyy-MM-dd HH:mm").format(dueDate);
      }
    } catch (e) {
      print("⚠️ Date calculation error: $e");
      _dateDueDateController.text = '';
    }

    print("Due Date: ${_dateDueDateController.text}");

    final isGoodPractice =
        foundObs.observationTypeID == goodPracticeObservationTypeId;

    if (isGoodPractice) {
      _dateDueDateController.text = '';
    }

    selectedActivities = observation.activityName;

    final observedName = observation.observedByName ?? '';
    final matchedObservedBy = ObservationConstants.observedBy.firstWhere(
      (item) =>
          (item['observedBy'] as String).toLowerCase() ==
          observedName.toLowerCase(),
      orElse: () => const {"id": 0, "observedBy": ""},
    );
    observedById =
        matchedObservedBy['id'] is int ? matchedObservedBy['id'] as int : 0;

    selectedArea = observation.sectionName;
    selectedFloor = observation.floorName;
    selectedPart = observation.partName;
    selectedElement = observation.elementName;
    selectedContractor = observation.contractorName;

    final fetchedUsers = await fetchUserList();
    userList = fetchedUsers;
    final assignedUsernames = observation.assignmentStatusDTO
        .map((e) => e.assignedUserName?.trim().toLowerCase())
        .where((name) => name != null && name.isNotEmpty)
        .toSet();

    selectedUserObjects = userList.where((user) {
      final userName = user.userName.trim().toLowerCase();
      return assignedUsernames.contains(userName);
    }).toList();
    selectedUsers = selectedUserObjects.map((u) => u.userName).toList();

    uploadedFiles = observation.activityDTO
        .where((a) => a.documentName != null && a.documentName!.isNotEmpty)
        .map((a) => a.documentName!)
        .toList();
    if (uploadedFiles.isNotEmpty) {
      selectedFileName = uploadedFiles.first;
    }

    activityDTOList = observation.activityDTO;
    debugPrint(const JsonEncoder.withIndent('  ').convert(activityDTOList));
    populateActivityListFromDTO(activityDTOList);

    setState(() {
      selectedObservationId = observation.id;
      isUserSelectionEnabled = observation.observationTypeID != 1;
    });
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
      selectedActivities = null;
      selectedArea = null;
      selectedFloor = null;
      selectedPart = null;
      selectedElement = null;
      selectedContractor = null;
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

  // void populateActivityListFromDTO(
  //     GetSiteObservationMasterById observation) async {
  //   int statusIdToSend = isDraft
  //       ? SiteObservationStatus.Draft
  //       : (selectedObservationTypeId == 1
  //           ? SiteObservationStatus.Closed
  //           : SiteObservationStatus.Open);
  //   int? userID = await SharedPrefsHelper.getUserId();
  //   if (userID == null || userID == 0) return;
  //   final fileActivities = observation.activityDTO
  //       .where((a) => a.documentName != null && a.documentName!.isNotEmpty)
  //       .map((a) => SiteObservationActivity(
  //             id: a.id ?? 0,
  //             siteObservationID: a.siteObservationID,
  //             actionID: a.actionID ?? 0,
  //             comments: a.comments ?? '',
  //             documentName: a.documentName ?? '',
  //             fileName: a.fileName,
  //             fileContentType: a.fileContentType,
  //             filePath: a.filePath,
  //             fromStatusID: statusIdToSend,
  //             toStatusID: statusIdToSend,
  //             assignedUserID: userID,
  //             createdBy: int.tryParse(a.createdBy ?? '0') ?? 0,
  //             createdDate: a.createdDate is DateTime
  //                 ? formatDateForApi(a.createdDate as DateTime)
  //                 : (a.createdDate != null ? a.createdDate.toString() : ''),
  //           ))
  //       .toList();
  //   print("File Activities: ${observation.activityDTO}");
  //   setState(() {
  //     // ⛔️ Don’t clear, just merge without duplicating
  //     for (var activity in fileActivities) {
  //       if (!activityList.any((a) =>
  //           a.id == activity.id && a.documentName == activity.documentName)) {
  //         activityList.add(activity);
  //       }
  //     }
  //     uploadedFiles = activityList
  //         .where((e) => e.documentName.isNotEmpty)
  //         .map((e) => e.documentName)
  //         .toList();
  //     if (uploadedFiles.isNotEmpty) {
  //       selectedFileName = uploadedFiles.first;
  //     }
  //   });
  // }
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
                                                // 🔴 Show read-only data inside popup
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text(
                                                        'Observation Details (View Only)'),
                                                    content:
                                                        SingleChildScrollView(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          _popupRow(
                                                              "Observation Code",
                                                              observation
                                                                  .siteObservationCode),
                                                          _popupRow(
                                                              "Observation Type",
                                                              observation
                                                                  .observationType),
                                                          _popupRow(
                                                              "Issue Type",
                                                              observation
                                                                  .issueType),
                                                          _popupRow(
                                                              "Status",
                                                              observation
                                                                  .observationStatus),
                                                          _popupRow(
                                                              "Project",
                                                              observation
                                                                  .projectName),
                                                          _popupRow(
                                                              "Date",
                                                              observation
                                                                  .transactionDate
                                                                  .toString()
                                                                  .split(
                                                                      " ")[0]),
                                                          _popupRow(
                                                              "Due Date",
                                                              observation
                                                                  .dueDate
                                                                  .toString()
                                                                  .split(
                                                                      " ")[0]),
                                                          _popupRow(
                                                              "Compliance Required",
                                                              observation
                                                                      .compliancerequired
                                                                  ? 'Yes'
                                                                  : 'No'),
                                                          _popupRow(
                                                              "Escalation Required",
                                                              observation
                                                                      .escalationrequired
                                                                  ? 'Yes'
                                                                  : 'No'),
                                                          _popupRow(
                                                              "Description",
                                                              observation
                                                                  .observationDescription),
                                                          // Aur bhi fields chahiye to add kar lo
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(),
                                                        child: Text('Close'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                            },
                                            child: Card(
                                              color: isDark
                                                  ? Colors.grey[900]
                                                  : Colors.white,
                                              elevation: 0,
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
                                                    Wrap(
                                                      spacing: 16,
                                                      runSpacing: 12,
                                                      children: [
                                                        _infoBox(
                                                            "ObservationType",
                                                            observation
                                                                .observationType,
                                                            isDark: isDark),
                                                        _infoBox(
                                                            "IssueType",
                                                            observation
                                                                .issueType,
                                                            isDark: isDark),
                                                        _infoBox(
                                                            "Status",
                                                            observation
                                                                .observationStatus,
                                                            isDark: isDark),
                                                        _infoBox(
                                                            "Project",
                                                            observation
                                                                .projectName,
                                                            isDark: isDark),
                                                        _infoBox(
                                                          "Date",
                                                          observation
                                                              .transactionDate
                                                              .toLocal()
                                                              .toString()
                                                              .split(' ')[0],
                                                          isDark: isDark,
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
                                                      ? () {
                                                          _selectDate(context,
                                                              _dateController); // Allow changing Start Date
                                                        }
                                                      : null,
                                                ),
                                              ),
                                              readOnly: true,
                                            ),

                                            SizedBox(height: 20),
                                            // Dropdown for Select observation
                                            // DropdownButtonFormField<String>(
                                            //   value: selectedObservationType,
                                            //   onChanged: isEditMode
                                            //       ? null
                                            //       : (String? newValue) {
                                            //           setState(() {
                                            //             selectedObservationType =
                                            //                 newValue;
                                            //             final selected =
                                            //                 observationTypeList
                                            //                     .firstWhereOrNull(
                                            //                         (e) =>
                                            //                             e.name ==
                                            //                             newValue);
                                            //             if (selected != null) {
                                            //               selectedObservationTypeId =
                                            //                   selected.id;
                                            //               if (selected.id ==
                                            //                   1) {
                                            //                 isUserSelectionEnabled =
                                            //                     false;
                                            //                 actionToBeTakenEnabled =
                                            //                     false;
                                            //                 selectedUsers
                                            //                     .clear(); // Optionally clear users
                                            //               } else {
                                            //                 isUserSelectionEnabled =
                                            //                     true;
                                            //                 actionToBeTakenEnabled =
                                            //                     true;
                                            //               }
                                            //               fetchIssueTypes();
                                            //             } else {
                                            //               selectedObservationTypeId =
                                            //                   0;
                                            //               issueTypes = [];
                                            //             }
                                            //             selectedIssueType =
                                            //                 null;
                                            //             selectedIssueTypeId = 0;
                                            //             selectedObservation =
                                            //                 null;
                                            //             observationsList = [];
                                            //             issueTypes = [];
                                            //             observationDescriptionController
                                            //                 .text = '';
                                            //             _dateDueDateController
                                            //                 .text = '';
                                            //             isComplianceRequired =
                                            //                 false;
                                            //             isEscalationRequired =
                                            //                 false;
                                            //             actionToBeTakenController
                                            //                 .text = '';
                                            //           });
                                            //         },
                                            //   decoration: InputDecoration(
                                            //     labelText: 'Observation Type',
                                            //     border: OutlineInputBorder(),
                                            //   ),
                                            //   validator:
                                            //       _validateObservationType,
                                            //   items: observationTypeList
                                            //       .map((observationType) {
                                            //     return DropdownMenuItem<String>(
                                            //       value: observationType.name,
                                            //       child: Text(
                                            //           observationType.name),
                                            //     );
                                            //   }).toList(),
                                            // ),
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
                                                          if (isEditMode) {
                                                            if (selected.id ==
                                                                1) {
                                                              isUserSelectionEnabled =
                                                                  false;
                                                              actionToBeTakenEnabled =
                                                                  false;
                                                              selectedUsers
                                                                  .clear();
                                                            } else {
                                                              isUserSelectionEnabled =
                                                                  true;
                                                              actionToBeTakenEnabled =
                                                                  true;
                                                            }
                                                          }
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

                                            DropdownButtonFormField<String>(
                                              value: issueTypes.any((e) =>
                                                      e.name ==
                                                      selectedIssueType)
                                                  ? selectedIssueType
                                                  : null,
                                              onChanged: (!isDraftObservation &&
                                                      isEditMode)
                                                  ? (String? newValue) {
                                                      setState(() {
                                                        selectedIssueType =
                                                            newValue;

                                                        try {
                                                          final selectedIssue =
                                                              issueTypes
                                                                  .firstWhere(
                                                            (element) =>
                                                                element.name ==
                                                                newValue,
                                                          );
                                                          selectedIssueTypeId =
                                                              selectedIssue.id;
                                                          // bool isNCRSelected =
                                                          //     selectedIssue
                                                          //                 .id ==
                                                          //             1 &&
                                                          //         selectedIssue
                                                          //                 .name ==
                                                          //             'NCR';

                                                          // // 🔁 Enable/Disable fields
                                                          // isDueDateEnabled =
                                                          //     !isNCRSelected;
                                                          // isToggleEnabled =
                                                          //     !isNCRSelected;
                                                          fetchObservations();
                                                        } catch (e) {
                                                          selectedIssueTypeId =
                                                              0;
                                                          observationsList = [];
                                                          selectedObservation =
                                                              null;
                                                        }
                                                      });
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
                                            // Dropdown for Select Observation
                                            DropdownButtonFormField<String>(
                                              value: (selectedObservation !=
                                                          null &&
                                                      selectedObservation!
                                                          .isNotEmpty &&
                                                      observationsList.any((obs) =>
                                                          obs.observationDescription ==
                                                          selectedObservation))
                                                  ? selectedObservation
                                                  : null,
                                              onChanged: (!isDraftObservation &&
                                                      isEditMode)
                                                  ? (selectedIssueTypeId ==
                                                              null ||
                                                          selectedIssueTypeId ==
                                                              0)
                                                      ? null
                                                      : (String? newValue) {
                                                          setState(() {
                                                            selectedObservation =
                                                                newValue ?? '';

                                                            final selected =
                                                                observationsList
                                                                    .firstWhere(
                                                              (obs) =>
                                                                  obs.observationDescription ==
                                                                  selectedObservation,
                                                              orElse: () =>
                                                                  Observation(
                                                                id: 0,
                                                                observationTypeID:
                                                                    0,
                                                                issueTypeID: 0,
                                                                observationDescription:
                                                                    '',
                                                                complianceRequired:
                                                                    false,
                                                                escalationRequired:
                                                                    false,
                                                                dueTimeInHrs: 0,
                                                                actionToBeTaken:
                                                                    '',
                                                                lastModifiedBy:
                                                                    '',
                                                                lastModifiedDate:
                                                                    DateTime.now()
                                                                        .toIso8601String(),
                                                              ),
                                                            );

                                                            observationDescriptionController
                                                                    .text =
                                                                selected
                                                                    .observationDescription;
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

                                                            // Due date calculation example
                                                            if (_dateController
                                                                    .text
                                                                    .isNotEmpty &&
                                                                selected.dueTimeInHrs !=
                                                                    null &&
                                                                selected.dueTimeInHrs !=
                                                                    0) {
                                                              try {
                                                                DateTime
                                                                    startDate =
                                                                    DateFormat(
                                                                            'yyyy-MM-dd HH:mm')
                                                                        .parse(_dateController
                                                                            .text);
                                                                DateTime
                                                                    dueDate =
                                                                    startDate.add(Duration(
                                                                        hours: selected
                                                                            .dueTimeInHrs
                                                                            .floor()));
                                                                String
                                                                    formattedDueDate =
                                                                    DateFormat(
                                                                            'yyyy-MM-dd HH:mm')
                                                                        .format(
                                                                            dueDate);
                                                                _dateDueDateController
                                                                        .text =
                                                                    formattedDueDate;
                                                              } catch (e) {
                                                                _dateDueDateController
                                                                    .text = '';
                                                              }
                                                            } else {
                                                              _dateDueDateController
                                                                  .text = '';
                                                            }
                                                          });
                                                        }
                                                  : null,
                                              decoration: const InputDecoration(
                                                labelText: 'Select Observation',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if ((selectedIssueTypeId ==
                                                            null ||
                                                        selectedIssueTypeId ==
                                                            0) ||
                                                    value == null ||
                                                    value.isEmpty) {
                                                  return 'Please select an observation';
                                                }
                                                return null;
                                              },
                                              items: (selectedIssueTypeId ==
                                                          null ||
                                                      selectedIssueTypeId == 0)
                                                  ? []
                                                  : [
                                                      const DropdownMenuItem<
                                                          String>(
                                                        value: '',
                                                        child: Text(
                                                          'Select Observation',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.grey),
                                                        ),
                                                      ),
                                                      ...observationsList
                                                          .map((observation) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: observation
                                                              .observationDescription,
                                                          child: Text(
                                                            observation
                                                                .observationDescription,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ],
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
                                                        _dateDueDateController);
                                                  },
                                                ),
                                              ),
                                              readOnly: true,
                                              // validator: _validateDueDate,
                                            ),
                                            SizedBox(height: 20),
                                            // Row(
                                            //   mainAxisAlignment:
                                            //       MainAxisAlignment
                                            //           .spaceBetween,
                                            //   children: [
                                            //     // **Compliance Required** Toggle Switch
                                            //     Expanded(
                                            //       child: Row(
                                            //         mainAxisAlignment:
                                            //             MainAxisAlignment.start,
                                            //         children: [
                                            //           Text(
                                            //               "Compliance Required"),
                                            //           Switch(
                                            //             value:
                                            //                 isComplianceRequired,
                                            //             onChanged: isToggleEnabled
                                            //                 ? (bool value) {
                                            //                     setState(() {
                                            //                       isComplianceRequired =
                                            //                           value;
                                            //                     });
                                            //                   }
                                            //                 : null, // disables switch when observation is selected
                                            //           ),
                                            //         ],
                                            //       ),
                                            //     ),

                                            //     // **Escalation Required** Toggle Switch
                                            //     Expanded(
                                            //       child: Row(
                                            //         mainAxisAlignment:
                                            //             MainAxisAlignment.start,
                                            //         children: [
                                            //           Text(
                                            //               "Escalation Required"),
                                            //           Switch(
                                            //             value:
                                            //                 isEscalationRequired,
                                            //             onChanged:
                                            //                 isToggleEnabled
                                            //                     ? (bool value) {
                                            //                         setState(
                                            //                             () {
                                            //                           isEscalationRequired =
                                            //                               value;
                                            //                         });
                                            //                       }
                                            //                     : null,
                                            //           ),
                                            //         ],
                                            //       ),
                                            //     ),
                                            //   ],
                                            // ),
                                            _buildToggleSwitches(context),

                                            SizedBox(height: 20),
                                            DropdownButtonFormField<String>(
                                              value:
                                                  selectedActivities, // This will bind to selectedActivities
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedActivities = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Select Activity',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator:
                                                  _validateActivity, // Your validation function if needed
                                              items: activitieList
                                                  .map((Activities activity) {
                                                return DropdownMenuItem<String>(
                                                  value: activity.activityName,
                                                  child: Text(
                                                      activity.activityName),
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

                                            // SizedBox(height: 20),
                                            // TextFormField(
                                            //   controller:
                                            //       userDescriptionController,
                                            //   decoration: InputDecoration(
                                            //     labelText: 'User Description',
                                            //     border: OutlineInputBorder(
                                            //       borderRadius:
                                            //           BorderRadius.circular(8),
                                            //     ),
                                            //   ),
                                            //   validator: _validateUser,
                                            // ),

                                            SizedBox(height: 20),
                                            DropdownButtonFormField<String>(
                                              value: selectedArea,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedArea = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Choose Area',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: _validateArea,
                                              items:
                                                  areaList.map((Area areaList) {
                                                return DropdownMenuItem<String>(
                                                  value: areaList.sectionName,
                                                  child: Text(
                                                      areaList.sectionName),
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 20),
                                            // Dropdown for Select Floor
                                            DropdownButtonFormField<String>(
                                              value: selectedFloor,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedFloor = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Choose Floor',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: _validateFloor,
                                              items: floorList
                                                  .map((Floor floorList) {
                                                return DropdownMenuItem<String>(
                                                  value: floorList.floorName,
                                                  child:
                                                      Text(floorList.floorName),
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 20),
                                            // Dropdown for Select Part

                                            DropdownButtonFormField<String>(
                                              value: selectedPart,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedPart = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Choose Part',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: _validatePart,
                                              items:
                                                  partList.map((Part partList) {
                                                return DropdownMenuItem<String>(
                                                  value: partList.partName,
                                                  child:
                                                      Text(partList.partName),
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 20),
                                            // Dropdown for Select Element
                                            DropdownButtonFormField<String>(
                                              value: selectedElement,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedElement = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Element Name',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: _validateElement,
                                              items: elementList
                                                  .map((Elements elementList) {
                                                return DropdownMenuItem<String>(
                                                  value:
                                                      elementList.elementName,
                                                  child: Text(
                                                      elementList.elementName),
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 20),
                                            // Dropdown for Select Contractor Name
                                            DropdownButtonFormField<String>(
                                              value: selectedContractor,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedContractor = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Contractor Name',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: _validateContractor,
                                              items: ContractorList.map<
                                                      DropdownMenuItem<String>>(
                                                  (Party contractor) {
                                                return DropdownMenuItem<String>(
                                                  value: contractor
                                                      .partyName, // Ensure this is a String
                                                  child: Text(
                                                      contractor.partyName),
                                                );
                                              }).toList(),
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
                                                    User>(
                                                  items: userList
                                                      .map((user) =>
                                                          MultiSelectItem<User>(
                                                              user,
                                                              user.userName))
                                                      .toList(),
                                                  initialValue:
                                                      selectedUserObjects,
                                                  title: Text("Assigned To"),
                                                  selectedItemsTextStyle:
                                                      TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                  itemsTextStyle:
                                                      TextStyle(fontSize: 16),
                                                  searchable: true,
                                                  buttonText:
                                                      Text("Select Users"),
                                                  onConfirm:
                                                      (List<User> selected) {
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
                                                    onTap: (User user) {
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
                                            // MultiSelectDialogField<User>(
                                            //   items: userList
                                            //       .map((user) =>
                                            //           MultiSelectItem<User>(
                                            //               user, user.userName))
                                            //       .toList(),

                                            //   // ✅ prefill selection here
                                            //   initialValue: selectedUserObjects,

                                            //   title: Text("Assigned To"),
                                            //   searchable: true,
                                            //   buttonText: Text("Select Users"),
                                            //   onConfirm: (List<User> selected) {
                                            //     setState(() {
                                            //       selectedUserObjects =
                                            //           selected;
                                            //       selectedUsers = selected
                                            //           .map((u) => u.userName)
                                            //           .toList();
                                            //     });
                                            //   },
                                            //   chipDisplay:
                                            //       MultiSelectChipDisplay(
                                            //     onTap: (user) {
                                            //       setState(() {
                                            //         selectedUserObjects
                                            //             .remove(user);
                                            //         selectedUsers
                                            //             .remove(user.userName);
                                            //       });
                                            //     },
                                            //   ),
                                            //   decoration: BoxDecoration(
                                            //     border: Border.all(
                                            //         color: Colors.grey),
                                            //     borderRadius:
                                            //         BorderRadius.circular(4),
                                            //   ),
                                            // ),

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
                                                  for (var name
                                                      in uploadedFiles)
                                                    Text("📄 $name",
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.green)),
                                                ],
                                              ],
                                            ),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      if (_formKey.currentState
                                                              ?.validate() ??
                                                          false) {
                                                        _submitForm(
                                                            isDraft: true);
                                                      }
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.grey,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child:
                                                        Text('Save as Draft'),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      if (_formKey.currentState
                                                              ?.validate() ??
                                                          false) {
                                                        _submitForm(
                                                            isDraft: false);
                                                      }
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blue,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child: Text('Submit'),
                                                  ),
                                                ),
                                              ],
                                            )
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
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      if (!showObservations) {
                        // We're on form, going back to list → reset the form
                        _resetForm();
                        isEditMode = false;
                        isDraftObservation = false;
                      } else {
                        isEditMode = true;
                        isDraftObservation = false;
                        _dateController.text = DateFormat('yyyy-MM-dd HH:mm')
                            .format(DateTime.now());
                      }
                      showObservations = !showObservations;
                    });
                  },
                  child: Icon(showObservations ? Icons.add : Icons.list),
                  backgroundColor: Colors.blue,
                ),
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

Widget _popupRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
