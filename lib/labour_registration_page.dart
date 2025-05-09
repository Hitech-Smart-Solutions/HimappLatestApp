import 'package:flutter/material.dart';
import 'package:himappnew/model/labour_registration_model.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:himappnew/service/labour_registration_service.dart';

class LabourRegistrationPage extends StatefulWidget {
  final String companyName;
  final LabourRegistrationService labourRegistrationService;

  const LabourRegistrationPage({
    Key? key,
    required this.companyName,
    required this.labourRegistrationService, // Pass the service here
  }) : super(key: key);

  @override
  State<LabourRegistrationPage> createState() => _LabourRegistrationPageState();
}

class _LabourRegistrationPageState extends State<LabourRegistrationPage> {
  bool showForm = false;
  List<LabourModel> labourList = [];
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  DateTime? _regDate, _birthDate, _arrivalDate;
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

  // Controllers
  final TextEditingController formSrNoController = TextEditingController();
  final TextEditingController contractorNameController =
      TextEditingController();
  final TextEditingController contractorContactController =
      TextEditingController();
  final TextEditingController labourNameController = TextEditingController();
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

  String? selectedGender;
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
    _loadParties();
    _fetchLabours();
    _loadLabourTypes();
    _loadCountries();
  }

//Get Labour List
  Future<void> _fetchLabours() async {
    setState(() => isLoading = true);
    try {
      // Assuming `LabourService.getAllLabours()` returns a list of labours.
      final fetched = await widget.labourRegistrationService.fetchLabours();
      setState(() => labourList = fetched);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching labours')));
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
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (labourList.isEmpty) {
      return Center(child: Text("No labours found."));
    }

    return ListView.builder(
      itemCount: labourList.length,
      itemBuilder: (context, index) {
        final labour = labourList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text(labour.fullName),
            subtitle: Text("Code: ${labour.labourRegistrationCode}"),
          ),
        );
      },
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

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dateField("Date of Registration", _regDate,
                (date) => setState(() => _regDate = date)),
            _textField("Form Sr. No", controller: formSrNoController),
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
            _dateField("Labour Birth Date", _birthDate,
                (date) => setState(() => _birthDate = date)),
            _dropdownField("Gender", ["Male", "Female", "Other"],
                selectedGender, (val) => setState(() => selectedGender = val)),
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
            SizedBox(height: 16),
            _textField("Address", controller: addressController, maxLines: 3),
            _fileUploadField(
                "Document", _registrationDoc, () => _pickImage(false)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_labourPhoto == null || _registrationDoc == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Please upload required documents")));
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Labour Registered Successfully!")));
                }
              },
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

  Widget _textField(String label,
      {TextInputType keyboard = TextInputType.text,
      int maxLines = 1,
      TextEditingController? controller,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration:
            InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: validator ??
            (val) => val == null || val.isEmpty ? "Required" : null,
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
