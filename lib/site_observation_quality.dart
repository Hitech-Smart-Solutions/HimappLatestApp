import 'package:flutter/material.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/model/company_model.dart';
import 'package:himappnew/model/project_model.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/service/company_service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class SiteObservationQuality extends StatefulWidget {
  final SiteObservationService siteObservationService;
  final ProjectService projectService;

  const SiteObservationQuality({
    Key? key,
    required this.siteObservationService,
    required this.projectService,
  }) : super(key: key);

  @override
  _SiteObservationQualityState createState() => _SiteObservationQualityState();
}

class _SiteObservationQualityState extends State<SiteObservationQuality> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();

  String? selectedCompany;
  List<Company> companies = []; // Company names list

  Project? selectedProject;
  List<Project> projectList = [];

  String? observationDescription;
  // String? selectedProject;
  bool showForm = false;
  bool isLoading = true; // Loading indicator
  // List<String> projectList = ['Project A', 'Project B', 'Project C'];
  List<String> categories = [
    'Workmanship',
    'Material',
    'Method',
    'Documentation'
  ];
  // List<Map<String, String>> observations = [];
  List<SiteObservation> observations = [];

  String? selectedIssueType;
  List<IssueType> issueTypes = [];

  String? selectedActivities;
  List<Activities> activitieList = [];

  String? selectedObservationType;
  List<ObservationType> observationTypeList = [];

  String? selectedObservation;
  List<Observation> observationsList = [];

  bool isComplianceRequired = false; // Compliance toggle state
  bool isEscalationRequired = false; // Escalation toggle state

  String? selectedArea;
  List<Area> areaList = [];

  String? selectedFloor;
  List<Floor> floorList = [];

  String? selectedPart;
  List<Part> partList = [];

  String? selectedElement;
  List<Elements> elementList = [];

  String? selectedContractor;
  List<Party> ContractorList = [];

  String? selectedUser;
  List<User> userList = [];

  TextEditingController observationDescriptionController =
      TextEditingController();
  TextEditingController userDescriptionController = TextEditingController();
  TextEditingController ActionToBeTakenController = TextEditingController();
  TextEditingController reworkCostController = TextEditingController();
  final CompanyService _companyService = CompanyService();
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await fetchCompanies(); // Optional: if company needed first
    await fetchProjects(); // Wait for project fetch and selection
    // print(selectedProject!.id);
    // if (selectedProject != null) {
    //   await _fetchSiteObservations(selectedProject!.id);
    // }
    int? projectID = await SharedPrefsHelper.getProjectID();
    print(projectID);
    if (projectID != null) {
      Project? projectFromPrefs = projectList.firstWhere(
          (p) => p.id == projectID,
          orElse: () => projectList.first);
      setState(() {
        selectedProject = projectFromPrefs;
      });
      await _fetchSiteObservations(projectFromPrefs.id);
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

  String? _validateReworkCost(String? value) {
    if (value == null || value.isEmpty) {
      return 'Rework Cost is required';
    }
    if (double.tryParse(value) == null) {
      return 'Enter valid number';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
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

  // Fetch Project from the service
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

      List<Project> projects = await widget.projectService.fetchProject(
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
    print("Project ID: $projectId");
    try {
      // int? projectID = await SharedPrefsHelper.getProjectID();
      final fetched = await widget.siteObservationService.fetchSiteObservations(
        projectId: projectId,
        sortColumn: 'ID desc',
        pageSize: 10,
        pageIndex: 0,
        isActive: true,
      );
      print("Fetched Observations: $fetched");
      setState(() => observations = fetched);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching labours: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Fetch Issue Types from the service
  Future<void> fetchIssueTypes() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<IssueType> fetchedIssueTypes =
          await widget.siteObservationService.fetchIssueTypes();
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
      List<Activities> fetchedActivities = await widget.siteObservationService
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

  // Fetch Observations from the service
  Future<void> fetchObservationType() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<ObservationType> fetchedObservationType =
          await widget.siteObservationService.fetchObservationType();

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

  // Fetch Observations from the service
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
          .siteObservationService
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

  // Fetch Area from the service
  Future<void> fetchAreaList() async {
    int? projectID = await SharedPrefsHelper.getProjectID();
    print('123 : $projectID');
    setState(() {
      isLoading = true;
    });
    // print(projectID);
    try {
      List<Area> fetchedArea =
          await widget.siteObservationService.fetchAreaList(projectID!);
      print('fetching Area: $fetchedArea');
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
    // print(projectID);
    setState(() {
      isLoading = true;
    });
    // print(projectID);
    try {
      List<Floor> fetchedFloor =
          await widget.siteObservationService.fetchFloorList(projectID!);

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
          await widget.siteObservationService.fetchPartList(projectID!);

      setState(() {
        partList = fetchedPart;
        if (partList.isNotEmpty) {
          selectedPart = partList[0].partName;
          print(partList);
        } else {
          selectedPart = null;
        }
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
    // print(projectID);
    setState(() {
      isLoading = true;
    });
    // print(projectID);
    try {
      List<Elements> fetchedElement =
          await widget.siteObservationService.fetchElementList(projectID!);

      setState(() {
        elementList = fetchedElement;
        if (elementList.isNotEmpty) {
          selectedElement = elementList[0].elementName;
          print(elementList);
        } else {
          selectedPart = null;
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
          await widget.siteObservationService.fetchContractorList();

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
          await widget.siteObservationService.fetchUserList();

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
    print("🔔 _submitForm() called"); // Check this

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

  Future<void> submitForm() async {
    try {
      String observationDescription = observationDescriptionController.text;
      String userDescription = userDescriptionController.text;
      String actionToBeTaken = ActionToBeTakenController.text;

      int? projectID = await SharedPrefsHelper.getProjectID();
      int? companyID = await SharedPrefsHelper.getCompanyId();
      int? userID = await SharedPrefsHelper.getUserId();

      final observationType = observationTypeList.firstWhere(
        (observation) => observation.name == selectedObservationType,
        orElse: () => throw Exception(
            "❌ observationType not found: $selectedObservationType"),
      );
      final issueType = issueTypes.firstWhere(
        (issueType) => issueType.name == selectedIssueType,
        orElse: () =>
            throw Exception("❌ issueType not found: $selectedIssueType"),
      );
      final activity = activitieList.firstWhere(
        (activity) => activity.activityName == selectedActivities,
        orElse: () =>
            throw Exception("❌ activity not found: $selectedActivities"),
      );
      final area = areaList.firstWhere(
        (area) => area.sectionName == selectedArea,
        orElse: () => throw Exception("❌ area not found: $selectedArea"),
      );
      final floor = floorList.firstWhere(
        (floor) => floor.floorName == selectedFloor,
        orElse: () => throw Exception("❌ floor not found: $selectedFloor"),
      );
      final part = partList.firstWhere(
        (part) => part.partName == selectedPart,
        orElse: () => throw Exception("❌ part not found: $selectedPart"),
      );
      final element = elementList.firstWhere(
        (element) => element.elementName == selectedElement,
        orElse: () => throw Exception("❌ element not found: $selectedElement"),
      );
      final contractor = ContractorList.firstWhere(
        (contractor) => contractor.partyName == selectedContractor,
        orElse: () =>
            throw Exception("❌ contractor not found: $selectedContractor"),
      );

      final siteObservation = SiteObservationModel(
        uniqueID: const Uuid().v4(),
        id: 0,
        siteObservationCode: "",
        trancationDate: formatDateForApi(DateTime.now()),
        observationRaisedBy: userID!,
        observationTypeID: observationType.id,
        issueTypeID: issueType.id,
        dueDate: formatDateForApi(DateTime.now()),
        observationDescription: observationDescription,
        userDescription: userDescription,
        complianceRequired: isComplianceRequired,
        escalationRequired: isEscalationRequired,
        actionToBeTaken: actionToBeTaken,
        companyID: companyID!,
        projectID: projectID!,
        functionID: ScreenTypes.Quality,
        activityID: activity.id,
        sectionID: area.id,
        floorID: floor.id,
        partID: part.id,
        elementID: element.id,
        contractorID: contractor.id,
        reworkCost: double.tryParse(reworkCostController.text) ?? 0.0,
        comments: 'Some comments',
        rootCauseID: 0,
        corretiveActionToBeTaken: 'Corrective action here',
        preventiveActionTaken: 'Preventive action here',
        statusID: 3,
        isActive: true,
        createdBy: userID,
        createdDate: formatDateForApi(DateTime.now()),
        lastModifiedBy: userID,
        lastModifiedDate: formatDateForApi(DateTime.now()),
        siteObservationActivity: [
          SiteObservationActivity(
            id: 0,
            siteObservationID: 0,
            actionID: 0,
            comments: 'Some initial comments',
            documentName: 'document.pdf',
            fromStatusID: 0,
            toStatusID: 0,
            assignedUserID: userID,
            createdBy: userID,
            createdDate: formatDateForApi(DateTime.now()),
          ),
        ],
      );

      bool success = await widget.siteObservationService
          .submitSiteObservation(siteObservation);

      if (success) {
        setState(() {
          showForm = false; // 👈 Form turant band karo
        });

        // ✅ Success message turant dikhana
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Site Observation submitted successfully!')),
        );

        // 🔄 Background me list reload karo bina delay ke
        if (projectID != null) {
          Future.delayed(Duration.zero, () async {
            await _fetchSiteObservations(projectID);
          });
        }
      } else {
        // ❌ Failure message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to submit Site Observation')),
        );
      }
    } catch (e, stackTrace) {
      print("❌ Exception in submitForm: $e");
      print("🧵 StackTrace: $stackTrace");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Site Observation - Quality'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            // 🔹 Project Dropdown
            if (!showForm)
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
                    });
                    await SharedPrefsHelper.saveProjectID(newProject.id);
                    await _fetchSiteObservations(newProject.id);
                  }
                },
              ),
            if (!showForm) SizedBox(height: 16),

            // 🔹 Observation List
            if (!showForm && observations.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No Observations Available'),
                ),
              ),
            if (!showForm)
              GridView.count(
                crossAxisCount: 1, // 1 card per row
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: observations.map((obs) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            obs.siteObservationCode,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),

                          // 2-column layout like Bootstrap col-md-6
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              _infoBox("ObservationType", obs.observationType),
                              _infoBox("IssueType", obs.issueType),
                              _infoBox("Status", obs.observationStatus),
                              _infoBox("Project", obs.projectName),
                              _infoBox(
                                  "Date",
                                  obs.transactionDate
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0]),
                            ],
                          ),

                          SizedBox(height: 8),
                          Text(
                            obs.observationDescription,
                            style: TextStyle(fontSize: 14),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            // 🔹 Form
            if (showForm)
              Card(
                margin: EdgeInsets.only(top: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // 🔹 Date Picker
                        TextFormField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            hintText: 'Select a date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          validator: _validateDate,
                          onTap: () => _selectDate(context),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedIssueType,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedIssueType = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Issue Type',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateIssueType,
                          items: issueTypes.map((IssueType issueType) {
                            return DropdownMenuItem<String>(
                              value: issueType.name,
                              child: Text(issueType.name),
                            );
                          }).toList(),
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
                          items: activitieList.map((Activities activity) {
                            return DropdownMenuItem<String>(
                              value: activity.activityName,
                              child: Text(activity.activityName),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 20),

                        DropdownButtonFormField<String>(
                          value: selectedObservation,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedObservation = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Select Observation',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateObservation,
                          items: observationsList.isNotEmpty
                              ? observationsList.map((Observation observation) {
                                  return DropdownMenuItem<String>(
                                    value: observation.observationDescription,
                                    child: Container(
                                      width:
                                          200.0, // You can set a max width here
                                      child: Text(
                                        observation.observationDescription,
                                        overflow: TextOverflow
                                            .ellipsis, // Handle text overflow
                                        maxLines:
                                            1, // Ensure it stays in one line
                                      ),
                                    ),
                                  );
                                }).toList()
                              : [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('No observations available'),
                                  ),
                                ],
                        ),
                        SizedBox(height: 20),

                        TextFormField(
                          controller: observationDescriptionController,
                          decoration: InputDecoration(
                            labelText: 'Observation Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: _validateDescription,
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: userDescriptionController,
                          decoration: InputDecoration(
                            labelText: 'User Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
                              icon: Icon(Icons.calendar_today),
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
                              selectedObservationType = newValue;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Observation Type',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateObservationType,
                          items: observationTypeList
                              .map((ObservationType observationType) {
                            return DropdownMenuItem<String>(
                              value: observationType.name,
                              child: Text(observationType.name),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // **Compliance Required** Toggle Switch
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text("Compliance Required"),
                                  Switch(
                                    value: isComplianceRequired,
                                    onChanged: (bool value) {
                                      setState(() {
                                        isComplianceRequired = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // **Escalation Required** Toggle Switch
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text("Escalation Required"),
                                  Switch(
                                    value: isEscalationRequired,
                                    onChanged: (bool value) {
                                      setState(() {
                                        isEscalationRequired = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),
                        // Dropdown for Select Area
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
                          items: areaList.map((Area areaList) {
                            return DropdownMenuItem<String>(
                              value: areaList.sectionName,
                              child: Text(areaList.sectionName),
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
                          items: floorList.map((Floor floorList) {
                            return DropdownMenuItem<String>(
                              value: floorList.floorName,
                              child: Text(floorList.floorName),
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
                          items: partList.map((Part partList) {
                            return DropdownMenuItem<String>(
                              value: partList.partName,
                              child: Text(partList.partName),
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
                          items: elementList.map((Elements elementList) {
                            return DropdownMenuItem<String>(
                              value: elementList.elementName,
                              child: Text(elementList.elementName),
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
                          items: ContractorList.map<DropdownMenuItem<String>>(
                              (Party contractor) {
                            return DropdownMenuItem<String>(
                              value: contractor
                                  .partyName, // Ensure this is a String
                              child: Text(contractor.partyName),
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
                          controller: ActionToBeTakenController,
                          decoration: InputDecoration(
                            labelText: 'Action to be Taken',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: _validateDescription,
                          // Add Controller to manage input text here (optional)
                        ),

                        SizedBox(height: 10),
                        TextFormField(
                          controller: reworkCostController,
                          keyboardType:
                              TextInputType.number, // Allow only number input
                          decoration: InputDecoration(
                            labelText: 'Rework Cost',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Please enter rework cost';
                            if (double.tryParse(value) == null)
                              return 'Enter valid number';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        // 🔹 Submit Button
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      // 🔹 FAB to toggle form
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            showForm = !showForm;
          });
        },
        child: Icon(showForm ? Icons.close : Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return SizedBox(
      width: 160, // You can tweak this to fit 2 columns nicely
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: value,
              style:
                  TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
