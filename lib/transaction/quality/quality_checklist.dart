import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:himappnew/model/project_model.dart';
import 'package:himappnew/model/quality_checklist.dart';
import 'package:himappnew/service/company_service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:himappnew/transaction/quality/quality_checklist_service.dart';

import 'package:intl/intl.dart';

class QualityChecklistPage extends StatefulWidget {
  const QualityChecklistPage({Key? key}) : super(key: key);

  @override
  State<QualityChecklistPage> createState() => _QualityChecklistPageState();
}

class PointModel {
  int pointID;
  String pointName;
  int? answerId;
  DateTime? workDate;

  TextEditingController workDateController = TextEditingController();
  TextEditingController remarkController = TextEditingController();

  PointModel({
    required this.pointID,
    required this.pointName,
    this.answerId,
  });
}

// class SectionModel {
//   String sectionName;
//   List<PointModel> points;

//   SectionModel({
//     required this.sectionName,
//     required this.points,
//   });
// }

class SectionModel {
  int sectionID;
  String sectionName;
  List<PointModel> points;

  SectionModel({
    required this.sectionID,
    required this.sectionName,
    required this.points,
  });
}

class _QualityChecklistPageState extends State<QualityChecklistPage> {
  bool isLoading = true;

  List<Project> projectList = [];
  Project? selectedProject;

  final CompanyService _companyService = CompanyService();
  final ProjectService _projectService = ProjectService();
  final QualityChecklistService _qualityChecklistService =
      QualityChecklistService();

  List<QualityChecklist> checklists = []; // Dummy data

  final dateFormat = DateFormat('dd/MM/yyyy');
  bool isAddMode = false; // 👈 state variable

  final TextEditingController checklistCodeController = TextEditingController();
  final TextEditingController checklistDateController = TextEditingController();
  final TextEditingController equipmentController = TextEditingController();
  final TextEditingController drawingNoController = TextEditingController();
  bool showForm = false;
  DateTime? selectedDate;

  List<ChecklistMapping> checklistMappingList = [];
  ChecklistMapping? selectedChecklistMapping;

  final List<FrequencyOption> frequencyOptions = [
    FrequencyOption(label: 'Daily', value: 1),
    FrequencyOption(label: 'Weekly', value: 2),
    FrequencyOption(label: 'Monthly', value: 3),
  ];
  FrequencyOption? selectedFrequency;

  Map<String, dynamic> mappingConfig = {};

  List<AreaModel> areaData = [];
  List<ElementModel> elementData = [];

  AreaModel? selectedArea;
  ElementModel? selectedElement;

  List<FloorModel> floorData = [];
  List<PartModel> partData = [];

  FloorModel? selectedFloor;
  PartModel? selectedPart;

  void applyMappingConfig(dynamic res) {
    setState(() {
      mappingConfig = {
        "isAreaVisible": res['isAreaVisible'],
        "isAreaRequired": res['isAreaRequired'],
        "isFloorVisible": res['isFloorVisible'],
        "isFloorRequired": res['isFloorRequired'],
        "isPourVisible": res['isPourVisible'],
        "isPourRequired": res['isPourRequired'],
        "isSectionVisible": res['isSectionVisible'],
        "isSectionRequired": res['isSectionRequired'],
        "isEquipmentVisible": res['isEquipmentVisible'],
        "isEquipmentRequired": res['isEquipmentRequired'],
        "isDrawingNoVisible": res['isDrawingNoVisible'],
        "isDrawingNoRequired": res['isDrawingNoRequired'],
      };
    });
  }

  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  List<SectionModel> sectionList = [];
  List<SectionMaster> sectionMasterList = [];

  bool showChecklistPoints = false;
  // List<SectionModel> sectionList = [
  //   // SectionModel(
  //   //   sectionName: "Safety",
  //   //   points: [
  //   //     PointModel(pointName: "Helmet used?"),
  //   //     PointModel(pointName: "Gloves worn?"),
  //   //   ],
  //   // ),
  //   SectionModel(
  //     sectionName: "Quality",
  //     points: [
  //       PointModel(pointName: "Material OK?"),
  //       PointModel(pointName: "Work proper?"),
  //     ],
  //   ),
  // ];

  bool areAllAnswersFilled() {
    for (var section in sectionList) {
      for (var point in section.points) {
        if (point.answerId == null) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    fetchProjects();
    loadChecklistMapping();
    loadAreaAndElement();
    loadFloorAndPart();
    startDate = DateTime.now();
    startDateController.text = dateFormat.format(startDate!); // 👈 auto fill
  }

  Future<void> fetchProjects() async {
    try {
      int? userId = await SharedPrefsHelper.getUserId();
      int? companyId = await SharedPrefsHelper.getCompanyId();

      if (userId == null || companyId == null) {
        setState(() => isLoading = false);
        return;
      }

      List<Project> projects =
          await _projectService.fetchProject(userId, companyId);

      setState(() {
        projectList = projects;
        selectedProject = projects.isNotEmpty ? projects[0] : null;
        isLoading = false;
      });

      if (projects.isNotEmpty) {
        await SharedPrefsHelper.saveProjectID(projects[0].id);
        await fetchQualityChecklists(projects[0].id);
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching projects: $e");
    }
  }

  Future<void> fetchQualityChecklists(int projectId) async {
    setState(() => isLoading = true);
    try {
      final fetched = await _qualityChecklistService.fetchQualityChecklists(
        projectId: projectId,
        sortColumn: 'ID desc',
        pageSize: 100,
        pageIndex: 0,
        isActive: true,
      );
      if (fetched.isEmpty) {
        // Table1 is empty, so no observations
        setState(() => checklists = []);
      } else {
        setState(() => checklists = fetched);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching labours: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadChecklistMapping() async {
    try {
      final data = await _qualityChecklistService.fetchChecklistMapping();

      setState(() {
        checklistMappingList = data;
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> loadAreaAndElement() async {
    try {
      final areas = await _qualityChecklistService.fetchAreas();
      final elements = await _qualityChecklistService.fetchElements();
      // print("Areas: ${areas.length}, Elements: ${elements.length}");
      setState(() {
        areaData = areas;
        elementData = elements;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> loadFloorAndPart() async {
    try {
      final floors = await _qualityChecklistService.fetchFloors();
      final parts = await _qualityChecklistService.fetchParts();

      setState(() {
        floorData = floors;
        partData = parts;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> onChecklistMappingChange(ChecklistMapping selected) async {
    if (selected.id == null) return;

    try {
      final res =
          await _qualityChecklistService.getChecklistMappingById(selected.id);

      // 🔹 1. Mapping config apply (IMPORTANT)
      applyMappingConfig(res);

      // 🔹 2. Dependent dropdown load
      await loadAreaAndElement();
      await loadFloorAndPart();

      // 🔹 3. Section + Points build
      final details = res["checkListProjectMappingDetails"] ?? [];

      Map<int, SectionModel> grouped = {};

      for (var item in details) {
        int sectionId = item["checkListSectionID"];
        int pointId = item["checkListPointID"];

        if (!grouped.containsKey(sectionId)) {
          grouped[sectionId] = SectionModel(
            sectionID: sectionId,
            sectionName: "Section $sectionId",
            points: [],
          );
        }

        grouped[sectionId]!.points.add(
              PointModel(
                pointID: pointId,
                pointName: "Point $pointId",
              ),
            );
      }

      setState(() {
        sectionList = grouped.values.toList();
      });
    } catch (e) {
      print("Error: $e");
    }
  }
//   Future<void> loadAreaAndElement() async {
//   areaData = await fetchAreas();
//   elementData = await fetchElements();
//   setState(() {});
// }

  Widget buildForm() {
    return Expanded(
      // 👈 IMPORTANT (fix overflow)
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 Checklist Code
                TextField(
                  controller: checklistCodeController,
                  decoration: const InputDecoration(
                    labelText: "Checklist Code",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                /// 🔹 Date
                TextField(
                  controller: checklistDateController,
                  readOnly: true,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                        checklistDateController.text =
                            dateFormat.format(picked);
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: "Checklist Date",
                    hintText: "DD/MM/YYYY",
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                /// 🔹 Checklist For
                DropdownButtonFormField<ChecklistMapping>(
                  value: selectedChecklistMapping,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Checklist For *",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: checklistMappingList.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        "${item.checklistFor} (${item.mappingCode})",
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      selectedChecklistMapping = value;
                    });

                    if (value != null) {
                      await onChecklistMappingChange(value);
                      await loadSectionList(value.id!);
                    }
                  },
                ),
                const SizedBox(height: 12),

                /// 🔹 Frequency
                DropdownButtonFormField<FrequencyOption>(
                  value: selectedFrequency,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Frequency",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: frequencyOptions.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFrequency = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                /// 🔥 AREA
                if (mappingConfig["isAreaVisible"] == true) ...[
                  DropdownSearch<AreaModel>(
                    items: areaData,
                    selectedItem: selectedArea,
                    itemAsString: (item) => item.sectionName,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: mappingConfig["isAreaRequired"] == true
                            ? "Area *"
                            : "Area",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => selectedArea = value);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                /// 🔥 ELEMENT
                if (mappingConfig["isSectionVisible"] == true) ...[
                  DropdownSearch<ElementModel>(
                    items: elementData,
                    selectedItem: selectedElement,
                    itemAsString: (item) => item.elementName,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: mappingConfig["isSectionRequired"] == true
                            ? "Element *"
                            : "Element",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => selectedElement = value);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                /// 🔥 FLOOR
                if (mappingConfig["isFloorVisible"] == true) ...[
                  DropdownSearch<FloorModel>(
                    items: floorData,
                    selectedItem: selectedFloor,
                    itemAsString: (item) => item.floorName,
                    popupProps: const PopupProps.menu(showSearchBox: true),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: mappingConfig["isFloorRequired"] == true
                            ? "Floor *"
                            : "Floor",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => selectedFloor = value);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                /// 🔥 POUR
                if (mappingConfig["isPourVisible"] == true) ...[
                  DropdownButtonFormField<PartModel>(
                    value: selectedPart,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: mappingConfig["isPourRequired"] == true
                          ? "Pour *"
                          : "Pour",
                      border: const OutlineInputBorder(),
                    ),
                    items: partData.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item.partName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedPart = value);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                /// 🔥 Equipment
                if (mappingConfig["isEquipmentVisible"] == true) ...[
                  TextField(
                    controller: equipmentController,
                    decoration: InputDecoration(
                      labelText: mappingConfig["isEquipmentRequired"] == true
                          ? "Equipment *"
                          : "Equipment",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                /// 🔥 Drawing
                if (mappingConfig["isDrawingNoVisible"] == true) ...[
                  TextField(
                    controller: drawingNoController,
                    decoration: InputDecoration(
                      labelText: mappingConfig["isDrawingNoRequired"] == true
                          ? "Drawing Number *"
                          : "Drawing Number",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                /// 🔥 Start Date
                TextField(
                  controller: startDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Start Date *",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                /// 🔥 End Date
                TextField(
                  controller: endDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText:
                        endDateController.text.isNotEmpty ? "End Date" : null,
                    hintText: "DD/MM/YYYY",
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showChecklistPoints = !showChecklistPoints; // 🔥 toggle
                    });
                  },
                  child: const Text("Checklist Points Details"),
                ),
                const SizedBox(height: 10),

                /// 🔥 YAHI ADD KARNA HAI
                if (showChecklistPoints) buildChecklistSection(),
                const SizedBox(height: 16),

                /// 🔥 Submit
                SizedBox(
                  width: double.infinity,
                  height: 48, // 👈 better touch area
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => showForm = false);
                      await fetchQualityChecklists(selectedProject!.id);
                    },
                    child: const Text("Submit"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void printFinalData() {
    for (var section in sectionList) {
      for (var point in section.points) {
        print({
          "pointName": point.pointName,
          "answerId": point.answerId,
          "workDate": point.workDate?.toString(),
          "remark": point.remarkController.text,
        });
      }
    }
  }

  Future<void> loadSectionList(int mappingId) async {
    final res = await _qualityChecklistService.getSectionList(mappingId);

    // 🔥 duplicate remove karna (important)
    final unique = <int, SectionMaster>{};

    for (var item in res) {
      unique[item["id"]] = SectionMaster(
        id: item["id"],
        name: item["sectionName"], // 👈 EXACT Angular jaisa
      );
    }

    setState(() {
      sectionMasterList = unique.values.toList();
    });
  }

  // Widget buildChecklistPopup(Function setStateDialog) {
  //   return Dialog(
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Container(
  //       padding: const EdgeInsets.all(16),
  //       width: double.maxFinite,
  //       height: MediaQuery.of(context).size.height * 0.7,
  //       child: Column(
  //         children: [
  //           /// 🔹 Header
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               const Text(
  //                 "Checklist Points",
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //               IconButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 icon: const Icon(Icons.close),
  //               )
  //             ],
  //           ),

  //           const SizedBox(height: 10),

  //           /// 🔹 LIST
  //           Expanded(
  //             child: sectionList.isEmpty
  //                 ? const Center(child: Text("No Data"))
  //                 : ListView.builder(
  //                     itemCount: sectionList.length,
  //                     itemBuilder: (context, index) {
  //                       return buildSectionCard(
  //                           sectionList[index], setStateDialog);
  //                     },
  //                   ),
  //           ),

  //           /// 🔥 👇 YAHI ADD KARNA THA (STEP 5)
  //           const SizedBox(height: 10),

  //           SizedBox(
  //             width: double.infinity,
  //             child: ElevatedButton(
  //               onPressed: () {
  //                 if (!areAllAnswersFilled()) {
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(content: Text("Please fill all answers")),
  //                   );
  //                   return;
  //                 }

  //                 Navigator.pop(context); // 👈 close popup
  //                 printFinalData(); // 👈 data ready
  //               },
  //               child: const Text("Save"),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget buildChecklistSection() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          /// 🔹 Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Checklist Points",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    showChecklistPoints = false;
                  });
                },
                icon: const Icon(Icons.close),
              )
            ],
          ),

          const SizedBox(height: 10),

          /// 🔹 LIST
          sectionList.isEmpty
              ? const Center(child: Text("No Data"))
              : ListView.builder(
                  shrinkWrap: true, // 🔥 IMPORTANT
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sectionList.length,
                  itemBuilder: (context, index) {
                    return buildSectionCard(
                        sectionList[index], setState); // 👈 NORMAL setState
                  },
                ),

          const SizedBox(height: 10),

          /// 🔥 SAVE BUTTON
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: () {
          //       if (!areAllAnswersFilled()) {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           const SnackBar(content: Text("Please fill all answers")),
          //         );
          //         return;
          //       }

          //       printFinalData(); // 👈 NO POPUP CLOSE
          //     },
          //     child: const Text("Save"),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget buildSectionCard(SectionModel section, Function setStateDialog) {
    return Card(
      child: ExpansionTile(
        title: Column(
          children: [
            /// 🔥 SECTION DROPDOWN (YAHI HOGA)
            DropdownButtonFormField<int>(
              value: section.sectionID,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Select Section",
              ),
              items: sectionMasterList.map((s) {
                return DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name), // 👈 "Section QC"
                );
              }).toList(),
              onChanged: null,
            ),
          ],
        ),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.points.length,
            itemBuilder: (context, index) {
              return buildPointRow(section.points[index], setStateDialog);
            },
          )
        ],
      ),
    );
  }

  Widget buildPointRow(PointModel point, Function setStateDialog) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Point Name
          Text(
            point.pointName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),

          // const SizedBox(height: 6),

          const SizedBox(height: 6),

          /// 🔹 Work Date
          TextField(
            readOnly: true,
            controller: point.workDateController,
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: point.workDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setState(() {
                  point.workDate = picked;
                  point.workDateController.text =
                      dateFormat.format(picked); // 🔥 add this
                });
              }
            },
            decoration: const InputDecoration(
              hintText: "Work Date",
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const SizedBox(height: 6),

          /// 🔹 Answer (Radio)
          Row(
            children: [
              Expanded(child: buildRadio("Yes", 1, point, setStateDialog)),
              Expanded(child: buildRadio("No", 2, point, setStateDialog)),
              Expanded(child: buildRadio("NA", 3, point, setStateDialog)),
            ],
          ),

          const SizedBox(height: 6),

          /// 🔹 Remark
          TextField(
            controller: point.remarkController,
            decoration: const InputDecoration(
              hintText: "Remark",
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const Divider(),
        ],
      ),
    );
  }

  Widget buildRadio(
      String label, int value, PointModel point, Function setStateDialog) {
    return Row(
      children: [
        Radio<int>(
          value: value,
          groupValue: point.answerId,
          onChanged: (val) {
            setStateDialog(() {
              // 🔥 IMPORTANT
              point.answerId = val;
            });
          },
        ),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (showForm) {
          setState(() {
            showForm = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          title: const Text("Quality Checklist"),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (showForm) {
                setState(() {
                  showForm = false; // 👈 form close
                });
              } else {
                Navigator.pop(context); // 👈 dashboard
              }
            },
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end, // 👈 RIGHT SIDE
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    showForm = !showForm;
                  });
                },
                child: Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : projectList.isEmpty
                ? const Center(child: Text("No Projects Available"))
                : showForm
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: buildForm(), // 🔥 ONLY FORM
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            /// 🔷 Dropdown
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Project>(
                                  isExpanded: true,
                                  value: selectedProject,
                                  hint: const Text("Select Project"),
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

                                      await SharedPrefsHelper.saveProjectID(
                                          newProject.id);

                                      await fetchQualityChecklists(
                                          newProject.id);
                                    }
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// 🔹 LIST
                            Expanded(
                              child: checklists.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.inbox,
                                              size: 60,
                                              color: Colors.grey[400]),
                                          const SizedBox(height: 10),
                                          const Text("No Checklist Found"),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: checklists.length,
                                      itemBuilder: (context, index) {
                                        return buildChecklistCard(
                                            checklists[index]);
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget buildChecklistCard(item) {
    Color statusColor;
    switch (item.status) {
      case "In Progress":
        statusColor = Colors.orange;
        break;
      case "Completed":
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    final hasFromDate = item.fromDate != null;
    final hasToDate = item.toDate != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Top Row (Code + Status)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.checklistCode,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                /// 🟢 Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// 🔹 Title
            Row(
              children: [
                if (item.checklistFor != null && item.checklistFor!.isNotEmpty)
                  Expanded(
                    child: Text(
                      item.checklistFor!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (item.checklistFor != null &&
                    item.checklistFor!.isNotEmpty &&
                    item.frequency != null &&
                    item.frequency!.isNotEmpty)
                  const SizedBox(width: 10),
                if (item.frequency != null && item.frequency!.isNotEmpty)
                  Expanded(
                    child: Text(
                      item.frequency!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (hasFromDate)
                  Expanded(
                    child: Text(
                      dateFormat.format(item.fromDate!),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (hasFromDate && hasToDate) const SizedBox(width: 10),
                if (hasToDate)
                  Expanded(
                    child: Text(
                      dateFormat.format(item.toDate!),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            /// 🔹 Bottom Info Row
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.createdBy!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis, // 👈 long text handle
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
/////////////////////////////
