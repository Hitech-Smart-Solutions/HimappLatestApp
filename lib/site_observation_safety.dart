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

class SiteObservationSafety extends StatefulWidget {
  final String companyName;
  final ProjectService _projectService;
  final SiteObservationService _siteObservationService;

  const SiteObservationSafety({
    super.key,
    required this.companyName,
    required ProjectService projectService,
    required SiteObservationService siteObservationService,
  })  : _projectService = projectService,
        _siteObservationService = siteObservationService;

  @override
  _SiteObservationState createState() => _SiteObservationState();
}

class _SiteObservationState extends State<SiteObservationSafety> {
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

  String? selectedUser;
  List<User> userList = [];

  bool isComplianceRequired = false; // Compliance toggle state
  bool isEscalationRequired = false; // Escalation toggle state

  TextEditingController observationDescriptionController =
      TextEditingController();
  TextEditingController userDescriptionController = TextEditingController();
  TextEditingController ActionToBeTakenController = TextEditingController();
  TextEditingController reworkCostController = TextEditingController();

  final CompanyService _companyService = CompanyService(); // Company service
  final _formKey = GlobalKey<FormState>();
  bool isFormReady = false;
  bool isUploading = false;
  String? selectedFileName;
  List<String> uploadedFiles = [];
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await fetchCompanies(); // Optional: if company needed first
    await fetchProjects(); // Wait for project fetch and selection
    print("selected uSERid : $selectedProject");
    if (selectedProject != null) {
      // print("selected uSERid : $selectedProject");
      await _fetchSiteObservations(selectedProject!.id);
    }

    // Then load all static or unrelated data
    fetchIssueTypes();
    fetchActivities();
    fetchObservations();
    fetchObservationType();
    fetchAreaList();
    fetchFloorList();
    fetchPartList();
    fetchElementList();
    fetchContractorList();
    fetchUserList();

    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String formatDateForApi(DateTime date) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(date);
  }

  // Fetch issue types from the service
  Future<void> fetchIssueTypes() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<IssueType> fetchedIssueTypes =
          await widget._siteObservationService.fetchIssueTypes();
      setState(() {
        issueTypes = fetchedIssueTypes;
      });
    } catch (e) {
      print('Error fetching issue types: $e');
      // Optionally, you can show an error message here
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch Activities from the service
  Future<void> fetchActivities() async {
    // Fetching the companyId from shared preferences
    int? companyId = await SharedPrefsHelper.getCompanyId();

    if (companyId == null) {
      print('Error: Company ID is null');
      return; // Exit the method if companyId is null
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Fetching the activities using the fetchActivities method
      List<Activities> fetchedActivities = await widget._siteObservationService
          .fetchActivities(companyId, ScreenTypes.Safety);
      setState(() {
        activitieList = fetchedActivities;

        // Ensure `selectedActivities` is set to a valid activity from the list
        if (activitieList.isNotEmpty) {
          selectedActivities = activitieList[0]
              .activityName; // Set to first activity if available
        } else {
          selectedActivities = null; // If no activities, keep it null
        }
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
      List<Observation> fetchedObservations = await widget
          ._siteObservationService
          .fetchObservations(companyId, ScreenTypes.Safety);
      setState(() {
        observationsList = fetchedObservations;
        // Ensure `selectedObservation` is set to a valid Observation from the list
        if (observationsList.isNotEmpty) {
          selectedObservation = observationsList[0]
              .observationDescription; // Set to first Observation if available
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
        if (observationTypeList.isNotEmpty) {
          selectedObservationType = observationTypeList[0].name;
          print("selectedObservationType: $selectedObservationType");
        } else {
          selectedObservationType = null;
        }
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
  Future<void> fetchAreaList() async {
    int? projectID = await SharedPrefsHelper.getProjectID();
    // print(projectID);
    setState(() {
      isLoading = true;
    });
    // print(projectID);
    try {
      List<Area> fetchedArea =
          await widget._siteObservationService.fetchAreaList(projectID!);

      setState(() {
        areaList = fetchedArea;
        if (areaList.isNotEmpty) {
          selectedArea = areaList[0].sectionName;
          print("Area List: ${areaList.length}");
        } else {
          selectedArea = null;
        }
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
  Future<void> fetchFloorList() async {
    int? projectID = await SharedPrefsHelper.getProjectID();
    print("floor projectid:$projectID");
    setState(() {
      isLoading = true;
    });
    // print(projectID);
    try {
      List<Floor> fetchedFloor =
          await widget._siteObservationService.fetchFloorList(projectID!);

      setState(() {
        floorList = fetchedFloor;
        if (areaList.isNotEmpty) {
          selectedFloor = floorList[0].floorName;
          print(floorList);
        } else {
          selectedFloor = null;
        }
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
  Future<void> fetchPartList() async {
    int? projectID = await SharedPrefsHelper.getProjectID();
    // print(projectID);
    setState(() {
      isLoading = true;
    });
    // print(projectID);
    try {
      List<Part> fetchedPart =
          await widget._siteObservationService.fetchPartList(projectID!);

      setState(() {
        final seen = <String>{};
        partList = fetchedPart.where((part) {
          final normalized = part.partName.trim().toLowerCase();
          return seen.add(normalized);
        }).toList();
        final partNames = partList.map((e) => e.partName.trim()).toList();

        if (partNames.contains(selectedPart?.trim())) {
          selectedPart = selectedPart!.trim();
        } else {
          selectedPart = ''; // Default to placeholder
        }

        print("✅ Filtered Unique Part Names: $partNames");
      });
    } catch (e) {
      print('Error fetching Part: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch Element from the service
  Future<void> fetchElementList() async {
    int? projectID = await SharedPrefsHelper.getProjectID();
    setState(() {
      isLoading = true;
    });

    try {
      List<Elements> fetchedElement =
          await widget._siteObservationService.fetchElementList(projectID!);

      // Deduplicate elements by elementName
      final seen = <String>{};
      final uniqueElements = fetchedElement.where((element) {
        final name = element.elementName.trim();
        return seen.add(name);
      }).toList();

      setState(() {
        elementList = uniqueElements;
        if (elementList.isNotEmpty) {
          selectedElement = elementList[0].elementName;
          print(
              'Unique Elements: ${elementList.map((e) => e.elementName).toList()}');
        } else {
          selectedElement = null;
        }
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
    // print(projectID);
    try {
      List<Party> fetchedContractor =
          await widget._siteObservationService.fetchContractorList();

      setState(() {
        ContractorList = fetchedContractor;
        if (ContractorList.isNotEmpty) {
          selectedContractor = ContractorList[0].partyName;
          print(ContractorList);
        } else {
          selectedContractor = null;
        }
      });
    } catch (e) {
      print('Error fetching Contractor: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch User from the service
  Future<void> fetchUserList() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<User> fetchedUsers =
          await widget._siteObservationService.fetchUserList();

      // Remove duplicates based on userName (if needed)
      List<User> uniqueUsers = [];
      Set<String> userNames = {}; // To track duplicate userNames

      for (var user in fetchedUsers) {
        if (!userNames.contains(user.userName)) {
          uniqueUsers.add(user);
          userNames.add(user.userName); // Add to set to prevent duplicates
        }
      }

      setState(() {
        userList = uniqueUsers;
        if (userList.isNotEmpty) {
          // Assuming you're displaying userName in the dropdown
          selectedUser = userList[0].userName; // Set the first user as selected
          print("Selected User: $selectedUser");
        } else {
          selectedUser = null;
        }
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
      // ✅ FORM IS VALID
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submitting...')),
      );

      await submitForm(); // 👈 Your actual async method
    } else {
      // ❌ FORM IS INVALID
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
        print("User ID or Company ID not found in SharedPreferences");
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

      // Save the selected project ID in SharedPreferences (assuming first project is selected)
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
  Future<void> _fetchSiteObservations(int projectId) async {
    setState(() => isLoading = true);

    try {
      // int? projectID = await SharedPrefsHelper.getProjectID();
      final fetched =
          await widget._siteObservationService.fetchSiteObservationsSafety(
        projectId: projectId,
        sortColumn: 'ID desc',
        pageSize: 10,
        pageIndex: 0,
        isActive: true,
      );

      setState(() => observations = fetched);
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
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime(2100);

    // Show the date picker and get the selected date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        // Format and display the selected date
        _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  // Function to submit the form data
  Future<void> submitForm() async {
    // Retrieve text field values from controllers
    String observationDescription = observationDescriptionController.text;
    String userDescription = userDescriptionController.text;
    String actionToBeTaken =
        ActionToBeTakenController.text; // Add this line to get the action text
    int? projectID = await SharedPrefsHelper.getProjectID();
    int? companyID = await SharedPrefsHelper.getCompanyId();
    int? userID = await SharedPrefsHelper.getUserId();
    SiteObservationModel siteObservation = SiteObservationModel(
      uniqueID: const Uuid().v4(),
      id: 0,
      siteObservationCode: "",
      trancationDate: formatDateForApi(DateTime.now()),
      observationRaisedBy: userID!,
      observationTypeID: observationTypeList
          .firstWhere(
              (observation) => observation.name == selectedObservationType)
          .id,
      issueTypeID: issueTypes
          .firstWhere((issueType) => issueType.name == selectedIssueType)
          .id,
      dueDate: formatDateForApi(DateTime.now()),
      observationDescription: observationDescription,
      userDescription: userDescription, // You can add more fields
      complianceRequired: isComplianceRequired,
      escalationRequired: isEscalationRequired,
      actionToBeTaken: actionToBeTaken,
      companyID: companyID!,
      projectID: projectID!,
      functionID: ScreenTypes.Safety,
      activityID: activitieList
          .firstWhere(
              (activities) => activities.activityName == selectedActivities)
          .id,
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
      createdDate: formatDateForApi(DateTime.now()),
      lastModifiedBy: userID,
      lastModifiedDate: formatDateForApi(DateTime.now()),
      siteObservationActivity: [
        SiteObservationActivity(
          id: 0,
          siteObservationID: null,
          actionID: SiteObservationActions.Created,
          comments: '',
          documentName: uploadedFiles.isNotEmpty ? uploadedFiles.first : "",
          fromStatusID: 0,
          toStatusID: 0,
          assignedUserID:
              userList.firstWhere((u) => u.userName == selectedUser).id,
          createdBy: userList.firstWhere((u) => u.userName == selectedUser).id,
          createdDate: formatDateForApi(DateTime.now()),
          //siteObservation: null // 👈 Add this field if needed,
        ),
      ],
    );
    print("Site Observation Model: ${siteObservation.toJson()}");
    try {
      bool success = await widget._siteObservationService
          .submitSiteObservation(siteObservation);

      if (success) {
        // _resetForm(); // ⬅️ Reset form here
        setState(() {
          showObservations = true; // 👈 Form hide
        });
        await _fetchSiteObservations(projectID);
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

  // void _resetForm() {
  //   _formKey.currentState?.reset();

  //   // TextControllers
  //   observationDescriptionController.clear();
  //   userDescriptionController.clear();
  //   ActionToBeTakenController.clear();
  //   reworkCostController.clear();
  //   _dateController.clear();

  //   // Dropdowns
  //   selectedObservationType = '';
  //   selectedIssueType = '';
  //   selectedActivities = '';
  //   selectedArea = '';
  //   selectedFloor = '';
  //   selectedPart = '';
  //   selectedElement = '';
  //   selectedContractor = '';
  //   selectedProject = null;

  //   // Others
  //   uploadedFiles.clear();
  //   selectedFileName = null;
  //   isComplianceRequired = false;
  //   isEscalationRequired = false;
  //   isUploading = false;
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!showObservations) {
          // 👇 Reset form values
          // _resetForm();

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
                      await _fetchSiteObservations(newProject.id);
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
                                                hintText: 'Select a date',
                                                border: OutlineInputBorder(),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                      Icons.calendar_today),
                                                  onPressed: () {
                                                    _selectDate(context);
                                                  },
                                                ),
                                              ),
                                              readOnly: true,
                                            ),
                                            SizedBox(height: 10),
                                            DropdownButtonFormField<String>(
                                              value:
                                                  (selectedIssueType == null ||
                                                          selectedIssueType!
                                                              .isEmpty)
                                                      ? ''
                                                      : selectedIssueType,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedIssueType = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Issue Type',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please select an issue type';
                                                }
                                                return null;
                                              },
                                              items: [
                                                DropdownMenuItem<String>(
                                                  value:
                                                      '', // Placeholder value
                                                  child: Text(
                                                    'Select Issue Type',
                                                    style: TextStyle(
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                                ...issueTypes
                                                    .map((IssueType issueType) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: issueType.name,
                                                    child: Text(issueType.name),
                                                  );
                                                }).toList(),
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
                                            DropdownButtonFormField<String>(
                                              value: (selectedObservation ?? '')
                                                      .isEmpty
                                                  ? ''
                                                  : selectedObservation,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedObservation =
                                                      newValue ?? '';

                                                  final selected =
                                                      observationsList
                                                          .firstWhere(
                                                    (obs) =>
                                                        obs.observationDescription ==
                                                        selectedObservation,
                                                    orElse: () => Observation(
                                                      id: 0,
                                                      observationTypeID: 0,
                                                      issueTypeID: 0,
                                                      observationDescription:
                                                          '',
                                                      complianceRequired: false,
                                                      escalationRequired: false,
                                                      dueTimeInHrs: 0,
                                                      actionToBeTaken: '',
                                                      lastModifiedBy: '',
                                                      lastModifiedDate: DateTime
                                                              .now()
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
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Select Observation',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please select an observation';
                                                }
                                                return null;
                                              },
                                              items: [
                                                const DropdownMenuItem<String>(
                                                  value:
                                                      '', // <-- Use empty string here
                                                  child: Text(
                                                    'Select Observation',
                                                    style: TextStyle(
                                                        color: Colors.grey),
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
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                            ),

                                            const SizedBox(height: 20),

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
                                                  userDescriptionController,
                                              decoration: InputDecoration(
                                                labelText: 'User Description',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              // Add Controller to manage input text here (optional)
                                              validator: _validateUser,
                                            ),
                                            SizedBox(height: 10),
                                            TextFormField(
                                              controller: _dateController,
                                              decoration: InputDecoration(
                                                labelText: 'Due Date',
                                                hintText: 'Select a date',
                                                border: OutlineInputBorder(),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                      Icons.calendar_today),
                                                  onPressed: () {
                                                    _selectDate(
                                                        context); // Show date picker on icon tap
                                                  },
                                                ),
                                              ),
                                              readOnly:
                                                  true, // Make it read-only to prevent manual typing
                                              validator: _validateDueDate,
                                            ),
                                            SizedBox(height: 20),
                                            // Dropdown for Select observation
                                            DropdownButtonFormField<String>(
                                              value: selectedObservationType,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedObservationType =
                                                      newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Observation Type',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator:
                                                  _validateObservationType,
                                              items: observationTypeList.map(
                                                  (ObservationType
                                                      observationType) {
                                                return DropdownMenuItem<String>(
                                                  value: observationType.name,
                                                  child: Text(
                                                      observationType.name),
                                                );
                                              }).toList(),
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
                                                        onChanged:
                                                            (bool value) {
                                                          setState(() {
                                                            isComplianceRequired =
                                                                value;
                                                          });
                                                        },
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
                                                            (bool value) {
                                                          setState(() {
                                                            isEscalationRequired =
                                                                value;
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                              value: partList.any((p) =>
                                                      p.partName ==
                                                      selectedPart)
                                                  ? selectedPart
                                                  : '',
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
                                              items: [
                                                DropdownMenuItem<String>(
                                                  value: '',
                                                  child: Text('Select Part',
                                                      style: TextStyle(
                                                          color: Colors.grey)),
                                                ),
                                                ...partList.map((part) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: part.partName,
                                                    child: Text(part.partName),
                                                  );
                                                }).toList(),
                                              ],
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
                                            // Dropdown for Select Assigned To
                                            DropdownButtonFormField<String>(
                                              value: selectedUser,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedUser = newValue;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Assigned To',
                                                border: OutlineInputBorder(),
                                              ),
                                              validator: _validateAssigned,
                                              items: userList.map((User user) {
                                                return DropdownMenuItem<String>(
                                                  value: user.userName,
                                                  child: Text(user.userName),
                                                );
                                              }).toList(),
                                            ),

                                            SizedBox(height: 10),
                                            TextFormField(
                                              controller:
                                                  ActionToBeTakenController,
                                              decoration: InputDecoration(
                                                labelText: 'Action to be Taken',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              validator: _validateDescription,
                                              // Add Controller to manage input text here (optional)
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
