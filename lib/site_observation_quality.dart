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
  List<MultiSelectItem<User>> userItems = [];

  bool isComplianceRequired = false; // Compliance toggle state
  bool isEscalationRequired = false; // Escalation toggle state

  List<SiteObservationActivity> activityList = [];

  TextEditingController observationDescriptionController =
      TextEditingController();
  TextEditingController userDescriptionController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _initializeData();
    userItems = userList
        .map((user) => MultiSelectItem<User>(user, user.userName))
        .toList();
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

    _dateController.text =
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()); // Local time
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
      print('Error: Company ID is null');
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
      print('Error: Company ID is null');
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

  // Fetch User List from the service
  Future<void> fetchUserList() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<User> fetchedUsers =
          await widget._siteObservationService.fetchUserList();
      List<User> uniqueUsers = [];
      Set<String> userNames = {};
      for (var user in fetchedUsers) {
        if (!userNames.contains(user.userName)) {
          uniqueUsers.add(user);
          userNames.add(user.userName);
        }
      }
      setState(() {
        userList = uniqueUsers;
      });
    } catch (e) {
      print('Error fetching User: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submitting...')),
      );
      await submitForm(); // 👈 Your actual async method
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please correct the errors')),
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
    print("Fetching site observations for project ID: $projectId");
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

  String? _validateUser(String? value) {
    if (value == null || value.isEmpty) {
      return 'User Description is required';
    }
    return null;
  }

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

  void onFileUploadSuccess(String uploadedFileName) async {
    int? userID = await SharedPrefsHelper.getUserId();

    activityList.add(
      SiteObservationActivity(
        id: 0,
        siteObservationID: null,
        actionID: SiteObservationActions.DocUploaded,
        comments: '',
        documentName: uploadedFileName,
        fromStatusID: SiteObservationStatus.Open,
        toStatusID: SiteObservationStatus.Open,
        assignedUserID: userID!,
        createdBy: userID,
        createdDate: formatDateForApi(DateTime.now()),
      ),
    );
  }

  // Function to submit the form data
  Future<void> submitForm() async {
    String observationDescription = observationDescriptionController.text;
    String userDescription = userDescriptionController.text;
    String actionToBeTaken =
        actionToBeTakenController.text; // Add this line to get the action text
    int? projectID = await SharedPrefsHelper.getProjectID();
    int? companyID = await SharedPrefsHelper.getCompanyId();
    int? userID = await SharedPrefsHelper.getUserId();
    final selectedObservedBy = ObservationConstants.observedBy.firstWhere(
        (item) => item['id'] == observedById,
        orElse: () => {"id": 0, "observedBy": ""})['id'] as int;

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
    // For Creator
    activityList.add(
      SiteObservationActivity(
        id: 0,
        siteObservationID: null,
        actionID: SiteObservationActions.Created,
        comments: '',
        documentName: "",
        fromStatusID: SiteObservationStatus.Open,
        toStatusID: SiteObservationStatus.Open,
        assignedUserID: userID!, // creator ka ID
        createdBy: userID,
        createdDate: formatDateForApi(DateTime.now()),
      ),
    );

// For Assigned Users
    for (var username in selectedUsers) {
      final user = userList.firstWhere((u) => u.userName == username);
      activityList.add(
        SiteObservationActivity(
          id: 0,
          siteObservationID: null,
          actionID: SiteObservationActions.Assigned,
          comments: '',
          documentName: '',
          fromStatusID: SiteObservationStatus.Open,
          toStatusID: SiteObservationStatus.Open,
          assignedUserID: user.id,
          createdBy: userID,
          createdDate: formatDateForApi(DateTime.now()),
        ),
      );
    }

    SiteObservationModel siteObservation = SiteObservationModel(
      uniqueID: const Uuid().v4(),
      id: 0,
      siteObservationCode: "",
      trancationDate: formatDateForApi(DateTime.now().toUtc()),
      observationRaisedBy: userID!,
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
      userDescription: userDescription, // You can add more fields
      complianceRequired: isComplianceRequired,
      escalationRequired: isEscalationRequired,
      actionToBeTaken: actionToBeTaken,
      companyID: companyID!,
      projectID: projectID!,
      functionID: ScreenTypes.Quality,
      activityID: activitieList
          .firstWhere(
              (activities) => activities.activityName == selectedActivities)
          .id,
      observedBy: selectedObservedBy,
      sectionID:
          areaList.firstWhere((area) => area.sectionName == selectedArea).id,
      floorID:
          floorList.firstWhere((floor) => floor.floorName == selectedFloor).id,
      partID: partList.firstWhere((part) => part.partName == selectedPart).id,
      elementID: elementList
          .firstWhere((element) => element.elementName == selectedElement)
          .id,
      contractorID: ContractorList.firstWhere(
          (contractor) => contractor.partyName == selectedContractor).id,
      reworkCost: double.tryParse(reworkCostController.text) ?? 0.0,
      comments: 'string',
      rootCauseID: 0,
      corretiveActionToBeTaken: 'Corrective action here',
      preventiveActionTaken: 'Preventive action here',
      statusID: SiteObservationStatus.Open,
      isActive: true,
      createdBy: userID,
      createdDate: formatDateForApi(DateTime.now().toUtc()),
      lastModifiedBy: userID,
      lastModifiedDate: formatDateForApi(DateTime.now().toUtc()),
      siteObservationActivity: activityList,
    );

    try {
      bool success = await widget._siteObservationService
          .submitSiteObservation(siteObservation);

      if (success) {
        _resetForm(); // ⬅️ Reset form here
        setState(() {
          showObservations = true; // 👈 Form hide
        });
        await fetchSiteObservationsQuality(projectID);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Operation Successful')),
        );
      } else {
        // Optional: for boolean false without exception
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Submission failed without specific error')),
        );
      }
    } catch (e) {
      // 👇 This will now show backend error like "Please Map RootCause with Activity"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString().replaceAll('"', '')}')),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();

    setState(() {
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
      reworkCostController.clear();
      observationDescriptionController.clear();
      userDescriptionController.clear();
      uploadedFiles.clear();
      selectedFileName = null;
      isComplianceRequired = false;
      isEscalationRequired = false;
      _dateDueDateController.clear();
      observedById = null;
      observationsList = [];
      issueTypes = [];
      selectedUsers = [];
      activityList = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!showObservations) {
          // 👇 Reset form values
          _resetForm();

          // 👇 Switch back to observations list
          setState(() {
            showObservations = true;
          });
          return false;
        }
        return true; // Default: allow back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Site Observation - Safety'),
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
                      print(
                        "Selected Project: ${newProject.name} (ID: ${newProject.id})",
                      );
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

                                          return Card(
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
                                                      _infoBox("IssueType",
                                                          observation.issueType,
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
                                                  onPressed: () {
                                                    _selectDate(context,
                                                        _dateController); // Allow changing Start Date
                                                  },
                                                ),
                                              ),
                                              readOnly: true,
                                            ),

                                            SizedBox(height: 20),
                                            // Dropdown for Select observation
                                            DropdownButtonFormField<String>(
                                              value: selectedObservationType,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedObservationType =
                                                      newValue;
                                                  final selected =
                                                      observationTypeList
                                                          .firstWhereOrNull(
                                                              (e) =>
                                                                  e.name ==
                                                                  newValue);
                                                  if (selected != null) {
                                                    selectedObservationTypeId =
                                                        selected.id;
                                                    fetchIssueTypes();
                                                  } else {
                                                    selectedObservationTypeId =
                                                        0;
                                                    issueTypes = [];
                                                  }
                                                  selectedIssueType = null;
                                                  selectedIssueTypeId = 0;
                                                  selectedObservation = null;
                                                  observationsList = [];
                                                  issueTypes = [];
                                                  observationDescriptionController
                                                      .text = '';
                                                  _dateDueDateController.text =
                                                      '';
                                                  isComplianceRequired = false;
                                                  isEscalationRequired = false;
                                                });
                                              },
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
                                            // Dropdown for Select Issue Type
                                            DropdownButtonFormField<String>(
                                              value: issueTypes.any((e) =>
                                                      e.name ==
                                                      selectedIssueType)
                                                  ? selectedIssueType
                                                  : null,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedIssueType = newValue;

                                                  try {
                                                    final selectedIssue =
                                                        issueTypes.firstWhere(
                                                      (element) =>
                                                          element.name ==
                                                          newValue,
                                                    );
                                                    selectedIssueTypeId =
                                                        selectedIssue.id;
                                                    fetchObservations();
                                                  } catch (e) {
                                                    selectedIssueTypeId = 0;
                                                    observationsList = [];
                                                    selectedObservation = null;
                                                  }
                                                });
                                              },
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
                                              value: (selectedObservation ?? '')
                                                          .isEmpty ||
                                                      !observationsList.any((obs) =>
                                                          obs.observationDescription ==
                                                          selectedObservation)
                                                  ? null
                                                  : selectedObservation,
                                              onChanged: (selectedIssueTypeId ==
                                                          null ||
                                                      selectedIssueTypeId == 0)
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
                                                            actionToBeTaken: '',
                                                            lastModifiedBy: '',
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
                                                        // Calculate due date based on start date and dueTimeInHrs
                                                        if (_dateController.text
                                                                .isNotEmpty &&
                                                            selected.dueTimeInHrs !=
                                                                null &&
                                                            selected.dueTimeInHrs !=
                                                                0) {
                                                          if (selectedIssueTypeId !=
                                                              3) {
                                                            try {
                                                              // Parse startDate from input (assume it's in local time)
                                                              DateTime
                                                                  startDate =
                                                                  DateFormat(
                                                                          'yyyy-MM-dd HH:mm')
                                                                      .parse(_dateController
                                                                          .text);

                                                              // Add due hours
                                                              DateTime dueDate =
                                                                  startDate.add(Duration(
                                                                      hours: selected
                                                                          .dueTimeInHrs
                                                                          .floor()));

                                                              // Convert to local datetime string like 'yyyy-MM-ddTHH:mm'
                                                              String
                                                                  formattedDueDate =
                                                                  DateFormat(
                                                                          "yyyy-MM-dd HH:mm")
                                                                      .format(dueDate
                                                                          .toUtc());

                                                              // Set this string to the controller
                                                              _dateDueDateController
                                                                      .text =
                                                                  formattedDueDate;
                                                            } catch (e) {
                                                              print(
                                                                  "Date parse or calculation error: $e");
                                                              _dateDueDateController
                                                                  .text = '';
                                                            }
                                                          } else {
                                                            _dateDueDateController
                                                                .text = '';
                                                          }
                                                        } else {
                                                          // If no start date or no due time, clear due date
                                                          _dateDueDateController
                                                              .text = '';
                                                        }
                                                      });
                                                    },
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
                                                                color: Colors
                                                                    .grey)),
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
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // **Compliance Required** Toggle Switch
                                                Expanded(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                          "Compliance Required"),
                                                      Switch(
                                                        value:
                                                            isComplianceRequired,
                                                        onChanged: isToggleEnabled
                                                            ? (bool value) {
                                                                setState(() {
                                                                  isComplianceRequired =
                                                                      value;
                                                                });
                                                              }
                                                            : null, // disables switch when observation is selected
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // **Escalation Required** Toggle Switch
                                                Expanded(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                          "Escalation Required"),
                                                      Switch(
                                                        value:
                                                            isEscalationRequired,
                                                        onChanged:
                                                            isToggleEnabled
                                                                ? (bool value) {
                                                                    setState(
                                                                        () {
                                                                      isEscalationRequired =
                                                                          value;
                                                                    });
                                                                  }
                                                                : null,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

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

                                            SizedBox(height: 20),
                                            TextFormField(
                                              controller:
                                                  userDescriptionController,
                                              decoration: InputDecoration(
                                                labelText: 'User Description',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              validator: _validateUser,
                                            ),

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
                                            MultiSelectDialogField<User>(
                                              items: userList
                                                  .map((user) =>
                                                      MultiSelectItem<User>(
                                                          user, user.userName))
                                                  .toList(),
                                              title: Text("Assigned To"),
                                              selectedItemsTextStyle: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              itemsTextStyle:
                                                  TextStyle(fontSize: 16),
                                              searchable: true,
                                              buttonText: Text("Select Users"),
                                              onConfirm: (List<User> selected) {
                                                setState(() {
                                                  selectedUsers = selected
                                                      .map((u) => u.userName)
                                                      .toList(); // ✅ Strings only
                                                });
                                              },
                                              chipDisplay:
                                                  MultiSelectChipDisplay(
                                                onTap: (user) {
                                                  setState(() {
                                                    selectedUsers.remove(
                                                        user); // ✅ Remove full User object
                                                  });
                                                },
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                              validator: _validateDescription,
                                            ),

                                            SizedBox(height: 10),
                                            TextFormField(
                                              controller: reworkCostController,
                                              keyboardType: TextInputType
                                                  .number, // Allow only number input
                                              decoration: InputDecoration(
                                                labelText: 'Rework Cost',
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty)
                                                  return 'Please enter rework cost';
                                                if (double.tryParse(value) ==
                                                    null)
                                                  return 'Enter valid number';
                                                return null;
                                              },
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

                                                        setState(() {
                                                          selectedFileName =
                                                              file.name;
                                                          isUploading = true;
                                                        });

                                                        final uploadedFileName =
                                                            await SiteObservationService()
                                                                .uploadFileAndGetFileName(
                                                                    file.name,
                                                                    file.bytes!);

                                                        setState(() {
                                                          isUploading = false;
                                                        });

                                                        if (uploadedFileName !=
                                                            null) {
                                                          setState(() {
                                                            uploadedFiles.add(
                                                                uploadedFileName);
                                                          });

                                                          onFileUploadSuccess(
                                                              uploadedFileName);
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    "❌ File upload failed")),
                                                          );
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

                                            ElevatedButton(
                                              onPressed: () {
                                                if (_formKey.currentState
                                                        ?.validate() ??
                                                    false) {
                                                  _submitForm();
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text('Submit'),
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
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      if (!showObservations) {
                        // We're on form, going back to list → reset the form
                        _resetForm();
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
      // No background color, so it stays transparent and matches card bg
      // color: Colors.transparent, // optional, can keep or remove color property
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
