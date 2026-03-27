import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:himappnew/model/logbook_model.dart';
import 'package:himappnew/model/project_model.dart';
import 'package:himappnew/service/logbook_service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class LogBook extends StatefulWidget {
  const LogBook({Key? key}) : super(key: key);

  @override
  State<LogBook> createState() => _LogBookState();
}

class LunchOption {
  final String label;
  final double value;

  LunchOption({required this.label, required this.value});
}

class ReadingDetail {
  ReadingType? selectedReading;

  TextEditingController openingController;
  TextEditingController closingController;
  TextEditingController remarksController;

  ReadingDetail({
    this.selectedReading,
    TextEditingController? openingController,
    TextEditingController? closingController,
    TextEditingController? remarksController,
  })  : openingController = openingController ?? TextEditingController(),
        closingController = closingController ?? TextEditingController(),
        remarksController = remarksController ?? TextEditingController();
}

class WorkDescriptionModel {
  int? workDescriptionID;

  String? fromTime;
  String? toTime;

  TextEditingController fromController;
  TextEditingController toController;

  TextEditingController workDownHours;
  TextEditingController machineOutput;

  int? uomID;
  int? projectID;
  bool allowProjectChange;

  TextEditingController remarks;

  WorkDescriptionModel({
    this.workDescriptionID,
    this.fromTime,
    this.toTime,
    TextEditingController? fromController,
    TextEditingController? toController,
    TextEditingController? workDownHours,
    TextEditingController? machineOutput,
    this.uomID,
    this.projectID,
    this.allowProjectChange = false,
    TextEditingController? remarks,
  })  : fromController = fromController ?? TextEditingController(),
        toController = toController ?? TextEditingController(),
        workDownHours = workDownHours ?? TextEditingController(),
        machineOutput = machineOutput ?? TextEditingController(),
        remarks = remarks ?? TextEditingController();
}

class BreakdownModel {
  int? typeID;
  int? reasonID;
  List<BreakDownReason> reasonsList;

  int? categoryId;

  String? fromTime;
  String? toTime;
  String? reading;
  int? rmTypeID;
  int? assetCounterId;
  double? spentHours;

  TextEditingController fromController;
  TextEditingController toController;
  TextEditingController readingsController;
  TextEditingController remarksController;

  BreakdownModel({
    this.typeID,
    this.reasonID,
    this.categoryId,
    this.fromTime,
    this.toTime,
    this.reading,
    this.rmTypeID,
    this.assetCounterId,
    this.spentHours = 0.0,
    List<BreakDownReason>? reasonsList,
    TextEditingController? fromController,
    TextEditingController? toController,
    TextEditingController? readingsController,
    TextEditingController? remarksController,
  })  : reasonsList = reasonsList ?? [],
        fromController = fromController ?? TextEditingController(),
        toController = toController ?? TextEditingController(),
        readingsController = readingsController ?? TextEditingController(),
        remarksController = remarksController ?? TextEditingController();
}

class _LogBookState extends State<LogBook> {
  /// 🔹 DATA
  // List<String> logs = [];
  Project? selectedProject;
  List<Project> projectList = [];
  final ProjectService _projectService = ProjectService();
  final LogbookService _logBookService = LogbookService();
  // bool isLoading = true; // Loading indicator

  List<LogBookModal> logbookData = [];
  bool isLoading = false;

  bool showForm = false;

  List<EquipmentModel> equipmentList = [];
  EquipmentModel? selectedEquipment;

  List<AssetTypeModel> assetTypes = [];
  AssetTypeModel? selectedAssetType;

  // final LogBookService _service = LogBookService();

  List<int> hours = List.generate(24, (i) => i);
  List<int> minutes = List.generate(60, (i) => i);
  // List<double> lunchOptions = [0, 0.5, 1, 1.5, 2];
  List<LunchOption> lunchOptions = [];

  int? stHour, stMinute, etHour, etMinute;
  double lunchTime = 0;

  double idleHour = 0;
  bool isNoWorkDone = false;

  double? selectedLunch;

  void updateTime({int? sH, int? sM, int? eH, int? eM}) {
    setState(() {
      if (sH != null) stHour = sH;
      if (sM != null) stMinute = sM;
      if (eH != null) etHour = eH;
      if (eM != null) etMinute = eM;
    });

    calculateIdleHour(); // always call after update
  }

  String formatHours(double hours) {
    int totalMinutes = (hours * 60).round();

    int hrs = totalMinutes ~/ 60;
    int mins = totalMinutes % 60;

    if (hrs > 0 && mins > 0) {
      return "$hrs hr $mins min";
    }

    if (hrs > 0) {
      return "$hrs hr";
    }

    return "$mins min";
  }

  String? errorMessage;

  DateTime? selectedDate;
  String? logBookDate;
  TextEditingController dateController = TextEditingController();
  TextEditingController remarksController = TextEditingController();

  List<Operator> operatorList = [];

  Operator? selectedDayOperator;
  Operator? selectedNightOperator;
  int pageIndex = 0;
  int pageSize = 100;
  String searchQuery = '';
  bool hasMore = true;

  List<ReadingType> readingTypesList = []; // ✅ YAHI LAGAO
  List<ReadingDetail> readingDetails = [];

  // void addReadingDetail() {
  //   setState(() {
  //     readingDetails.add(ReadingDetail());
  //   });
  //   print("Row added: ${readingDetails.length}");
  // }

// workDescription
  List<WorkDescriptionModel> workList = [];
  List<WorkDescription> workDescriptionList = [];
  void addWorkDescription() {
    setState(() {
      workList.add(WorkDescriptionModel()..projectID = selectedProject?.id);
    });
  }

  void openWorkPopup() {
    showDialog(
      context: Navigator.of(context, rootNavigator: true).context,
      builder: (context) {
        return AlertDialog(
          title: Text("Test"),
          content: Text("Popup working"),
        );
      },
    );
  }

// BreakDown
  List<BreakDownReason> breakDownReasonsList = [];
  List<BreakdownModel> breakdownList = [];
  List<UomModel> uomList = [];

  List<AssetCounter> assetCountersList = [];
  List<RmType> rmTypesList = [];

  // Outside the dialog, in the same file
  void onTypeChanged(BreakdownModel item, int? type, int objectTypeId,
      void Function(VoidCallback fn) setStateDialog) async {
    item.typeID = type;
    item.reasonID = null; // reset selected reason

    List<BreakDownReason> newReasons = [];

    if (type == 1) {
      newReasons = await _logBookService.getBreakDownReasons(objectTypeId);
    } else if (type == 2) {
      newReasons = await _logBookService.getInHouseMaintenance(objectTypeId);
    }

    setStateDialog(() {
      item.reasonsList = newReasons; // update the dropdown
      item.spentHours = 0.0;
      item.reading = null;
      item.assetCounterId = null;
      item.rmTypeID = null;
    });
    print(" item.spentHours: ${item.spentHours}");
  }

  bool _isSubmitting = false;
  bool isEditMode = false;
  int? editingId;

  // LogBookModel? currentModel;
  // bool isNoWorkDone = false;
  // bool get isNoWorkDone => isNoWorkDone;

  /// 🔹 INIT
  @override
  void initState() {
    super.initState();
    loadProjects();
    generateLunchTimeOptions();
    loadOperators();
    // addReadingDetail();
    getUomDropdown();
    loadAllAssetCounters();
    loadRmTypes();
    selectedLunch = lunchOptions.first.value; // ✅ important
    lunchTime = selectedLunch!;
  }

  String formatDateForApi(DateTime date) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(date);
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text =
            DateFormat('dd/MM/yyyy').format(picked); // ✅ format

        // API value
        logBookDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> loadProjects() async {
    try {
      int? userId = await SharedPrefsHelper.getUserId();
      int? companyId = await SharedPrefsHelper.getCompanyId();

      if (userId == null || companyId == null) return;

      final projects = await _projectService.fetchProject(userId, companyId);

      setState(() {
        projectList = projects;
        selectedProject = projects.isNotEmpty ? projects[0] : null;
      });

      /// 🔥 DEFAULT DATA LOAD
      if (selectedProject != null) {
        await fetchLogBook(selectedProject!.id);
        await fetchEquipmentsByProjectID(selectedProject!.id);
      }
    } catch (e) {
      print("❌ Error loading projects: $e");
    }
  }

  Future<void> fetchLogBook(int projectId) async {
    setState(() => isLoading = true);

    try {
      final fetched = await _logBookService.getOperatorLogBookByProjectID(
        projectId: projectId,
        sortColumn: 'ID desc',
        pageSize: 100,
        pageIndex: 0,
        isActive: true,
      );

      setState(() {
        logbookData = fetched; // even if empty, it's fine
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching logbook: $e')),
        );
      }
    }
  }

  Future<void> fetchEquipmentsByProjectID(int projectId) async {
    final data = await _logBookService.getAssetMastersByProjectID(projectId);
    setState(() {
      equipmentList = data;
    });
    print(equipmentList);
  }

  Future<void> loadAssetTypes() async {
    try {
      final res = await _logBookService.getAllAssetTypes();

      setState(() {
        assetTypes = res
            .where((x) => x.label != null && x.label!.trim().isNotEmpty)
            .toList();
      });

      // print("🔥 AssetTypes: $assetTypes");
    } catch (e) {
      print("❌ AssetType Error: $e");
    }
  }

  void calculateIdleHour() {
    if (stHour == null || etHour == null) return;

    int start = (stHour! * 60) + (stMinute ?? 0);
    int end = (etHour! * 60) + (etMinute ?? 0);

    String? error;

    double result = 0;

    if (end < start) {
      error = "End time must be greater than Start time";
    } else {
      double diff = ((end - start) / 60) - lunchTime;

      if (diff < 0) {
        error = "Lunch time cannot exceed working hours";
      } else {
        result = diff;
      }
    }

    setState(() {
      errorMessage = error;
      idleHour = result;
    });
  }

  void generateLunchTimeOptions() {
    lunchOptions = List.generate(17, (index) {
      double value = index * 0.25;

      int totalMinutes = (value * 60).round();
      int hrs = totalMinutes ~/ 60;
      int mins = totalMinutes % 60;

      String label;

      if (hrs > 0 && mins > 0) {
        label = "$hrs hr $mins min";
      } else if (hrs > 0) {
        label = "$hrs hr";
      } else {
        label = "$mins min";
      }

      return LunchOption(
        label: label,
        value: value,
      );
    });
  }

  Future<void> loadOperators({bool isNewSearch = false}) async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    if (isNewSearch) {
      pageIndex = 0;
      operatorList.clear();
      hasMore = true;
    }

    final users = await _logBookService.getItemsForUsersDropdown(
        searchQuery, pageIndex, pageSize);

    setState(() {
      if (pageIndex == 0) {
        operatorList = users;
      } else {
        operatorList.addAll(users);
      }

      isLoading = false;

      if (users.length < pageSize) {
        hasMore = false;
      } else {
        pageIndex++;
      }
    });
  }

  Future<void> onReadingChange(
    ReadingDetail item,
    void Function(VoidCallback fn) setStateDialog,
  ) async {
    final equipmentId = selectedEquipment?.id;
    final readingId = item.selectedReading?.id;

    print("equipmentId: $equipmentId");
    print("readingId: $readingId");

    if (equipmentId == null || readingId == null) return;

    setStateDialog(() {
      item.openingController.text = "";
    });

    try {
      final res =
          await _logBookService.getLastClosingReading(equipmentId, readingId);

      print("API Response: $res");

      setStateDialog(() {
        item.openingController.text = (res ?? 0).toString();
      });
    } catch (e) {
      print("❌ API Error: $e");

      setStateDialog(() {
        item.openingController.text = "0";
      });
    }
  }

  List<ReadingType> mapReadingTypes(List data) {
    return data.map<ReadingType>((e) {
      return ReadingType(
        id: e['id'],
        name: e['name'],
      );
    }).toList();
  }

  Future<void> getUomDropdown() async {
    final data = await _logBookService.getUomDropdown();

    setState(() {
      uomList = data;
    });

    print("uomList:$uomList");
  }

  Future<void> onCategoryChange(int? categoryId) async {
    if (categoryId == null) {
      setState(() {
        workDescriptionList = [];
        readingTypesList = [];
        breakdownList = [];
      });
      return;
    }

    final workRes =
        await _logBookService.getWorkDescriptionsByCategoryId(categoryId);

    final readingRes =
        await _logBookService.getReadingsByObjectType(categoryId);

    final breakdownRes =
        await _logBookService.getBreakDownReasons(categoryId); // ✅ only once

    final readingMapped =
        (readingRes as List).map((e) => ReadingType.fromJson(e)).toList();

    final uniqueByName = <String, ReadingType>{};

    for (var item in readingMapped.reversed) {
      if (item.name.isEmpty) continue;
      uniqueByName.putIfAbsent(item.name, () => item);
    }

    setState(() {
      workDescriptionList = workRes;
      readingTypesList = uniqueByName.values.toList();
      breakDownReasonsList = breakdownRes; // ✅ correct
    });

    // /// Debug print
    // for (var e in breakDownReasonsList) {
    //   print('ID: ${e.id}, Name: ${e.name}, Counter: ${e.counterTypeId}');
    // }
  }

  // void calculateHours(WorkDescriptionModel item) {
  //   if (item.fromTime == null || item.toTime == null) {
  //     item.workDownHours.text = "";
  //     return;
  //   }

  //   int from = convertToMinutes(item.fromTime!);
  //   int to = convertToMinutes(item.toTime!);

  //   /// 🔥 HANDLE NEXT DAY
  //   if (to <= from) {
  //     to += 24 * 60; // add 24 hours
  //   }

  //   double diff = (to - from) / 60;

  //   item.workDownHours.text = diff.toStringAsFixed(2);

  //   print("Hours: ${item.workDownHours.text}");
  // }

  void calculateHours(WorkDescriptionModel item) {
    if (item.fromTime == null || item.toTime == null) {
      item.workDownHours.text = "";
      return;
    }

    int from = convertToMinutes(item.fromTime!);
    int to = convertToMinutes(item.toTime!);

    /// ❌ REMOVE NEXT DAY LOGIC
    if (to <= from) {
      item.workDownHours.text = ""; // same as Angular null
      return;
    }

    double diff = (to - from) / 60;

    item.workDownHours.text = diff.toStringAsFixed(2);

    print("Hours: ${item.workDownHours.text}");
  }

  void calculateBreakdownHours(BreakdownModel item) {
    if (item.fromTime == null || item.toTime == null) {
      item.spentHours = null;
      return;
    }

    int from = convertToMinutes(item.fromTime!);
    int to = convertToMinutes(item.toTime!);

    /// ❌ REMOVE NEXT DAY LOGIC (match Angular/backend)
    if (to <= from) {
      item.spentHours = null;
      return;
    }

    double diff = (to - from) / 60;

    item.spentHours = double.parse(diff.toStringAsFixed(2));

    print("SPENT HOURS: ${item.spentHours}");
  }

  int convertToMinutes(String time) {
    final parts = time.split(":");
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Widget buildDropdown(
      List<int> items, int? value, Function(int) onChanged, String hint) {
    return Expanded(
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
        ),
        hint: Text(hint),
        items: items.map((val) {
          return DropdownMenuItem<int>(
            value: val,
            child: Text(val.toString().padLeft(2, '0')),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  Future<void> loadAllAssetCounters() async {
    final res = await _logBookService.getAllAssetCounters();
    final Map<String, AssetCounter> uniqueMap = {};

    for (var item in res.reversed) {
      if ((item.name ?? "").isEmpty) continue;

      uniqueMap.putIfAbsent(item.name!, () => item);
    }

    setState(() {
      assetCountersList = uniqueMap.values.toList();
    });

    print("✅ Unique Counters: ${assetCountersList.map((e) => e.name)}");
  }

  Future<void> loadRmTypes() async {
    final res = await _logBookService.getRmTypes();

    setState(() {
      rmTypesList = res;
    });

    /// 🔥 Debug prints
    print("🔥 RM TYPES LIST:");
    for (var e in rmTypesList) {
      print("ID: ${e.id}, Name: ${e.name}");
    }
  }

  void resetForm() {
    setState(() {
      /// 🔹 Dropdown reset
      isEditMode = false; // 🔥 MUST
      editingId = null; // 🔥 MUST
      selectedEquipment = null;
      selectedAssetType = null;

      /// 🔹 Time reset
      stHour = null;
      stMinute = null;
      etHour = null;
      etMinute = null;

      /// 🔹 Lunch reset
      selectedLunch = null;
      lunchTime = 0;

      /// 🔹 Idle + Work checkbox
      idleHour = 0;
      isNoWorkDone = false;

      /// 🔹 Operator reset
      selectedDayOperator = null;
      selectedNightOperator = null;

      /// 🔹 Remarks
      remarksController.clear();

      /// 🔹 Error reset
      errorMessage = null;

      /// 🔹 Date reset
      dateController.clear();

      /// 🔥 CLEAR LISTS (ONLY ONE WAY)
      readingDetails.clear();
      workList.clear();
      breakdownList.clear();
    });

    print("🔄 Full form reset completed");
  }

  void showValidationToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Closing cannot be less than Opening. Please correct the values!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String? get startTimeString {
    if (stHour == null || stMinute == null) return null;
    return "${stHour!.toString().padLeft(2, '0')}:${stMinute!.toString().padLeft(2, '0')}:00";
  }

  String? get endTimeString {
    if (etHour == null || etMinute == null) return null;
    return "${etHour!.toString().padLeft(2, '0')}:${etMinute!.toString().padLeft(2, '0')}:00";
  }

  String formatTime(String? time) {
    if (time == null) return "";
    return time.length == 5 ? "$time:00" : time; // HH:mm → HH:mm:ss
  }

  Future<void> submitLogBook() async {
    try {
      print("⏳ Submitting LogBook...");

      int? userId = await SharedPrefsHelper.getUserId();
      int? projectId = await SharedPrefsHelper.getProjectID();

      int? existingId = isEditMode ? editingId : null;

      if (!isNoWorkDone) {
        for (int i = 0; i < readingDetails.length; i++) {
          final r = readingDetails[i];

          final opening = double.tryParse(r.openingController.text) ?? 0;
          final closing = double.tryParse(r.closingController.text) ?? 0;

          if (closing < opening) {
            showValidationToast(context);
            return; // STOP SAVE
          }
        }
      }

      final logBook = LogBookModal(
        id: existingId,
        equipmentCategoryID: selectedAssetType?.id,
        equipmentID: selectedEquipment?.id,
        projectID: projectId,
        logBookCode: '',
        operatorID: selectedDayOperator?.id,
        operatorID2: selectedNightOperator?.id,
        createdBy: userId,
        logBookDate: selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
            : null,
        // startTime: startTimeString,
        // endTime: endTimeString,
        startTime: isNoWorkDone ? null : startTimeString,
        endTime: isNoWorkDone ? null : endTimeString,
        remarks: remarksController.text,
        idleHours: double.parse(idleHour.toStringAsFixed(2)),
        lunchHours: double.parse(lunchTime.toStringAsFixed(2)),
        isNoWorkDone: isNoWorkDone ?? false,
        logBookReadingDetails: readingDetails.map((e) {
          return LogBookReadingDetails(
            readingID: e.selectedReading?.id,
            openning: double.tryParse(e.openingController.text) ?? 0,
            closing: double.tryParse(e.closingController.text) ?? 0,
            remarks: e.remarksController.text,
          );
        }).toList(),
        workDescriptionDetails: workList.map((e) {
          return WorkDescriptionDetails(
            fromTime: e.fromTime,
            toTime: e.toTime,
            workDownHours: double.tryParse(e.workDownHours.text.trim()) ?? 0.0,
            workDescriptionID: e.workDescriptionID,
            uomID: e.uomID,
            machineOutput: double.tryParse(e.machineOutput.text.trim()) ?? 0.0,
            remarks: e.remarks.text,
            projectID: projectId,
          );
        }).toList(),
        breakDownDetails: breakdownList.map((e) {
          return BreakDownDetails(
            fromTime: e.fromTime,
            toTime: e.toTime,
            spentHours: e.spentHours ?? 0.0,
            reading: double.tryParse(e.readingsController.text.trim()) ?? 0.0,
            readingID: e.assetCounterId,
            rmTypeID: e.rmTypeID,
            reasonID: e.reasonID,
            typeID: e.typeID,
            remarks: e.remarksController.text,
          );
        }).toList(),
      );

      final json = logBook.toJson();
      print("🔥 FINAL JSON:");
      print(jsonEncode(json));

      bool success;

      if (logBook.id == null || logBook.id == 0) {
        success = await _logBookService.createLogBook(logBook);
      } else {
        success = await _logBookService.updateLogBook(logBook);
      }

      if (success) {
        print("✅ SUCCESS");

        // 1️⃣ Refresh list

        resetForm();
        setState(() {
          showForm = false; // hide form
        });
        print("projectId: $projectId");
        if (projectId != null) {
          print("innnnn: $projectId");
          await fetchLogBook(projectId);
        }
        // 2️⃣ Success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditMode
                  ? "LogBook updated successfully ✅"
                  : "LogBook created successfully ✅"),
              backgroundColor: Colors.green,
            ),
          );
        }

        // 3️⃣ Reset form
      } else {
        print("❌ FAILED");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Something went wrong ❌"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("❌ ERROR: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  EquipmentModel? findEquipment(int? id) {
    print("Finding Equipment for ID: $id");

    try {
      final result = equipmentList.firstWhere((e) => e.id == id);
      print("FOUND Equipment: ${result.displayText}");
      return result;
    } catch (e) {
      print("❌ Equipment NOT FOUND");
      return null;
    }
  }

  AssetTypeModel? findAssetType(int? id) {
    if (id == null) return null;

    try {
      return assetTypes.firstWhere(
        (e) => e.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  Operator? findOperator(int? id) {
    if (id == null) return null;

    try {
      return operatorList.firstWhere(
        (e) => e.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  ReadingType? findReading(int? id) {
    if (id == null) return null;

    try {
      return readingTypesList.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  String extractTime(String? dateTime) {
    if (dateTime == null) return "";

    final dt = DateTime.tryParse(dateTime);
    if (dt == null) return "";

    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

// openEditForm
  Future<void> openEditForm(int id) async {
    try {
      print("⏳ Fetching LogBook by ID: $id");

      setState(() {
        isEditMode = true;
        // isViewMode = false;
        editingId = id;
        showForm = true; // switch to form
      });

      final data = await _logBookService.getOperatorLogBookByID(id);
      print("FULL API DATA: ${data.toJson()}");

      /// 🧾 BASIC FORM FIELDS
      // dateController.text = data.logBookDate != null ? data.logBookDate! : "";
      dateController.text = data.logBookDate != null
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(data.logBookDate!))
          : "";

      remarksController.text = data.remarks ?? "";

      // 1️⃣ Equipment set
      selectedEquipment = findEquipment(data.equipmentID);

// 2️⃣ 🔥 AssetTypes LOAD करो (MISSING STEP)
      await loadAssetTypes();

// 3️⃣ अब category related API call
      await onCategoryChange(data.equipmentCategoryID);

// 4️⃣ अब category set होगी
      selectedAssetType = findAssetType(data.equipmentCategoryID);
      print("API Category ID: ${data.equipmentCategoryID}");
      print("API Equipment ID: ${data.equipmentID}");
      print("Equipment List Length: ${equipmentList.length}");
      print("AssetType List Length: ${assetTypes.length}");
      selectedDayOperator = findOperator(data.operatorID);
      selectedNightOperator = findOperator(data.operatorID2);

      selectedDate = data.logBookDate != null
          ? DateTime.tryParse(data.logBookDate!)
          : null;

      isNoWorkDone = data.isNoWorkDone ?? false;

      /// ⏰ TIME HANDLING
      if (data.startTime != null) {
        final start = data.startTime!.split(":");
        stHour = int.tryParse(start[0]);
        stMinute = int.tryParse(start[1]);
      }

      if (data.endTime != null) {
        final end = data.endTime!.split(":");
        etHour = int.tryParse(end[0]);
        etMinute = int.tryParse(end[1]);
      }

      idleHour = data.idleHours ?? 0;
      lunchTime = data.lunchHours ?? 0;

      selectedLunch = data.lunchHours;

      /// 🧹 CLEAR OLD LISTS
      readingDetails.clear();
      workList.clear();
      breakdownList.clear();

      // 🔥 READINGS
      for (var item in data.logBookReadingDetails ?? []) {
        readingDetails.add(
          ReadingDetail(
            selectedReading: findReading(item.readingID), // 🔥 IMPORTANT
            openingController:
                TextEditingController(text: item.openning?.toString() ?? ""),
            closingController:
                TextEditingController(text: item.closing?.toString() ?? ""),
            remarksController: TextEditingController(text: item.remarks ?? ""),
          ),
        );
      }

      // 🔥 WORK DESCRIPTION
      for (var item in data.workDescriptionDetails ?? []) {
        final from = extractTime(item.fromTime);
        final to = extractTime(item.toTime);

        workList.add(
          WorkDescriptionModel(
            workDescriptionID: item.workDescriptionID,
            uomID: item.uomID,
            projectID: item.projectID,
            fromTime: from,
            toTime: to,
            fromController: TextEditingController(text: from),
            toController: TextEditingController(text: to),
            workDownHours: TextEditingController(
                text: item.workDownHours?.toString() ?? ""),
            machineOutput: TextEditingController(
                text: item.machineOutput?.toString() ?? ""),
            remarks: TextEditingController(text: item.remarks ?? ""),
          ),
        );
      }

      // 🔥 BREAKDOWN
      for (var item in data.breakDownDetails ?? []) {
        final from = extractTime(item.fromTime);
        final to = extractTime(item.toTime);

        breakdownList.add(
          BreakdownModel(
            typeID: item.typeID,
            reasonID: item.reasonID,
            rmTypeID: item.rmTypeID,
            assetCounterId: item.readingID,
            spentHours: item.spentHours,
            fromTime: from,
            toTime: to,
            fromController: TextEditingController(text: from),
            toController: TextEditingController(text: to),
            readingsController:
                TextEditingController(text: item.reading?.toString() ?? ""),
            remarksController: TextEditingController(text: item.remarks ?? ""),
          ),
        );
      }

      /// 🔥 IF EMPTY READINGS
      // if (readingDetails.isEmpty) {
      //   addReadingDetail();
      // }

      setState(() {});

      print("✅ Edit mode loaded successfully");
    } catch (e) {
      print("❌ Error in editRow: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LogBook"),
        centerTitle: true,

        /// 🔥 SHOW BACK ONLY WHEN FORM OPEN
        leading: showForm
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    resetForm(); // 🔥 ADD THIS
                    isEditMode = false; // 🔥 ADD THIS
                    editingId = null; // 🔥 ADD THIS
                    showForm = false;
                  });
                },
              )
            : null,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              loadProjects();
            },
          )
        ],
      ),

      /// 🔥 FLOATING BUTTONS (BOTTOM RIGHT)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (showForm) {
              /// 🔴 Form band → reset
              resetForm();
            } else {
              /// 🟢 New form open → ADD MODE
              isEditMode = false; // 🔥 IMPORTANT
              editingId = null; // 🔥 IMPORTANT
            }

            showForm = !showForm;
          });
        },
        child: Icon(showForm ? Icons.close : Icons.add),
      ),

      /// 🔹 BODY
      body: showForm ? buildFormView() : buildListViewUI(),
    );
  }

  Widget buildListViewUI() {
    return Column(
      children: [
        /// 🔸 PROJECT DROPDOWN
        Padding(
          padding: const EdgeInsets.all(10),
          child: DropdownButtonFormField<Project>(
            value: selectedProject,
            hint: const Text("Select Project"),
            items: projectList.map((project) {
              return DropdownMenuItem(
                value: project,
                child: Text(project.name ?? ""),
              );
            }).toList(),
            onChanged: (value) async {
              setState(() {
                selectedProject = value;
              });

              if (value != null) {
                await SharedPrefsHelper.saveProjectID(value.id);
                await fetchLogBook(value.id);
                await fetchEquipmentsByProjectID(value.id);
              }
            },
          ),
        ),

        /// 🔸 LIST
        Expanded(
          child: buildListView(),
        ),
      ],
    );
  }

  Widget buildFormView() {
    bool isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom, // 🔥 IMPORTANT
        ),
        child: Column(
          children: [
            /// 🔹 EQUIPMENT NAME (SEARCHABLE DROPDOWN)
            DropdownSearch<EquipmentModel>(
                items: equipmentList,
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                ),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Equipment Name",
                    border: OutlineInputBorder(),
                  ),
                ),

                /// 👇 IMPORTANT (displayText show karega)
                itemAsString: (item) => item.displayText ?? "",
                selectedItem: selectedEquipment,
                onChanged: (value) async {
                  setState(() {
                    selectedEquipment = value;
                    selectedAssetType = null;
                  });

                  await loadAssetTypes();

                  final match = assetTypes.firstWhere(
                    (item) =>
                        (item.value ?? "").trim() ==
                        (value?.assetType ?? "").trim(),
                    orElse: () => AssetTypeModel(id: 0),
                  );

                  if (match.id != 0) {
                    setState(() {
                      selectedAssetType = match;
                    });

                    // 🔥🔥 YAHI MAIN FIX
                    // print("🔥 Auto Selected Category: ${match.value}");

                    await onCategoryChange(match.id); // ✅ CALL HERE
                  }
                }),

            const SizedBox(height: 10),
            DropdownSearch<AssetTypeModel>(
              items: assetTypes,

              popupProps: const PopupProps.menu(showSearchBox: true),

              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Equipment Category",
                  border: OutlineInputBorder(),
                ),
              ),

              itemAsString: (item) => item.displayText ?? "",

              selectedItem: selectedAssetType,

              /// 🔥 DISABLE UNTIL EQUIPMENT SELECT
              enabled: false,

              onChanged: (value) {
                setState(() {
                  selectedAssetType = value;
                });
              },
            ),

            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Working Time",
                        style: TextStyle(fontWeight: FontWeight.bold)),

                    SizedBox(height: 10),

                    AbsorbPointer(
                      absorbing: isNoWorkDone,
                      child: Opacity(
                        opacity: isNoWorkDone ? 0.5 : 1.0,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            /// Start Time
                            SizedBox(
                              width: isTablet ? 250 : double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Start Time",
                                      style: TextStyle(color: Colors.green)),
                                  Row(
                                    children: [
                                      buildDropdown(hours, stHour,
                                          (v) => updateTime(sH: v), "HH"),
                                      SizedBox(width: 5),
                                      buildDropdown(minutes, stMinute,
                                          (v) => updateTime(sM: v), "MM"),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            /// End Time
                            SizedBox(
                              width: isTablet ? 250 : double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("End Time",
                                      style: TextStyle(color: Colors.red)),
                                  Row(
                                    children: [
                                      buildDropdown(hours, etHour,
                                          (v) => updateTime(eH: v), "HH"),
                                      SizedBox(width: 5),
                                      buildDropdown(minutes, etMinute,
                                          (v) => updateTime(eM: v), "MM"),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            /// Lunch
                            SizedBox(
                              width: isTablet ? 200 : double.infinity,
                              child: DropdownButtonFormField<double>(
                                value: selectedLunch,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: "Lunch (hrs)",
                                ),
                                hint: Text("Select Lunch Time"),
                                items: lunchOptions.map((item) {
                                  return DropdownMenuItem<double>(
                                    value: item.value,
                                    child: Text(item.label),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedLunch = val;
                                    lunchTime = val ?? 0;
                                  });

                                  calculateIdleHour();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// Error
                    if (errorMessage != null)
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(errorMessage!,
                            style: TextStyle(color: Colors.red)),
                      ),

                    SizedBox(height: 10),

                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "dd/mm/yyyy",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => pickDate(context),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10),

            /// Idle Hour Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    /// Idle Hours
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        formatHours(idleHour),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                    SizedBox(height: 10),

                    /// No Work Done
                    Row(
                      children: [
                        Checkbox(
                          value: isNoWorkDone,
                          onChanged: (val) {
                            setState(() {
                              isNoWorkDone = val ?? false;

                              if (isNoWorkDone) {
                                // RESET ALL FIELDS
                                stHour = null;
                                stMinute = null;

                                etHour = null;
                                etMinute = null;

                                selectedLunch = null;
                                lunchTime = 0;

                                /// 🔥 CLEAR ALL DATA
                                readingDetails.clear();
                                workList.clear(); // ✅ FIX HERE
                                breakdownList
                                    .clear(); // (only if this is actual UI list)
                              }
                            });
                          },
                        ),
                        Text("No Work Done"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10),

            DropdownSearch<Operator>(
              items: operatorList,
              selectedItem: selectedDayOperator,
              itemAsString: (Operator u) => u.userName,
              onChanged: (Operator? value) {
                setState(() {
                  selectedDayOperator = value;
                });
              },
              popupProps: PopupProps.menu(
                showSearchBox: true,
              ),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Operator (Day Shift) *",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            SizedBox(height: 10),

            DropdownSearch<Operator>(
              items: operatorList,
              selectedItem: selectedNightOperator,
              itemAsString: (Operator u) => u.userName,
              onChanged: (Operator? value) {
                setState(() {
                  selectedNightOperator = value;
                });
              },
              popupProps: PopupProps.menu(
                showSearchBox: true,
              ),
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Operator (Night Shift) *",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 10),

            TextField(
              controller: remarksController,
              maxLines: 3, // multiline like textarea
              decoration: InputDecoration(
                labelText: "Remarks",
                hintText: "Enter remarks",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            buildReadingSummary(),
            SizedBox(height: 10),
            buildWorkSummary(),
            SizedBox(height: 10),
            buildBreakDownSummary(),

            /// 🔹 SAVE BUTTON
            ElevatedButton(
              onPressed: () {
                submitLogBook();
              },
              child: Text(isEditMode ? "Update" : "Submit"),
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget buildReadingSummary() {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            /// 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Readings (${readingDetails.length})",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: isNoWorkDone ? null : () => openReadingPopup(),
                  child: Text("+ Add Reading"),
                ),
              ],
            ),

            SizedBox(height: 10),

            /// 🔹 EMPTY
            if (readingDetails.isEmpty)
              Padding(
                padding: EdgeInsets.all(20),
                child: Text("No readings added"),
              ),

            /// 🔹 LIST
            if (readingDetails.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: readingDetails.length,
                itemBuilder: (context, index) {
                  final item = readingDetails[index];

                  final readingName = item.selectedReading?.name ?? "-";

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🔹 TOP ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                readingName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    openReadingPopup(
                                      editItem: item,
                                      index: index,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      readingDetails.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            )
                          ],
                        ),

                        SizedBox(height: 6),

                        /// 🔹 DETAILS
                        Text("Opening: ${item.openingController.text}"),
                        Text("Closing: ${item.closingController.text}"),
                        Text(
                            "Remarks: ${item.remarksController.text.isEmpty ? "-" : item.remarksController.text}"),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void openReadingPopup({ReadingDetail? editItem, int? index}) {
    ReadingDetail item = editItem ?? ReadingDetail();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 400,
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔹 TITLE
                      Center(
                        child: Text(
                          editItem == null ? "Add Reading" : "Edit Reading",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: 10),
                      Divider(),

                      /// 🔹 READING DROPDOWN
                      DropdownSearch<ReadingType>(
                        items: readingTypesList,
                        selectedItem: item.selectedReading,
                        itemAsString: (r) => r.name ?? "",
                        popupProps: PopupProps.menu(showSearchBox: true),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "Reading",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        onChanged: (value) async {
                          setStateDialog(() {
                            item.selectedReading = value;
                          });

                          await onReadingChange(
                              item, setStateDialog); // 🔥 no index
                        },
                      ),

                      SizedBox(height: 12),

                      /// 🔹 OPENING
                      TextFormField(
                        controller: item.openingController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Opening",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      SizedBox(height: 12),

                      /// 🔹 CLOSING
                      TextFormField(
                        controller: item.closingController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Closing",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      SizedBox(height: 12),

                      /// 🔹 REMARKS
                      TextFormField(
                        controller: item.remarksController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Remarks",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      SizedBox(height: 16),

                      /// 🔹 SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (editItem != null && index != null) {
                                readingDetails[index] = item;
                              } else {
                                readingDetails.add(item);
                              }
                            });

                            Navigator.pop(context);
                          },
                          child: Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildWorkSummary() {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            /// 🔹 Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Work Description (${workList.length})",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                ElevatedButton(
                  onPressed: isNoWorkDone ? null : () => openWorkFormPopup(),
                  child: Text("+ Add Work"),
                ),
              ],
            ),

            SizedBox(height: 10),

            /// 🔹 LIST
            workList.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No work added"),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: workList.length,
                    itemBuilder: (context, index) {
                      final item = workList[index];

                      /// 🔥 Selected Work Name nikalna
                      final selectedWorkList = workDescriptionList
                          .where((e) => e.id == item.workDescriptionID)
                          .toList();

                      final workName = selectedWorkList.isNotEmpty
                          ? selectedWorkList.first.name
                          : "No Work Selected";

                      final uom =
                          uomList.where((e) => e.id == item.uomID).toList();

                      final uomSymbol = uom.isNotEmpty ? uom.first.symbol : "-";

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    workName ?? "No Work Selected",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    openWorkFormPopup(
                                      editItem: item,
                                      index: index,
                                    );
                                  },
                                ),

                                /// 🔥 DELETE BUTTON
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      workList.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),

                            // /// 🔹 1. WORK NAME (TOP)
                            // Text(
                            //   workName ?? "No Work Selected",
                            //   style: TextStyle(
                            //     fontWeight: FontWeight.bold,
                            //     fontSize: 15,
                            //   ),
                            // ),

                            SizedBox(height: 8),

                            /// 🔹 2. FROM - TO
                            Row(
                              children: [
                                Expanded(
                                  child: Text("From: ${item.fromTime ?? "-"}"),
                                ),
                                Expanded(
                                  child: Text("To: ${item.toTime ?? "-"}"),
                                ),
                                Expanded(
                                  child: Text(
                                    "Hours: ${item.workDownHours.text.isEmpty ? "-" : item.workDownHours.text}",
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 6),

                            /// 🔹 3. HOURS / OUTPUT / UOM
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Output: ${item.machineOutput.text.isEmpty ? "-" : item.machineOutput.text}",
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "UOM: ${uomSymbol ?? "-"}",
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 6),

                            /// 🔹 4. REMARKS (LAST)
                            Text(
                              "Remark: ${item.remarks.text.isEmpty ? "-" : item.remarks.text}",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void openWorkFormPopup({WorkDescriptionModel? editItem, int? index}) {
    WorkDescriptionModel item =
        editItem ?? (WorkDescriptionModel()..projectID = selectedProject?.id);
    bool isChecked = item.allowProjectChange ?? false;

    if (editItem != null) {
      item.fromController.text = editItem.fromTime ?? "";
      item.toController.text = editItem.toTime ?? "";
      item.workDownHours.text = editItem.workDownHours.text;
      item.remarks.text = editItem.remarks.text;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // bool isChecked = item.allowProjectChange ?? false;
            return Dialog(
              child: Container(
                // 🔥 Dialog me Container use karo
                width: 500,
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// HEADER
                      Center(
                        child: Text(
                          "Add Work",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),

                      SizedBox(height: 10),
                      Divider(),

                      /// WORK
                      DropdownButtonFormField<int>(
                        value: item.workDescriptionID,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Work",
                          border: OutlineInputBorder(),
                        ),
                        items: workDescriptionList.map((e) {
                          return DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name ?? ""),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            item.workDescriptionID = val;
                            print("Selected Work ID changed to: $val");
                          });
                        },
                      ),

                      SizedBox(height: 12),

                      /// FROM | TO | HOURS
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item.fromController, // ✅ important
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "From",
                                border: OutlineInputBorder(),
                              ),
                              onTap: () async {
                                TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    final time =
                                        "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";

                                    item.fromTime = time;
                                    item.fromController.text =
                                        time; // 🔥 UI update
                                    calculateHours(item);
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item.toController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "To",
                                border: OutlineInputBorder(),
                              ),
                              onTap: () async {
                                TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    final time =
                                        "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";

                                    item.toTime = time;
                                    item.toController.text =
                                        time; // 🔥 UI update
                                    calculateHours(item);
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item.workDownHours,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "Hours",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      /// OUTPUT + UOM
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item.machineOutput,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Output",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: "UOM",
                                border: OutlineInputBorder(),
                              ),
                              value: item.uomID,
                              items: uomList.map((e) {
                                return DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.symbol ?? ""),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setStateDialog(() {
                                  // 🔥 FIX
                                  item.uomID = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      /// CHECKBOX

                      Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            onChanged: (val) {
                              setStateDialog(() {
                                isChecked = val!;
                                item.allowProjectChange =
                                    val; // ✅ sync with model
                              });
                            },
                          ),
                          Text("Change Project?")
                        ],
                      ),

                      /// PROJECT DROPDOWN
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: "Project",
                          border: OutlineInputBorder(),
                        ),
                        value: item.projectID,
                        isExpanded: true,

                        /// ✅ SAME VARIABLE USE
                        onChanged: isChecked
                            ? null // disable
                            : (val) {
                                setStateDialog(() {
                                  item.projectID = val;
                                });
                              },

                        items: projectList.map((e) {
                          return DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name ?? ""),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 12),

                      /// DESCRIPTION
                      TextFormField(
                        controller: item.remarks,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      SizedBox(height: 16),

                      /// SAVE
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (editItem != null && index != null) {
                                /// 🔥 EDIT
                                workList[index] = item;
                              } else {
                                /// 🔥 ADD
                                workList.add(item);
                              }
                            });

                            Navigator.pop(context);
                          },
                          child: Text("Save"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildBreakDownSummary() {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            /// 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Breakdown (${breakdownList.length})",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                ElevatedButton(
                  onPressed: isNoWorkDone
                      ? null
                      : () => openBreakdownFormPopup(
                            categoryId: selectedAssetType!.id,
                          ),
                  child: Text("+ Add Breakdown"),
                ),
              ],
            ),

            SizedBox(height: 10),

            /// 🔹 EMPTY
            breakdownList.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No breakdown added"),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: breakdownList.length,
                    itemBuilder: (context, index) {
                      final item = breakdownList[index];
                      print("ReasonID: ${item.reasonID}");
                      print("ReasonsList Length: ${item.reasonsList.length}");

                      /// 🔥 TYPE NAME
                      final typeName = breakdownTypeList
                              .where((e) => e.id == item.typeID)
                              .isNotEmpty
                          ? breakdownTypeList
                              .firstWhere((e) => e.id == item.typeID)
                              .name
                          : "-";

                      /// 🔥 REASON NAME
                      final reasonName = breakDownReasonsList
                              .firstWhere(
                                (e) => e.id == item.reasonID,
                                orElse: () => BreakDownReason(name: "-"),
                              )
                              .name ??
                          "-";

                      final counterName = assetCountersList
                              .where((e) => e.id == item.assetCounterId)
                              .isNotEmpty
                          ? assetCountersList
                              .firstWhere((e) => e.id == item.assetCounterId)
                              .name
                          : "-";

                      final rmName = rmTypesList
                              .where((e) => e.id == item.rmTypeID)
                              .isNotEmpty
                          ? rmTypesList
                              .firstWhere((e) => e.id == item.rmTypeID)
                              .name
                          : "-";

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 🔹 TOP ROW (TYPE + ACTIONS)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    typeName ?? "-",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    /// ✏️ EDIT
                                    IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.blue),
                                      onPressed: selectedAssetType == null
                                          ? null
                                          : () {
                                              openBreakdownFormPopup(
                                                categoryId:
                                                    selectedAssetType!.id,
                                                editItem: item,
                                                index: index,
                                              );
                                            },
                                    ),

                                    /// 🗑 DELETE
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          breakdownList.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),

                            SizedBox(height: 8),

                            /// 🔹 FROM - TO - HOURS
                            Row(
                              children: [
                                Expanded(
                                  child: Text("From: ${item.fromTime ?? "-"}"),
                                ),
                                Expanded(
                                  child: Text("To: ${item.toTime ?? "-"}"),
                                ),
                                Expanded(
                                  child: Text(
                                    "Reading: ${item.readingsController.text.isEmpty ? "-" : item.readingsController.text}",
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 6),

                            /// 🔹 REASON + READING
                            Row(
                              children: [
                                Expanded(
                                  child: Text("Reason: $reasonName"),
                                ),
                                Expanded(
                                  child: Text("Counter: $counterName"),
                                ),
                              ],
                            ),

                            SizedBox(height: 6),

                            /// 🔹 REASON + READING
                            Row(
                              children: [
                                Expanded(
                                  child: Text("R&M Type: $rmName"),
                                ),
                                // Expanded(
                                //   child: Text("Counter: $counterName"),
                                // ),
                              ],
                            ),
                            SizedBox(height: 6),

                            /// 🔹 REMARKS
                            Text(
                              "Remark: ${item.remarksController.text.isEmpty ? "-" : item.remarksController.text}",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void openBreakdownFormPopup({
    required int categoryId, // 🔹 pass category here
    BreakdownModel? editItem,
    int? index,
  }) async {
    BreakdownModel item = editItem ?? BreakdownModel();

    /// 🔥 EDIT MODE FIX
    if (editItem != null) {
      item = editItem;

      List<BreakDownReason> newReasons = [];

      if (item.typeID == 1) {
        newReasons = await _logBookService.getBreakDownReasons(categoryId);
      } else if (item.typeID == 2) {
        newReasons = await _logBookService.getInHouseMaintenance(categoryId);
      }

      item.reasonsList = newReasons; // ✅ IMPORTANT
    } else {
      item.typeID = 1;
      item.reasonsList = breakDownReasonsList;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void onTimeChanged() {
              if (item.typeID == 1) {
                calculateBreakdownHours(item);
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 500,
                padding: EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔹 TITLE
                      Center(
                        child: Text(
                          editItem == null ? "Add Breakdown" : "Edit Breakdown",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: 10),
                      Divider(),

                      /// 🔹 TYPE
                      DropdownButtonFormField<int>(
                        value: item.typeID,
                        decoration: InputDecoration(
                          labelText: "Type",
                          border: OutlineInputBorder(),
                        ),
                        items: breakdownTypeList.map((e) {
                          return DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name),
                          );
                        }).toList(),
                        onChanged: (val) => onTypeChanged(
                          item,
                          val,
                          categoryId, // 🔹 pass category here
                          setStateDialog,
                        ),
                      ),

                      SizedBox(height: 12),

                      /// 🔹 REASON
                      DropdownButtonFormField<int>(
                        value:
                            item.reasonsList.any((e) => e.id == item.reasonID)
                                ? item.reasonID
                                : null,
                        decoration: InputDecoration(
                          labelText: "Reason",
                          border: OutlineInputBorder(),
                        ),
                        items: item.reasonsList.map<DropdownMenuItem<int>>((e) {
                          return DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(e.name ?? ""),
                          );
                        }).toList(),
                        onChanged: item.reasonsList.isEmpty
                            ? null
                            : (val) {
                                setStateDialog(() {
                                  item.reasonID = val;
                                  print('Selected reasonID: $val');
                                });
                              },
                      ),

                      // ... rest of your fields (From/To/Hours/Reading/Remarks)

                      SizedBox(height: 16),

                      /// 🔹 FROM / TO / HOURS
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item.fromController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "From",
                                border: OutlineInputBorder(),
                              ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  final time =
                                      "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                  item.fromTime = time;
                                  item.fromController.text = time;
                                  onTimeChanged();
                                  setStateDialog(() {});
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item.toController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "To",
                                border: OutlineInputBorder(),
                              ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  final time =
                                      "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                  item.toTime = time;
                                  item.toController.text = time;
                                  onTimeChanged();
                                  setStateDialog(() {});
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: item.readingsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Reading",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      /// 🔹 READING
                      DropdownButtonFormField<int>(
                        value: item.assetCounterId,
                        decoration: InputDecoration(
                          labelText: "Reading",
                          border: OutlineInputBorder(),
                        ),
                        items: assetCountersList.map((e) {
                          return DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(e.name ?? ""),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            item.assetCounterId = val;
                            print("Selected Counter: $val");
                          });
                        },
                      ),

                      SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: item.rmTypeID,
                        decoration: InputDecoration(
                          labelText: "RM Type",
                          border: OutlineInputBorder(),
                        ),
                        items: rmTypesList.map((e) {
                          return DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(e.name ?? ""),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            item.rmTypeID = val;
                            print("✅ Selected RM Type ID: $val");
                          });
                        },
                      ),
                      SizedBox(height: 12),

                      /// 🔹 REMARKS
                      TextFormField(
                        controller: item.remarksController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Remarks",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      /// 🔹 SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              if (editItem != null && index != null) {
                                breakdownList[index] = item;
                              } else {
                                breakdownList.add(item);
                              }
                            });
                            Navigator.pop(context);
                          },
                          child: Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 🔹 LIST VIEW
  Widget buildListView() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (logbookData.isEmpty) {
      return const Center(child: Text("No Data Found"));
    }

    return ListView.builder(
      itemCount: logbookData.length,
      itemBuilder: (context, index) {
        final item = logbookData[index];

        /// 🔥 DATE FORMAT
        String formattedDate = "--";
        if (item.logBookDate != null) {
          final date = DateTime.tryParse(item.logBookDate!);
          if (date != null) {
            formattedDate = "${date.day.toString().padLeft(2, '0')}/"
                "${date.month.toString().padLeft(2, '0')}/"
                "${date.year}";
          }
        }

        return InkWell(
          onTap: () {
            openEditForm(item.id!);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔴 ROW 1 (FULL WIDTH) → Log Book Code
                  Row(
                    children: [
                      const Text(
                        "Log Book Code: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(item.logBookCode ?? "--"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// 🔴 ROW 2 (FULL WIDTH) → Date
                  Row(
                    children: [
                      const Text(
                        "Log Book Date: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(formattedDate),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// 🔴 ROW 3 (HALF + HALF) → Start / End Time
                  Row(
                    children: [
                      /// LEFT (col-md-6)
                      Expanded(
                        child: Row(
                          children: [
                            const Text(
                              "Start Time: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(item.startTime ?? "--"),
                          ],
                        ),
                      ),

                      /// RIGHT (col-md-6)
                      Expanded(
                        child: Row(
                          children: [
                            const Text(
                              "End Time: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(item.endTime ?? "--"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// 🔴 ROW 4 → Category Name
                  Row(
                    children: [
                      const Text(
                        "Category Name: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(item.name ?? "--"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// 🔴 ROW 5 → Status
                  Row(
                    children: [
                      const Text(
                        "Status: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item.isNoWorkDone == true ? "No Work Done" : "Working",
                        style: TextStyle(
                          color: item.isNoWorkDone == true
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
////////////////////////////
