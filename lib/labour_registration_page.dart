import 'package:flutter/material.dart';
import 'package:himappnew/model/labour_registration_model.dart';
import 'package:himappnew/model/project_model.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:himappnew/service/labour_registration_service.dart';
import 'package:uuid/uuid.dart';

class LabourRegistrationPage extends StatefulWidget {
  final String companyName;
  final LabourRegistrationService labourRegistrationService;
  final ProjectService _projectService;

  const LabourRegistrationPage({
    super.key,
    required this.companyName,
    required ProjectService projectService,
    required this.labourRegistrationService, // Pass the service here
  }) : _projectService = projectService;

  @override
  State<LabourRegistrationPage> createState() => _LabourRegistrationPageState();
}

class _LabourRegistrationPageState extends State<LabourRegistrationPage> {
  Project? selectedProject;
  List<Project> items = [];
  bool showForm = false;
  List<LabourModel> labourList = [];
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  DateTime? _regDate,
      _birthDate,
      _arrivalDate,
      _firstVaccineDate,
      _secorndVaccineDate;
  TimeOfDay? _arrivalTime;
  File? _labourPhoto, _registrationDoc;

  final ImagePicker _picker = ImagePicker();

  List<PartyModel> parties = [];
  PartyModel? selectedParty;

  List<LabourTypeModel> labourTypes = [];
  LabourTypeModel? selectedLabourType;

  List<CountriesModel> countries = [];
  CountriesModel? selectedCountry;
  bool isCountryLoading = true;

  List<StateModel> states = [];
  StateModel? selectedState;
  bool isStateLoading = true;

  List<CityModel> cities = [];
  CityModel? selectedCity;
  bool isCityLoading = false;

  bool readOnly = false;

  // Controllers
  final TextEditingController formSrNoController = TextEditingController();
  final TextEditingController contractorNameController =
      TextEditingController();
  final TextEditingController contractorContactController =
      TextEditingController();
  final TextEditingController labourNameController = TextEditingController();
  final TextEditingController labourCodeController = TextEditingController();
  final TextEditingController labourContactController = TextEditingController();
  final TextEditingController labourTypeController = TextEditingController();
  final TextEditingController aadharController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController voterIdController = TextEditingController();
  final TextEditingController uanController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController idMarkController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final TextEditingController firstVaccineReferenceID = TextEditingController();
  final TextEditingController secorndVaccineReferenceID =
      TextEditingController();

  final Map<String, int> genderMapping = {
    'Male': 1,
    'Female': 2,
    'Other': 3,
  };

  String? selectedGender;
  int? genderId;
  String? selectedBloodGroup;
  String? selectedMaritalStatus;

  Future<void> _pickImage(bool isPhoto) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isPhoto) {
          _labourPhoto = File(pickedFile.path);
        } else {
          _registrationDoc = File(pickedFile.path);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProjects();
    _loadParties();
    _fetchLabours();
    _loadLabourTypes();
    _loadCountries();
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
        items = projects; // Correct: List<Project>
        selectedProject = items.isNotEmpty ? items[0] : null;
        isLoading = false;
      });
      // Save the selected project ID in SharedPreferences (assuming first project is selected)
      if (projects.isNotEmpty) {
        await SharedPrefsHelper.saveProjectID(
            projects[0].id); // Save the first project ID
        // print("Saved project ID: ${projects[0].id}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching projects: $e");
    }
  }

//Get Labour List
  // Future<void> _fetchLabours() async {
  //   setState(() => isLoading = true);
  //   try {
  //     // Assuming `LabourService.getAllLabours()` returns a list of labours.
  //     final fetched = await widget.labourRegistrationService.fetchLabours();
  //     setState(() => labourList = fetched);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('Error fetching labours')));
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }

  Future<void> _fetchLabours() async {
    setState(() => isLoading = true);

    try {
      int? projectID = await SharedPrefsHelper.getProjectID();
      print(projectID);

      final fetched = await widget.labourRegistrationService.fetchLabours(
        projectId: projectID!,
        sortColumn: 'ID desc',
        pageSize: 10,
        pageIndex: 0,
        isActive: true,
      );

      setState(() => labourList = fetched);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching labours: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

//Labour Type List
  void _loadLabourTypes() async {
    try {
      labourTypes = await widget.labourRegistrationService.fetchLabourTypes();
      setState(() {});
    } catch (e) {
      print("Failed to load labour types: $e");
    }
  }

//Party List
  void _loadParties() async {
    try {
      parties = await widget.labourRegistrationService.fetchParties();
      setState(() {});
    } catch (e) {
      print('Error fetching party data: $e');
    }
  }

//country list
  Future<void> _loadCountries() async {
    try {
      countries = await widget.labourRegistrationService.fetchCountries();
    } catch (e) {
      print("Failed to load countries: $e");
    } finally {
      setState(() {
        isCountryLoading = false;
      });
    }
  }

//state list
  Future<void> _loadStates(int countryId) async {
    setState(() {
      isStateLoading = true;
      states = [];
      selectedState = null;
    });

    try {
      states = await widget.labourRegistrationService.fetchState(countryId);
    } catch (e) {
      print("Failed to load states: $e");
    } finally {
      setState(() {
        isStateLoading = false;
      });
    }
  }

  //City List

  void _loadCities(int stateId) async {
    setState(() {
      isCityLoading = true;
      selectedCity = null;
    });
    try {
      cities = await widget.labourRegistrationService.fetchCities(stateId);
    } catch (e) {
      print("Failed to load cities: $e");
    } finally {
      setState(() {
        isCityLoading = false;
      });
    }
  }

  Widget _buildLabourList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<Project>(
            isExpanded: true,
            hint: Text("Select a project"),
            value: selectedProject,
            items: items.map((project) {
              return DropdownMenuItem<Project>(
                value: project,
                child: Text(project.name),
              );
            }).toList(),
            onChanged: (Project? newProject) {
              setState(() {
                selectedProject = newProject;
              });
              if (newProject != null) {
                _fetchLabours(); // Fetch labours for selected project
              }
            },
          ),
        ),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : labourList.isEmpty
                  ? Center(child: Text("No labours found."))
                  : ListView.builder(
                      itemCount: labourList.length,
                      itemBuilder: (context, index) {
                        final labour = labourList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.person),
                            title: Text(labour.fullName),
                            subtitle: Text("Code: ${labour.code}"),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Labour Registration")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: showForm ? _buildForm() : _buildLabourList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            showForm = !showForm;
          });
        },
        label: Text(showForm ? 'View List' : 'Register'),
        icon: Icon(showForm ? Icons.list : Icons.person_add),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Getting projectID from SharedPrefsHelper
      int? projectID = await SharedPrefsHelper.getProjectID();
      int? userID = await SharedPrefsHelper.getUserId();
      int genderId = genderMapping[selectedGender!] ?? 0;

      print("projectID: $projectID");
      print("userID: $userID");
      // Checking if gender and party are selected
      if (selectedGender == null || selectedParty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select gender and party')),
        );
        return;
      }
      genderId = genderMapping[selectedGender!] ?? 0;

      // Creating LabourRegistration object
      final registration = LabourRegistration(
        uniqueId: const Uuid().v4(),
        id: 0,
        labourRegistrationDate: _regDate!,
        labourRegistrationCode: labourCodeController.text,
        partyId: selectedParty!.id,
        partyContactNo: contractorContactController.text,
        fullName: labourNameController.text,
        birthDate: _birthDate!,
        genderId: genderId, // Gender ID as int
        // fullName: fullNameController.text,
        contactNo: labourContactController.text,
        tradeId: selectedLabourType!.id,
        projectId: projectID!, // Assuming projectID is non-null here
        uanNo: uanController.text,
        aadharNo: aadharController.text,
        panNo: panController.text,
        voterIDNo: voterIdController.text,
        bankAccNo: accountController.text,
        profileImagePath: _labourPhoto != null
            ? _labourPhoto!.path
            : '', // Assuming path is required
        profileFileName: _labourPhoto != null
            ? _labourPhoto!.path.split('/').last
            : '', // Assuming filename is required
        statusId: 1, // Assuming status ID is 1 for active
        isActive: true, // Assuming active by default
        createdBy: userID, // Assuming created by user ID
        createdDate: DateTime.now(),
        lastModifiedBy: userID, // Assuming last modified by user ID
        lastModifiedDate: DateTime.now(),
        labourArrivalDate: _arrivalDate!, // Assuming arrival date is required
        idMark: idMarkController.text, // Assuming ID mark is required
        bloodGroup: selectedBloodGroup,
        maritalStatusId: selectedMaritalStatus == "Single"
            ? 1
            : selectedMaritalStatus == "Married"
                ? 2
                : 3, // Assuming marital status IDs
        address: addressController.text,
        cityId: selectedCity != null
            ? selectedCity!.id
            : 0, // Assuming city ID is required
        stateId: selectedState != null
            ? selectedState!.id
            : 0, // Assuming state ID is required
        countryId: selectedCountry != null
            ? selectedCountry!.id
            : 0, // Assuming country ID is required
        firstVaccineDate: DateTime.now(),
        firstVaccineReferenceID: firstVaccineReferenceID.text,
        // secorndVaccineDate: DateTime.now(),
        secorndVaccineDate: DateTime.now(), // Replace null
        secorndVaccineReferenceID: secorndVaccineReferenceID.text,
        labourRegistrationDocumentDetails: [
          LabourRegistrationDocumentDetail(
            uniqueId: const Uuid().v4(),
            id: 0,
            labourRegistrationId: 0,
            documentName: 'Registration Document',
            fileName: _registrationDoc != null
                ? _registrationDoc!.path.split('/').last
                : '', // Assuming filename is required
            fileContentType: '',
            filePath: _registrationDoc != null
                ? _registrationDoc!.path
                : '', // Assuming path is required
            isActive: true,
            createdBy: userID,
            createdDate: DateTime.now(),
            lastModifiedBy: userID,
            lastModifiedDate: DateTime.now(),
            // documentTypeId: 1, // Assuming document type ID is 1
            // documentPath: _registrationDoc != null
            //     ? _registrationDoc!.path
            //     : '', // Assuming path is required
            // documentFileName: _registrationDoc != null
            //     ? _registrationDoc!.path.split('/').last
            //     : '', // Assuming filename is required
          ),
        ],
      );
      // Submit the registration data
      bool success = await widget.labourRegistrationService
          .submitLabourRegistration(registration);

      // Show success or failure message
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Failed')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all required fields')),
      );
    }
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dateField("Date of Registration", _regDate,
                (date) => setState(() => _regDate = date)),
            _textField("Form Sr. No",
                controller: formSrNoController, readOnly: true),
            // TextField(
            //   controller: formSrNoController,
            //   readOnly: true,
            //   decoration: InputDecoration(labelText: "Form Sr. No"),
            // ),
            DropdownButtonFormField<PartyModel>(
              value: selectedParty,
              onChanged: (PartyModel? newParty) {
                setState(() {
                  selectedParty = newParty;
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Party',
                border: OutlineInputBorder(),
              ),
              items: parties.map((party) {
                return DropdownMenuItem(
                  value: party,
                  child: Text(party.partyName),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            _textField("Contractor Contact Number",
                keyboard: TextInputType.phone,
                controller: contractorContactController,
                validator: _validatePhone),
            _textField("Name Of Labour", controller: labourNameController),
            _textField("Code Of Labour", controller: labourCodeController),
            _dateField("Labour Birth Date", _birthDate,
                (date) => setState(() => _birthDate = date)),
            _dropdownField(
                "Gender", ["Male", "Female", "Other"], selectedGender, (val) {
              setState(() {
                selectedGender = val; // Update the selectedGender
                genderId = genderMapping[
                    val]; // Update genderId based on the selected gender
              });
            }),
            _textField("Labour Contact Number",
                keyboard: TextInputType.phone,
                controller: labourContactController,
                validator: _validatePhone),
            DropdownButtonFormField<LabourTypeModel>(
              value: selectedLabourType,
              onChanged: (LabourTypeModel? newValue) {
                setState(() {
                  selectedLabourType = newValue;
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Labour Type',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null ? 'Please select a labour type' : null,
              items: labourTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.labourCategoryFullName),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            _fileUploadField(
                "Labour Photo", _labourPhoto, () => _pickImage(true)),
            _textField("Aadhar No", controller: aadharController),
            _textField("PAN No", controller: panController),
            _textField("VoterID No", controller: voterIdController),
            _textField("UAN No", controller: uanController),
            _textField("Account Number", controller: accountController),
            _dateField("Labour Arrival Date", _arrivalDate,
                (date) => setState(() => _arrivalDate = date)),
            _timeField("Labour Arrival Time", _arrivalTime,
                (time) => setState(() => _arrivalTime = time)),
            _textField("ID Mark", controller: idMarkController),
            _dropdownField(
                "Blood Group",
                ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"],
                selectedBloodGroup,
                (val) => setState(() => selectedBloodGroup = val)),
            _dropdownField(
                "Marital Status",
                ["Single", "Married", "Divorced"],
                selectedMaritalStatus,
                (val) => setState(() => selectedMaritalStatus = val)),
            DropdownButtonFormField<CountriesModel>(
              value: selectedCountry,
              onChanged: (CountriesModel? newValue) {
                setState(() {
                  selectedCountry = newValue;
                });
                if (newValue != null) {
                  _loadStates(newValue.id);
                }
              },
              decoration: InputDecoration(
                labelText: 'Choose Country',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null ? 'Please select a country' : null,
              items: countries.map((country) {
                return DropdownMenuItem(
                  value: country,
                  child: Text(country.name),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<StateModel>(
              value: selectedState,
              onChanged: (StateModel? newState) {
                setState(() {
                  selectedState = newState;
                });
                if (newState != null) {
                  _loadCities(newState.id);
                }
              },
              decoration: InputDecoration(
                labelText:
                    isStateLoading ? 'Loading states...' : 'Choose State',
                border: OutlineInputBorder(),
              ),
              items: states.map((state) {
                return DropdownMenuItem(
                  value: state,
                  child: Text(state.name),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<CityModel>(
              value: selectedCity,
              onChanged: (CityModel? newCity) {
                setState(() {
                  selectedCity = newCity;
                });
              },
              decoration: InputDecoration(
                labelText: isCityLoading ? 'Loading cities...' : 'Choose City',
                border: OutlineInputBorder(),
              ),
              items: cities.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city.name),
                );
              }).toList(),
            ),
            _dateField("Labour Arrival Date", _firstVaccineDate,
                (date) => setState(() => _firstVaccineDate = date)),
            _textField("Name Of Labour", controller: firstVaccineReferenceID),
            _dateField("Labour Arrival Date", _secorndVaccineDate,
                (date) => setState(() => _secorndVaccineDate = date)),
            _textField("Name Of Labour", controller: secorndVaccineReferenceID),
            SizedBox(height: 16),
            _textField("Address", controller: addressController, maxLines: 3),
            _fileUploadField(
                "Document", _registrationDoc, () => _pickImage(false)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitForm, // ✅ yahan sirf method ka naam
              icon: Icon(Icons.save),
              label: Text("Submit"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePhone(String? val) {
    if (val == null || val.isEmpty) return "Required";
    if (!RegExp(r'^\d{10}$').hasMatch(val)) return "Enter 10-digit number";
    return null;
  }

  // Widget _textField(String label,
  //     {TextInputType keyboard = TextInputType.text,
  //     int maxLines = 1,
  //     TextEditingController? controller,
  //     bool readOnly = false,
  //     String? Function(String?)? validator}) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16),
  //     child: TextFormField(
  //       controller: controller,
  //       keyboardType: keyboard,
  //       maxLines: maxLines,
  //       // readOnly: readOnly,
  //       decoration:
  //           InputDecoration(labelText: label, border: OutlineInputBorder()),
  //       filled: readOnly,
  //       validator: validator ??
  //           (val) => val == null || val.isEmpty ? "Required" : null,
  //     ),
  //   );
  // }

  Widget _textField(String label,
      {TextInputType keyboard = TextInputType.text,
      int maxLines = 1,
      TextEditingController? controller,
      bool readOnly = false,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
        ),
        validator: validator ??
            (val) {
              if (readOnly) return null; // ❌ No validation if field is readOnly
              return val == null || val.isEmpty ? "Required" : null;
            },
      ),
    );
  }

  Widget _dropdownField(String label, List<String> items, String? currentValue,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration:
            InputDecoration(labelText: label, border: OutlineInputBorder()),
        items: items
            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
            .toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? "Required" : null,
      ),
    );
  }

  Widget _dateField(
      String label, DateTime? date, Function(DateTime) onSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked != null) onSelected(picked);
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            controller: TextEditingController(
                text: date != null ? _dateFormat.format(date) : ''),
            validator: (val) => val == null || val.isEmpty ? "Required" : null,
          ),
        ),
      ),
    );
  }

  Widget _timeField(
      String label, TimeOfDay? time, Function(TimeOfDay) onSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
          TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: time ?? TimeOfDay.now(),
          );
          if (picked != null) onSelected(picked);
        },
        child: AbsorbPointer(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.access_time),
            ),
            controller: TextEditingController(
                text: time != null ? time.format(context) : ''),
            validator: (val) => val == null || val.isEmpty ? "Required" : null,
          ),
        ),
      ),
    );
  }

  Widget _fileUploadField(String label, File? file, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
              child: Text(file != null
                  ? file.path.split('/').last
                  : "No file selected")),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(Icons.upload_file),
            label: Text(label),
          ),
        ],
      ),
    );
  }
}
