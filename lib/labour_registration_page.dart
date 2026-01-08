import 'package:flutter/material.dart';
import 'package:himappnew/model/labour_registration_model.dart';
import 'package:himappnew/model/project_model.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:himappnew/service/labour_registration_service.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import 'package:http_parser/http_parser.dart';

class LabourRegistrationPage extends StatefulWidget {
  final String companyName;
  final LabourRegistrationService labourRegistrationService;
  final ProjectService _projectService;
  final LabourRegistration? selectedLabour;

  const LabourRegistrationPage({
    super.key,
    required this.companyName,
    required ProjectService projectService,
    required this.labourRegistrationService, // Pass the service here
    this.selectedLabour,
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
  File? _labourPhoto, _registrationDoc, _pickedImage;

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

  // File? _registrationDoc;
  bool _isUploading = false;

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
  final String? imageUrl = null;
  String? selectedGender;
  int? genderId;
  String? selectedBloodGroup;
  String? selectedMaritalStatus;
  int? maritalStatusId;

  int _mapMaritalStatusStringToId(String? status) {
    switch (status) {
      case 'Single':
        return 1;
      case 'Married':
        return 2;
      case 'Divorced':
        return 3;
      default:
        return 1;
    }
  }

  String _mapMaritalStatusIdToString(int? id) {
    switch (id) {
      case 1:
        return 'Single';
      case 2:
        return 'Married';
      case 3:
        return 'Divorced';
      default:
        return 'Single'; // Default fallback
    }
  }

  late TextEditingController fullNameController;
  late TextEditingController contactNoController;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  LabourRegistration? selectedLabour;
  final Map<int, String> reverseGenderMapping = {
    1: 'Male',
    2: 'Female',
    3: 'Other',
  };

  int labourId = 0; // Assuming this is the ID of the labour being edited

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchProjects();
    _loadParties();

    int? projectID = await SharedPrefsHelper.getProjectID();
    if (projectID != null) {
      Project? projectFromPrefs =
          items.firstWhere((p) => p.id == projectID, orElse: () => items.first);
      setState(() {
        selectedProject = projectFromPrefs;
      });
      await _fetchLabours(projectFromPrefs.id);
    }

    _loadLabourTypes();
    _loadCountries();

    final labour = widget.selectedLabour;
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
        items = projects; // Correct: List<Project>
        selectedProject = items.isNotEmpty ? items[0] : null;
        isLoading = false;
      });
      // Save the selected project ID in SharedPreferences (assuming first project is selected)
      if (projects.isNotEmpty) {
        await SharedPrefsHelper.saveProjectID(
            projects[0].id); // Save the first project ID
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching projects: $e");
    }
  }

  Future<void> _fetchLabours(int projectId) async {
    setState(() => isLoading = true);

    try {
      // int? projectID = await SharedPrefsHelper.getProjectID();
      final fetched = await widget.labourRegistrationService.fetchLabours(
        projectId: projectId,
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
  Future<void> _loadCities(int stateId) async {
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

  Future<void> _setDropdownValuesForEdit(
      LabourRegistration selectedLabour) async {
    // Step 1: Set selectedCountry
    selectedCountry = countries.firstWhere(
      (country) => country.id == selectedLabour.countryId,
      orElse: () => countries.first,
    );

    // Step 2: Load states for selected country
    await _loadStates(selectedCountry!.id);

    // Step 3: Set selectedState
    if (states.isNotEmpty) {
      selectedState = states.firstWhere(
        (state) => state.id == selectedLabour.stateId,
        orElse: () => states.first,
      );
    }

    // Step 4: Load cities for selected state
    await _loadCities(selectedState!.id);
    // await Future(() => _loadCities(selectedState!.id));
    // Step 5: Set selectedCity
    if (cities.isNotEmpty) {
      selectedCity = cities.firstWhere(
        (city) => city.id == selectedLabour.cityId,
        orElse: () => cities.first,
      );
    }

    setState(() {});
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
            onChanged: (Project? newProject) async {
              if (newProject != null) {
                setState(() {
                  selectedProject = newProject;
                });
                await SharedPrefsHelper.setProjectID(newProject.id);
                await _fetchLabours(newProject.id);
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
                            title: Text(labour.fullName ?? 'No Name'),
                            subtitle: Text("Code: ${labour.code ?? 'N/A'}"),
                            onTap: () async {
                              // final labourId = labour.id;
                              final labourIdFromList = labour.id;
                              final labourRegistration = await widget
                                  .labourRegistrationService
                                  .getLabourById(labourIdFromList);
                              setState(() {
                                showForm = true; // Open the form
                                selectedLabour = labourRegistration;
                                labourId = labourRegistration.id ?? 0;
                                _regDate =
                                    selectedLabour!.labourRegistrationDate;
                                formSrNoController.text =
                                    selectedLabour?.labourRegistrationCode ??
                                        '';
                                selectedParty = parties.firstWhere(
                                  (party) =>
                                      party.id == selectedLabour?.partyId,
                                  orElse: () => parties
                                      .first, // fallback in case ID doesn't match
                                );
                                contractorContactController.text =
                                    selectedLabour?.partyContactNo ?? '';
                                labourNameController.text =
                                    selectedLabour?.fullName ?? '';
                                _birthDate =
                                    selectedLabour?.birthDate ?? DateTime.now();
                                if (selectedLabour?.genderId != null) {
                                  selectedGender = reverseGenderMapping[
                                          selectedLabour!.genderId!] ??
                                      'Male';
                                }
                                labourContactController.text =
                                    selectedLabour?.contactNo ?? '';
                                selectedLabourType = labourTypes.firstWhere(
                                  (albour) =>
                                      labour.id == selectedLabour?.tradeId,
                                  orElse: () => labourTypes
                                      .first, // fallback in case ID doesn't match
                                );
                                aadharController.text =
                                    selectedLabour?.aadharNo ?? '';
                                panController.text =
                                    selectedLabour?.panNo ?? '';
                                voterIdController.text =
                                    selectedLabour?.voterIDNo ?? '';
                                uanController.text =
                                    selectedLabour?.uanNo ?? '';
                                accountController.text =
                                    selectedLabour?.bankAccNo ?? '';
                                _arrivalDate =
                                    selectedLabour?.labourArrivalDate;
                                _arrivalTime = TimeOfDay.fromDateTime(
                                    selectedLabour?.labourArrivalDate ??
                                        DateTime.now());
                                // _arrivalTime = selectedLabour?.arrivalTime;
                                idMarkController.text =
                                    selectedLabour?.idMark ?? '';
                                selectedBloodGroup =
                                    selectedLabour?.bloodGroup ?? '';
                                selectedMaritalStatus =
                                    _mapMaritalStatusIdToString(
                                        selectedLabour?.maritalStatusId);
                                _setDropdownValuesForEdit(labourRegistration);
                                addressController.text =
                                    selectedLabour?.address ?? '';
                                _firstVaccineDate =
                                    selectedLabour?.firstVaccineDate;
                                firstVaccineReferenceID.text =
                                    selectedLabour?.firstVaccineReferenceID ??
                                        '';
                                _secorndVaccineDate =
                                    selectedLabour?.secondVaccineDate;
                                secorndVaccineReferenceID.text =
                                    selectedLabour?.secondVaccineReferenceID ??
                                        '';
                                _labourPhoto = selectedLabour
                                            ?.profileImagePath !=
                                        null
                                    ? File(selectedLabour!.profileImagePath!)
                                    : null;
                              });
                            },
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

  Future<void> _uploadImage() async {
    if (_pickedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.130:8000/api/LabourRegistration/upload'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // 👈 this must match the backend field name
          _pickedImage!.path,
          contentType: MediaType(
            'image',
            lookupMimeType(_pickedImage!.path)!.split('/')[1],
          ),
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        print("✅ Upload successful");
      } else {
        print("❌ Upload failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Upload error: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      int? projectID = await SharedPrefsHelper.getProjectID();
      int? userID = await SharedPrefsHelper.getUserId();
      int genderId = genderMapping[selectedGender!] ?? 0;

      if (selectedGender == null || selectedParty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select gender and party')),
        );
        return;
      }

      final registration = LabourRegistration(
        uniqueId: const Uuid().v4(),
        id: labourId, // 👈 id 0 hoga to save, warna update
        labourRegistrationDate: _regDate!,
        labourRegistrationCode: labourCodeController.text,
        partyId: selectedParty!.id,
        partyContactNo: contractorContactController.text,
        fullName: labourNameController.text,
        birthDate: _birthDate!,
        genderId: genderId,
        contactNo: labourContactController.text,
        tradeId: selectedLabourType!.id,
        projectId: projectID!,
        uanNo: uanController.text,
        aadharNo: aadharController.text,
        panNo: panController.text,
        voterIDNo: voterIdController.text,
        bankAccNo: accountController.text,
        profileImagePath: _labourPhoto?.path ?? '',
        profileFileName:
            _labourPhoto != null ? _labourPhoto!.path.split('/').last : '',
        statusId: 1,
        isActive: true,
        createdBy: userID,
        createdDate: DateTime.now(),
        lastModifiedBy: userID,
        lastModifiedDate: DateTime.now(),
        labourArrivalDate: _arrivalDate!,
        idMark: idMarkController.text,
        bloodGroup: selectedBloodGroup,
        maritalStatusId: selectedMaritalStatus == "Single"
            ? 1
            : selectedMaritalStatus == "Married"
                ? 2
                : 3,
        address: addressController.text,
        cityId: selectedCity?.id ?? 0,
        stateId: selectedState?.id ?? 0,
        countryId: selectedCountry?.id ?? 0,
        firstVaccineDate: DateTime.now(),
        firstVaccineReferenceID: firstVaccineReferenceID.text,
        secondVaccineDate: DateTime.now(),
        secondVaccineReferenceID: secorndVaccineReferenceID.text,
        labourRegistrationDocumentDetails: [
          LabourRegistrationDocumentDetail(
            uniqueId: const Uuid().v4(),
            id: 0,
            labourRegistrationId: 0,
            documentName: 'Registration Document',
            fileName: _registrationDoc?.path.split('/').last ?? '',
            fileContentType: '',
            filePath: _registrationDoc?.path ?? '',
            isActive: true,
            createdBy: userID,
            createdDate: DateTime.now(),
            lastModifiedBy: userID,
            lastModifiedDate: DateTime.now(),
          ),
        ],
      );
      // Debugging: Print the registration object
      // ✅ Save or Update
      bool success;
      if (registration.id == 0) {
        success = await widget.labourRegistrationService
            .submitLabourRegistration(registration);
      } else {
        success = await widget.labourRegistrationService
            .updateLabourRegistration(registration);
      }

      // ✅ After save/update: Hide form and refresh list
      if (success) {
        setState(() {
          showForm = false; // 👈 Form hide
        });
        if (projectID != null) {
          _fetchLabours(projectID);
        } // 👈 Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Operation Successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Operation Failed')),
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
            // _textField("Code Of Labour", controller: labourCodeController),
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
            // _fileUploadField(
            //     "Labour Photo", _labourPhoto, () => _pickImage(true)),
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
              (val) {
                setState(() {
                  selectedMaritalStatus = val;
                  maritalStatusId =
                      _mapMaritalStatusStringToId(val); // If needed
                });
              },
            ),
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
            SizedBox(height: 16),
            _dateField("Labour Arrival Date", _firstVaccineDate,
                (date) => setState(() => _firstVaccineDate = date)),
            _textField("Name Of Labour", controller: firstVaccineReferenceID),
            _dateField("Labour Arrival Date", _secorndVaccineDate,
                (date) => setState(() => _secorndVaccineDate = date)),
            _textField("Name Of Labour", controller: secorndVaccineReferenceID),
            SizedBox(height: 16),
            _textField("Address", controller: addressController, maxLines: 3),
            _fileUploadField("Document", _registrationDoc, () => _pickImage),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Pick Image"),
            ),
            ElevatedButton.icon(
              onPressed: _submitForm, // ✅ yahan sirf method ka naam
              icon: Icon(Icons.save),
              // label: Text(registration.id == 0 ? "Save" : "Update"),
              label: Text(selectedLabour == null || selectedLabour!.id == 0
                  ? "Save"
                  : "Update"),
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

  Widget _fileUploadField(String label, File? imageFile, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl ?? '',
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        if (imageFile != null) ...[
          SizedBox(height: 10),
          Text(
            "Preview:",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Image.file(
            imageFile,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ]
      ],
    );
  }
}
