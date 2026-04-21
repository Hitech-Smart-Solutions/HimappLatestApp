import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:himappnew/awaitingapprovals/awaiting_approval_mris_page.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/model/material_requisition_slip_model.dart';
import 'package:himappnew/model/page_permission.dart';
import 'package:himappnew/model/project_model.dart';
import 'package:himappnew/service/material_requisition_slip_service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'dart:convert';

class MaterialRequisitionSlip extends StatefulWidget {
  final ProjectService _projectService;
  final int? slipId;
  final bool isApproval;
  final PagePermission pagePermission;

  const MaterialRequisitionSlip({
    super.key,
    required ProjectService projectService,
    this.slipId,
    this.isApproval = false,
    required this.pagePermission, // 🔥
  }) : _projectService = projectService;

  @override
  State<MaterialRequisitionSlip> createState() =>
      _MaterialRequisitionSlipState();
}

class UiItemDetail {
  int? id;
  int lineNumber;
  int itemId;
  String item;
  String unit;

  double qty; // ✅ actual qty (35.76)
  double requiredQty; // ✅ user input (2.8)
  double issueQty; // ✅ separate field

  double? availableQty;
  int? activityNo;
  String? equipmentName;
  String remarks;
  String placeOfIssue;

  ActivityModel? selectedActivity;
  EquipmentModel? selectedEquipment;

  UiItemDetail({
    this.id,
    this.lineNumber = 0,
    this.itemId = 0,
    this.item = '',
    this.unit = '',
    this.qty = 0,
    this.requiredQty = 0, // ✅ NEW
    this.issueQty = 0, // ✅ NEW
    this.availableQty,
    this.activityNo,
    this.equipmentName,
    this.remarks = '',
    this.placeOfIssue = '',
    this.selectedActivity,
    this.selectedEquipment,
  });

  UiItemDetail.clone(UiItemDetail other)
      : id = other.id,
        lineNumber = other.lineNumber,
        itemId = other.itemId,
        item = other.item,
        unit = other.unit,
        qty = other.qty,
        requiredQty = other.requiredQty, // ✅ NEW
        issueQty = other.issueQty, // ✅ NEW
        availableQty = other.availableQty,
        activityNo = other.activityNo,
        equipmentName = other.equipmentName,
        remarks = other.remarks,
        placeOfIssue = other.placeOfIssue,
        selectedActivity = other.selectedActivity,
        selectedEquipment = other.selectedEquipment;
}

class _MaterialRequisitionSlipState extends State<MaterialRequisitionSlip> {
  final MaterialRequisitionSlipService _materialRequisitionSlipService =
      MaterialRequisitionSlipService();

  Project? selectedProject;
  List<Project> projectList = [];
  List<MaterialIssue> materialIssueList = [];
  bool listLoading = false;
  bool showForm = false;
  // Controllers
  final TextEditingController slipNoCtrl = TextEditingController();
  final TextEditingController slipDateCtrl = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController availableController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(text: '0');

  List<SectionModel> sectionList = [];
  int? selectedSectionId;

  List<FloorModel> floorData = [];
  int? selectedFloorId;

  EmployeeModel? selectedEmployee;
  int employeePageNumber = 1;
  final int employeePageSize = 1000;
  bool employeeLoading = false;
  bool employeeHasMore = true;

  void resetEmployeeSearch(String search) {
    employeeSearchText = search;
    employeePageNumber = 1;
    employeeHasMore = true;
  }

  void resetContractorSearch(String search) {
    contractorSearchText = search;
    contractorPageNumber = 1;
    contractorHasMore = true;
  }

  Future<void> addItem(UiItemDetail tempItem, {int? index}) async {
    final result = await openItemSheet(tempItem, index: index);
    if (result != null) {
      setState(() {
        if (index != null) {
          // edit existing
          itemDetails[index] = result;
        } else {
          // add new
          itemDetails.add(result);
        }
      });
    }
  }

  /// Deletes an item from itemDetails with a confirmation dialog
  Future<void> deleteItem(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        itemDetails.removeAt(index);
      });
    }
  }

  int _currentProjectFetchId = 0;
  void onProjectChanged(Project? project) async {
    if (project == null) return;

    setState(() {
      selectedProject = project;
      selectedSectionId = null;
      selectedFloorId = null;
      sectionList.clear();
      floorData.clear();
      materialIssueList.clear();
      listLoading = true;
    });

    // Increment fetch ID
    final fetchId = ++_currentProjectFetchId;

    // Load dependent data
    await loadSections(project.id);
    await loadFloors(project.id);

    // 🔹 Fetch list safely
    final list = await _materialRequisitionSlipService
        .fetchMaterialIssueRequestByProjectID(
      projectId: project.id,
    );

    // Only set list if this fetch is latest
    if (fetchId == _currentProjectFetchId) {
      setState(() {
        // materialIssueList = list; 🔴 DON'T overwrite directly
        for (var m in list) {
          if (!materialIssueList.any((e) => e.id == m.id)) {
            materialIssueList.add(m);
          }
        }
        listLoading = false;
      });
    }
  }

  String formatQty(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString(); // 10.0 -> 10
    } else {
      return value.toStringAsFixed(2); // 10.20, 65.31
    }
  }

  String employeeSearchText = '';

  ContractorModel? selectedContractor;
  int contractorPageNumber = 1;
  final int contractorPageSize = 1000;
  bool contractorLoading = false;
  bool contractorHasMore = true;
  String contractorSearchText = '';

  List<EquipmentModel> equipmentList = [];
  int equipmentPageNumber = 1;
  final int equipmentPageSize = 1000;
  bool equipmentLoading = false;
  bool equipmentHasMore = true;
  String equipmentSearchText = '';
  EquipmentModel? selectedEquipment;

  List<ActivityModel> activityList = [];
  int activityPageNumber = 1;
  final int activityPageSize = 20;
  bool activityLoading = false;
  bool activityHasMore = true;
  String activitySearchText = '';
  ActivityModel? selectedActivity;
  int? activityID;

  // final ProjectService _projectService = ProjectService();
  bool isLoading = false;
  // List<ItemDetail> itemDetails = [];
  List<UiItemDetail> itemDetails = [];

  List<ItemModel> itemList = [];
  int itemPageNumber = 1;
  int itemPageSize = 50;
  bool itemLoading = false;
  bool itemHasMore = true;
  String itemSearchText = '';

  DateTime? selectedSlipDateUtc;

  /// Formats only date (dd/mm/yyyy)
  String formatDateSafe(dynamic date) {
    if (date == null) return "-";

    DateTime d;

    if (date is String) {
      if (date.isEmpty) return "-";
      d = DateTime.parse(date);
    } else if (date is DateTime) {
      d = date;
    } else {
      return "-";
    }

    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  /// Formats date + time (dd/mm/yyyy hh:mm)
  String formatDateTimeSafe(dynamic date) {
    if (date == null) return "-";

    DateTime d;

    if (date is String) {
      if (date.isEmpty) return "-";
      d = DateTime.parse(date);
    } else if (date is DateTime) {
      d = date;
    } else {
      return "-";
    }

    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year} "
        "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }

  String? itemError;
  String? qtyError;
  String? placeError;
  String? activityError;
  bool isItemSubmitted = true;
  ItemModel? selectedItem;
  final programId = AppPages.materialIssueSlipProgramId;

  bool validateItem(UiItemDetail item) {
    if (selectedItem == null) return false;
    if (item.qty <= 0) return false;
    if (item.placeOfIssue == null || item.placeOfIssue!.isEmpty) return false;
    if (selectedActivity == null) return false;
    return true;
  }

  bool isApproval = false; // IsApproval
  bool isEditable = true; // isEditable
  // bool isLoading = false;
  int editingId = 0; // 0 = new, >0 = edit
  bool isEditMode = false; // UI control

  String? status;
  String? syncStatus;

  // bool get isApprovalMode => widget.isApproval == true;
  bool isApprovalMode = false; // ✅ make it variable
  String approvalStatus = "";
  bool get showSubmitButton => showForm && !isApproval && isEditable;
  bool get showApprovalButtons => showForm && isApproval;
  bool get canEdit =>
      approvalStatus == "Draft" || approvalStatus == "Disapproved";

  int backPressCount = 0; // 🔹 State variable
  bool isDataLoaded = false;
  @override
  void initState() {
    super.initState();
    isApprovalMode = widget.isApproval == true;

    if (widget.slipId != null) {
      // 🔹 EDIT MODE (FROM DASHBOARD / CARD CLICK)
      isEditMode = true;
      showForm = false; // 👈 IMPORTANT (start with list/state first)
      isDataLoaded = false;

      _loadEditFlow(widget.slipId!);
    } else {
      // 🔹 CREATE / DASHBOARD LIST MODE
      isEditMode = false;
      showForm = false;
      isDataLoaded = true;

      selectedSlipDateUtc = DateTime.now().toUtc();
      slipDateCtrl.text = formatDateSafe(selectedSlipDateUtc);

      fetchProjects();
    }
  }

  Future<void> _loadEditFlow(int slipId) async {
    if (!mounted || !isEditMode) return; // 🔥 IMPORTANT
    setState(() => isLoading = true);
    try {
      /// 🔹 API CALL
      final data = await _materialRequisitionSlipService.getMaterialIssueById(
        slipId,
        programId,
      );

      print("🔥 API Response for Slip ID $slipId: $data");

      if (data == null) {
        setState(() => isLoading = false);
        return;
      }

      editingId = slipId;
      final int slipProjectId = data['projectID'];
      await fetchProjects(editProjectId: slipProjectId);

      // ✅ Save projectID in SharedPrefs
      if (selectedProject != null) {
        await SharedPrefsHelper.saveProjectID(selectedProject!.id);
        // print("PROJECT SAVED IN PREFS => ${selectedProject!.id}");
      }

      int statusID = data['statusID'] ?? 0;
      int createdBy = data['createdBy'] ?? 0;
      int awaitingApprovalForId = data['isAwaitingApprovalForId'] ?? 0;
      int currentUserId = await SharedPrefsHelper.getUserId() ?? 0;
      final bool hasAccess = projectList.any((p) => p.id == slipProjectId);

      /// Approver ko allow karo
      if (!hasAccess && currentUserId != awaitingApprovalForId) {
        showSnack("This MRIS belongs to a project not assigned to you");
        setState(() => isLoading = false);
        return;
      }

      /// 🔹 SELECT PROJECT
      selectedProject = projectList.firstWhere(
        (p) => p.id == slipProjectId,
        orElse: () => projectList.first,
      );
      materialIssueList.clear();
      await fetchMaterialIssueRequestByProjectID(selectedProject!.id);

      /// 🔹 LOAD SECTION / FLOOR
      // await loadSections(slipProjectId);
      // await loadFloors(slipProjectId);

      /// 🔥 EXACT ANGULAR LOGIC
      setState(() {
        // showForm = true; // show form
        if (statusID == 2 &&
            createdBy == awaitingApprovalForId &&
            currentUserId == createdBy) {
          isApproval = false;
          isEditable = true;
        } else if (currentUserId == awaitingApprovalForId && statusID == 2) {
          isApproval = true;
          isEditable = false;
        } else if (statusID == 3) {
          isApproval = false;
          isEditable = false;
        } else {
          isApproval = false;
          isEditable = false;
        }
      });
      await _patchSlipData(data);
      // int awaitingApprovalForBeforeUpdate = awaitingApprovalForId;
    } catch (e) {
      print("❌ Error in loadEditFlow: $e");
      showSnack("Error loading MRIS");
    } finally {
      setState(() {
        isDataLoaded = true;
        showForm = true;
      });
    }
  }

  Future<ItemModel?> resolveItemById({
    required int itemId,
    required int projectId,
  }) async {
    final list = await _materialRequisitionSlipService.getReleasedProducts(
      search: itemId.toString(), // 🔥 KEY POINT
      pageNumber: 1,
      pageSize: 1000,
      projectID: projectId,
    );

    try {
      return list.firstWhere((e) => e.id == itemId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _patchSlipData(Map<String, dynamic> data) async {
    try {
      itemDetails.clear();
      slipNoCtrl.text = data['slipNumber'] ?? '';
      slipDateCtrl.text = formatDateSafe(DateTime.parse(data['slipDate']));

      final sections = await _materialRequisitionSlipService
          .getSectionsByProjectID(data['projectID']);
      final floors = await _materialRequisitionSlipService
          .getFloorByProjectID(data['projectID']);

      setState(() {
        sectionList = sections;
        floorData = floors;
        selectedSectionId = data['sectionID'];
        selectedFloorId = data['floorID'];
      });

      final employees = await loadEmployees("");
      if (data['employeeID'] != null) {
        selectedEmployee = employees.firstWhere(
          (e) => e.id == data['employeeID'],
          orElse: () => EmployeeModel(
            id: data['employeeID'],
            displayName: data['employeeName'] ?? "",
          ),
        );
      }

      final contractors = await loadContractors("");
      if (data['contractorID'] != null) {
        selectedContractor = contractors.firstWhere(
          (c) => c.id == data['contractorID'],
          orElse: () => ContractorModel(
            id: data['contractorID'],
            displayName: "",
          ),
        );
      }

      final allActivities = await _materialRequisitionSlipService.getActivities(
        search: '',
        projectID: data['projectID'],
      );

      for (final d in data['details']) {
        if (!itemDetails.any((e) => e.id == d['id'])) {
          final itemId = (d['itemID'] as num).toInt();
          final itemModel = await resolveItemById(
            itemId: itemId,
            projectId: data['projectID'],
          );

          final activityNo =
              d['activityID'] != null ? (d['activityID'] as num).toInt() : null;

          ActivityModel? selectedActivity;
          if (activityNo != null) {
            try {
              selectedActivity =
                  allActivities.firstWhere((a) => a.id == activityNo);
            } catch (e) {
              selectedActivity = ActivityModel(
                id: activityNo,
                activityName: "Activity #$activityNo",
              );
            }
          }

          /// 🔥🔥🔥 EQUIPMENT FIX (YAHI DALNA HAI)
          final equipmentIdStr = d['equipmentId_ISPL']?.toString();

          EquipmentModel? selectedEquipment;

          if (equipmentIdStr != null && equipmentIdStr.isNotEmpty) {
            final equipmentList =
                await _materialRequisitionSlipService.getEquipment(
              search: '',
              pageNumber: 1,
              pageSize: 50,
            );

            try {
              selectedEquipment = equipmentList.firstWhere(
                (e) => e.id.toString() == equipmentIdStr,
              );
            } catch (e) {
              selectedEquipment = EquipmentModel(
                id: int.tryParse(equipmentIdStr) ?? 0,
                displayName: "Equipment #$equipmentIdStr",
              );
            }
          }

          itemDetails.add(
            UiItemDetail(
              id: d['id'],
              lineNumber: d['lineNumber'] ?? 0,
              itemId: itemId,
              item: itemModel?.displayText ?? 'Item #$itemId',
              unit: itemModel?.unit ?? d['unit'] ?? '',
              qty: (d['qty'] as num?)?.toDouble() ?? 0,
              placeOfIssue: d['placeOfIssue'] ?? '',
              remarks: d['remarks'] ?? '',
              requiredQty: (d['requiredQty'] as num?)?.toDouble() ?? 0,
              issueQty: (d['issueQty'] as num?)?.toDouble() ?? 0,
              availableQty: (d['qty'] as num?)?.toDouble(),
              activityNo: activityNo,
              selectedEquipment: selectedEquipment,
              equipmentName: selectedEquipment?.displayName ?? '',
              selectedActivity: selectedActivity,
            ),
          );
        } else {
          print("⚠️ Skipping duplicate item with id: ${d['id']}");
        }

        print("👉 API Equipment ID: ${d['equipmentId_ISPL']}");
        print("👉 Mapped Equipment: ${selectedEquipment?.displayName}");
      }
      setState(() {
        showForm = true;
      });
    } catch (e, s) {
      print("❌ PATCH ERROR: $e");
      print(s);
    }
  }

  // Date Picker (UTC)
  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();

    // 👇 Last month ki same date (approx)
    // final DateTime lastMonthDate = DateTime(now.year, now.month - 1, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedSlipDateUtc?.toLocal() ?? now,
      firstDate: DateTime(2000), // 👈 yaha change
      lastDate: now, // 👈 future block
    );

    if (picked != null) {
      setState(() {
        selectedSlipDateUtc = DateTime.utc(
          picked.year,
          picked.month,
          picked.day,
        );

        slipDateCtrl.text = formatDateSafe(picked);
      });

      print("📅 Picked Date (Local): $picked");
      print("📅 Stored Date (UTC): $selectedSlipDateUtc");
    }
  }

  Future<void> fetchProjects({int? editProjectId}) async {
    try {
      int? userId = await SharedPrefsHelper.getUserId();
      int? companyId = await SharedPrefsHelper.getCompanyId();
      if (userId == null || companyId == null) return;

      List<Project> projects =
          await widget._projectService.fetchProject(userId, companyId);

      Project? matchedProject;

      if (editProjectId != null) {
        try {
          matchedProject = projects.firstWhere((p) => p.id == editProjectId);
        } catch (_) {
          print("❌ EDIT PROJECT NOT FOUND IN LIST");
        }
      }

      setState(() {
        projectList = projects;
        selectedProject =
            matchedProject ?? (projects.isNotEmpty ? projects[0] : null);
      });

      if (selectedProject != null) {
        await SharedPrefsHelper.saveProjectID(selectedProject!.id);

        // 🔥 AUTO LOAD DATA
        await loadSections(selectedProject!.id);
        await loadFloors(selectedProject!.id);
        // 🔥 ONLY FOR CREATE MODE
        if (!isEditMode) {
          await fetchMaterialIssueRequestByProjectID(selectedProject!.id);
        }
      }
    } catch (e) {
      print("Error fetching projects: $e");
    }
  }

  Future<void> fetchMaterialIssueRequestByProjectID(int projectId) async {
    setState(() => isLoading = true);
    try {
      materialIssueList.clear(); // clear old list first
      print(
          "🔥 MaterialIssueList BEFORE adding fetched: ${materialIssueList.length}");

      final fetched = await _materialRequisitionSlipService
          .fetchMaterialIssueRequestByProjectID(
        projectId: projectId,
        sortColumn: 'ID Desc',
        pageIndex: 0,
        pageSize: 50,
        isActive: true,
      );

      print("🔥 Fetched list length: ${fetched.length}");

      // 🔹 Add/update slips to prevent duplicates
      for (var slip in fetched) {
        int idx = materialIssueList.indexWhere((e) => e.id == slip.id);
        if (idx == -1) {
          materialIssueList.add(slip);
        } else {
          materialIssueList[idx] = slip;
        }
      }

      // 🔹 Print full data log
      // print("🔥 MaterialIssueList AFTER adding fetched:");
      // for (var slip in materialIssueList) {
      //   print("📌 Slip ID: ${slip.id}");
      //   print("   Slip Number: ${slip.slipNumber}");
      //   print("   Slip Date: ${slip.slipDate}");
      //   print("   Floor: ${slip.floorName}");
      //   print("   Section: ${slip.sectionName}");
      //   print("   Employee: ${slip.employeeName}");
      //   print("   Contractor: ${slip.contractorName}");
      //   print("   Sync Status: ${slip.syncStatus}");
      //   print("   Active: ${slip.isActive}");
      //   print("   Approval Status: ${slip.approvalStatus}");
      //   print("   Awaiting Approval For: ${slip.AwaitingApprovalFor}");
      //   print("   ----------------------------------------");
      // }

      setState(() => listLoading = false);
    } catch (e) {
      print("❌ Fetch error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadSections(int projectId) async {
    sectionList =
        await _materialRequisitionSlipService.getSectionsByProjectID(projectId);
    setState(() {});
  }

  Future<void> loadFloors(int projectId) async {
    floorData =
        await _materialRequisitionSlipService.getFloorByProjectID(projectId);
    setState(() {});
  }

  String lastEmployeeFilter = '';
  List<EmployeeModel> employeeCache = [];
  Future<List<EmployeeModel>> loadEmployees(String filter) async {
    /// RESET when search changes
    if (filter != lastEmployeeFilter) {
      employeePageNumber = 1;
      employeeHasMore = true;
      employeeCache.clear(); // 🔥 IMPORTANT
      lastEmployeeFilter = filter;
    }

    if (employeeLoading) {
      return employeeCache; // 🔥 RETURN OLD DATA
    }

    employeeLoading = true;

    final result = await _materialRequisitionSlipService.getEmployees(
      search: filter,
      pageNumber: employeePageNumber,
      pageSize: employeePageSize,
    );

    if (result.isNotEmpty) {
      employeePageNumber++;
      employeeCache.addAll(result); // 🔥 STORE DATA
    } else {
      employeeHasMore = false;
    }

    employeeLoading = false;

    return employeeCache;
  }

  List<ContractorModel> contractorCache = [];
  String lastContractorFilter = '';
  Future<List<ContractorModel>> loadContractors(String filter) async {
    print("🔍 FILTER => '$filter'");

    /// ✅ RESET when search changes
    if (filter != lastContractorFilter) {
      contractorPageNumber = 1;
      contractorHasMore = true;
      contractorCache.clear(); // 🔥 IMPORTANT
      lastContractorFilter = filter;
    }

    if (contractorLoading) {
      return contractorCache; // 🔥 DON'T RETURN EMPTY
    }

    contractorLoading = true;

    final result = await _materialRequisitionSlipService.getVendors(
      search: filter,
      pageNumber: contractorPageNumber,
      pageSize: contractorPageSize,
    );

    if (result.isNotEmpty) {
      contractorPageNumber++;
      contractorCache.addAll(result); // 🔥 STORE DATA
    } else {
      contractorHasMore = false;
    }

    contractorLoading = false;

    return contractorCache;
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> onSlipClick(BuildContext context, int id) async {
    final data = await _materialRequisitionSlipService.getMaterialIssueById(
        id, programId);

    if (data == null) return;

    await SharedPrefsHelper.saveProjectID(data['projectID']);

    /// 🔹 Navigate to Slip Page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialRequisitionSlip(
          projectService: ProjectService(),
          slipId: id,
          isApproval: true,
          pagePermission: widget.pagePermission,
        ),
      ),
    );
    if (result == true) {
      // _loadAwaitingMRISData(); // list refresh

      /// 🔥 Optional: agar chaho to auto back
      // Navigator.pop(context, true); // dashboard ko signal
    }
  }

  Future<void> saveMRIS() async {
    print("🔥 saveMRIS START");
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final int? projectIdBeforeReset =
          selectedProject?.id; // ✅ preserve current project

      final int? userId = await SharedPrefsHelper.getUserId();

      if (selectedSectionId == null || selectedSectionId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Section is required"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (selectedFloorId == null || selectedFloorId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Floor is required"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (itemDetails.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please add at least one item"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (selectedEmployee == null && selectedContractor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select either Employee or Contractor."),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (selectedEmployee != null && selectedContractor != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "You can not select both Employee and Contractor. Please select either one.",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final request = MaterialIssueRequest(
        id: editingId,
        dataAreaId: "hppl",
        slipNumber: slipNoCtrl.text,
        site: "SITE",
        sectionID: selectedSectionId ?? 0,
        floorID: selectedFloorId ?? 0,

        // 🔥 IMPORTANT
        status: "Posted",
        isplMaterialIssueType: 1,
        slipDate: selectedSlipDateUtc ?? DateTime.now().toUtc(),
        projectID: projectIdBeforeReset ?? 0,
        contractorID: selectedContractor?.id,
        employeeID: selectedEmployee?.id,
        isActive: true,
        programId: programId,
        lastModifiedBy: userId,
        createdBy: userId,
        // awaitingApprovalFor:
        //     awaitingApprovalForBeforeUpdate, // 🔹 YE FIELD ADD KARO
        details: itemDetails.asMap().entries.map((entry) {
          int index = entry.key;
          var ui = entry.value;
          return ItemDetail(
            id: ui.id,
            lineNumber: index + 1, // 🔥 FIX (UNIQUE)
            itemID: ui.itemId,
            equipmentIdISPL: ui.selectedEquipment?.id?.toString() ?? '',
            placeOfIssue: ui.placeOfIssue,
            unit: ui.unit,
            activityID: ui.selectedActivity?.id ?? 0,
            projectID: projectIdBeforeReset ?? 0,
            remarks: ui.remarks,
            requiredQty: ui.requiredQty,
            issueQty: ui.issueQty,
            qty: ui.availableQty ?? 0,
            journalNum: '',
          );
        }).toList(),
      );

      bool success;
      // 🟢 SAVE / 🔵 UPDATE
      if (editingId == 0) {
        // return; // 🔹 TEMPORARY DISABLE CREATE
        success =
            await _materialRequisitionSlipService.submitMaterialIssue(request);
      } else {
        final jsonString =
            const JsonEncoder.withIndent('  ').convert(request.toJson());
        print("📌 Full MRIS Payload:\n$jsonString");
        // return; // 🔹 TEMPORARY DISABLE UPDATE
        success =
            await _materialRequisitionSlipService.updateMaterialIssue(request);
      }

      if (success) {
        showSnack(editingId == 0
            ? "MRIS Saved Successfully"
            : "MRIS Updated Successfully");

        setState(() {
          resetForm(); // 🔥 form reset
          isEditable = true; // ✅ IMPORTANT
          isApprovalMode = false;

          showForm = false;
          isEditMode = false;
          approvalStatus = "";
        });

        // fetch list
        await fetchMaterialIssueRequestByProjectID(selectedProject!.id);
      }
    } catch (e) {
      String message = "Something went wrong";

      if (e is Map) {
        // 🔥 ONLY TAKE "error" FIELD
        if (e['error'] != null && e['error'].toString().isNotEmpty) {
          message = e['error'];
        }
      }

      showSnack(message);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void resetForm() {
    // TextControllers
    slipNoCtrl.clear();
    // slipDateCtrl.clear();

    // Dropdown selections
    selectedSectionId = null;
    selectedFloorId = null;
    selectedEmployee = null;
    selectedContractor = null;
    selectedActivity = null;
    selectedEquipment = null;

    // Date
    selectedSlipDateUtc = null;

    // Item details
    itemDetails.clear();

    // Reset item dialog controllers
    resetItemFields();

    // Form flags
    // showForm = false;
  }

  void resetItemFields() {
    // Clear controllers
    unitController.clear();
    availableController.clear();
    qtyController.clear();

    // Reset temporary item object
    selectedItem = null;
    selectedActivity = null;
    selectedEquipment = null;

    // Reset validation errors
    itemError = null;
    qtyError = null;
    placeError = null;
    activityError = null;
  }

  void openApprovalPopup(BuildContext context, bool isApprove) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isApprove ? "Approve MRIS" : "Disapprove MRIS"),
        content: const Text("Are you sure you want to continue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (isApprove) {
                await approveMRIS();
              } else {
                await disapproveMRIS();
              }
            },
            child: const Text("Yes"),
          )
        ],
      ),
    );
  }

  Future<String?> showRemarkDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required Color actionColor,
    required String actionText,
  }) async {
    final TextEditingController remarkController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: remarkController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
              ),
              onPressed: () {
                if (remarkController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Remark is required"),
                    ),
                  );
                  return;
                }
                Navigator.pop(
                  context,
                  remarkController.text.trim(),
                );
              },
              child: Text(actionText),
            ),
          ],
        );
      },
    );
  }

  Future<void> approveMRIS() async {
    final int? userId = await SharedPrefsHelper.getUserId();
    final int? issueId = widget.slipId;

    if (userId == null || issueId == null) {
      showSnack("Invalid user or issue");
      return;
    }

    final remark = await showRemarkDialog(
      context,
      title: "Approve MRIS",
      hint: "Enter approval remark",
      actionColor: Colors.green,
      actionText: "Approve",
    );

    if (remark == null) return;

    final payload = {
      "IssueId": issueId,
      "ApprovalStatusCode": 3,
      "Remarks": remark,
      "ProgramId": AppPages.materialIssueSlipProgramId,
      "ActionedBy": userId,
    };

    print("Approval Payload => $payload");

    final success = await _materialRequisitionSlipService.approveMRIS(payload);

    if (success) {
      showSnack("Approved Successfully");

      /// 🔥 Approval ke baad Awaiting Approval list pe wapas
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => const AwaitingApprovalMrisPage(),
      //   ),
      //   (route) => false, // 🔥 purana stack clear
      // );
      Navigator.pop(context, true); // 🔥 bas itna
    }
  }

  Future<void> disapproveMRIS() async {
    final int? userId = await SharedPrefsHelper.getUserId();
    final int? issueId = widget.slipId; // ✅ FIX

    if (userId == null || issueId == null) {
      showSnack("Invalid user or issue");
      return;
    }

    final remark = await showRemarkDialog(
      context,
      title: "Disapprove MRIS",
      hint: "Enter rejection reason",
      actionColor: Colors.red,
      actionText: "Disapprove",
    );

    if (remark == null) return;

    final payload = {
      "OldId": issueId, // 🔥 backend key yahi expect kar raha
      "DisapprovalRemarks": remark,
      "ActionedBy": userId,
    };

    print("Disapprove Payload => $payload");

    final success =
        await _materialRequisitionSlipService.disapproveMRIS(payload);

    if (success) {
      showSnack("Disapproved Successfully");

      /// 🔥 Same clean navigation as Approve
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => const AwaitingApprovalMrisPage(),
      //   ),
      //   (route) => false,
      // );
      Navigator.pop(context, true); // 🔥 bas itna
    }
  }

  Future<UiItemDetail?> openItemSheet(UiItemDetail tempItem,
      {int? index}) async {
    print("🔥 DIALOG BUILD STARTED");
    final item = tempItem;

    /// Controllers
    final qtyController = TextEditingController(
      text: item.requiredQty > 0 ? item.requiredQty.toString() : '',
    );
    final unitController = TextEditingController(text: item.unit);
    final availableController =
        TextEditingController(text: item.availableQty?.toString() ?? '');

    /// Selected Dropdown Values
    ItemModel? selectedItem = item.itemId != 0
        ? ItemModel(id: item.itemId, displayText: item.item, unit: item.unit)
        : null;

    ActivityModel? selectedActivity = item.selectedActivity;

    EquipmentModel? selectedEquipment = item.selectedEquipment;

    final placeController =
        TextEditingController(text: item.placeOfIssue ?? '');

    /// ✅ FIX 1 : Prefill available qty when editing
    if (selectedItem != null) {
      final projectId = selectedProject?.id;

      if (projectId != null) {
        final qty = await _materialRequisitionSlipService
            .getAvailableQuantityByProject(projectId, selectedItem.id);

        availableController.text = formatQty(qty);
      }
    }

    final remarksController = TextEditingController(
      text: item.remarks,
    );

    return showDialog<UiItemDetail?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: MediaQuery.of(context).size.width,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// TITLE
                      Text(
                        index == null ? "Add Item" : "Item ${index + 1}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// SCROLLABLE CONTENT
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// ITEM DROPDOWN
                              DropdownSearch<ItemModel>(
                                selectedItem: selectedItem,
                                dropdownBuilder: (context, selectedItem) {
                                  if (selectedItem == null) {
                                    return const Text("Select Item");
                                  }
                                  return Text(
                                    selectedItem.displayText,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                                popupProps: PopupProps.dialog(
                                  showSearchBox: true,
                                  loadingBuilder: (context, search) =>
                                      const Center(
                                          child: CircularProgressIndicator()),
                                  itemBuilder: (context, item, isSelected) {
                                    return ListTile(
                                      title: Text(
                                        item.displayText,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                                asyncItems: (String filter) async {
                                  return _materialRequisitionSlipService
                                      .getReleasedProducts(
                                    search: filter,
                                    pageNumber: 1,
                                    pageSize: 20,
                                    projectID: selectedProject?.id ?? 0,
                                  );
                                },
                                itemAsString: (ItemModel item) =>
                                    item.displayText,
                                onChanged: (ItemModel? itemModel) async {
                                  if (itemModel == null) return;

                                  setDialogState(() {
                                    selectedItem = itemModel;
                                    item.itemId = itemModel.id;
                                    item.item = itemModel.displayText;
                                    item.unit = itemModel.unit ?? '';
                                    unitController.text = item.unit;
                                  });

                                  final projectId = selectedProject?.id;
                                  if (projectId == null) return;

                                  final qty =
                                      await _materialRequisitionSlipService
                                          .getAvailableQuantityByProject(
                                              projectId, itemModel.id);

                                  setDialogState(() {
                                    availableController.text = formatQty(qty);
                                    item.availableQty = qty;
                                  });
                                },
                              ),

                              const SizedBox(height: 10),

                              /// UNIT / AVAILABLE / QTY
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: unitController,
                                      enabled: false,
                                      decoration: const InputDecoration(
                                        labelText: "Unit",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: availableController,
                                      enabled: false,
                                      decoration: const InputDecoration(
                                        labelText: "Available",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: qtyController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: "Required Qty",
                                        border: const OutlineInputBorder(),
                                        errorText:
                                            isItemSubmitted ? qtyError : null,
                                      ),
                                      onChanged: (v) {
                                        setDialogState(() {
                                          item.requiredQty =
                                              double.tryParse(v) ?? 0;
                                          qtyError = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              /// PLACE OF ISSUE
                              TextField(
                                controller: placeController,
                                decoration: InputDecoration(
                                  labelText: "Place Of Issue",
                                  border: const OutlineInputBorder(),
                                  errorText:
                                      isItemSubmitted ? placeError : null,
                                ),
                                onChanged: (v) {
                                  setDialogState(() {
                                    item.placeOfIssue = v;
                                    placeError = null;
                                  });
                                },
                              ),

                              const SizedBox(height: 10),

                              /// ACTIVITY
                              DropdownSearch<ActivityModel>(
                                selectedItem: selectedActivity,
                                compareFn: (a, b) => a.id == b.id,
                                asyncItems: (String filter) async {
                                  if (selectedProject == null) return [];
                                  return _materialRequisitionSlipService
                                      .getActivities(
                                    search: filter.trim(),
                                    projectID: selectedProject!.id,
                                  );
                                },
                                itemAsString: (a) => a.activityName,

                                // 👇 ADD THIS
                                dropdownDecoratorProps:
                                    const DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: "Activity No",
                                    border: OutlineInputBorder(),
                                  ),
                                ),

                                popupProps: const PopupProps.dialog(
                                  showSearchBox: true,
                                ),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedActivity = value;

                                    item.activityNo = value?.id;
                                    item.selectedActivity = value; // ✅ ADD THIS

                                    activityError = null;
                                  });
                                },
                              ),

                              const SizedBox(height: 10),

                              /// EQUIPMENT
                              DropdownSearch<EquipmentModel>(
                                selectedItem: selectedEquipment,
                                asyncItems: (String filter) async {
                                  return _materialRequisitionSlipService
                                      .getEquipment(
                                    search: filter,
                                    pageNumber: 1,
                                    pageSize: 20,
                                  );
                                },
                                itemAsString: (e) => e.displayName,

                                // 👇 ADD THIS
                                dropdownDecoratorProps:
                                    const DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: "Equipment",
                                    border: OutlineInputBorder(),
                                  ),
                                ),

                                popupProps: const PopupProps.dialog(
                                  showSearchBox: true,
                                ),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedEquipment = value;
                                    item.equipmentName =
                                        value?.displayName ?? "";
                                    item.selectedEquipment = value;
                                  });
                                },
                              ),

                              const SizedBox(height: 10),

                              /// REMARKS
                              TextField(
                                controller: remarksController, // ✅ ADD THIS
                                decoration: const InputDecoration(
                                  labelText: "Remarks",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => item.remarks = v,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setDialogState(() {
                                isItemSubmitted = true;

                                itemError = selectedItem == null
                                    ? "Item required"
                                    : null;

                                final value = qtyController.text.trim();
                                final qty = double.tryParse(value);

                                qtyError =
                                    (value.isEmpty || qty == null || qty <= 0)
                                        ? "Qty must be greater than 0"
                                        : null;

                                placeError = (item.placeOfIssue ?? "").isEmpty
                                    ? "Place required"
                                    : null;
                              });

                              if (itemError == null &&
                                  qtyError == null &&
                                  placeError == null) {
                                Navigator.pop(context, item);
                              }
                            },
                            child: const Text("Done"),
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
      },
    );
  }

  Widget _infoText(String label, String value, {bool fullWidth = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey, // subtle grey for label
            ),
          ),
          const SizedBox(height: 2),
          // Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500, // slightly bolder
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoColRow(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Future<void> _openActionPopup(int id) async {
    try {
      final data = await _materialRequisitionSlipService.getMrisApprovalHistory(
        id: id,
        programId: AppPages.materialIssueSlipProgramId,
      );

      if (!mounted) return;

      // 🔥 API ke baad dialog open
      _showHistoryPopup(data);
    } catch (e) {
      debugPrint("❌ History error: $e");
      showSnack("Failed to load history");
    }
  }

  void _showHistoryPopup(List<dynamic> historyData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final header = historyData.isNotEmpty ? historyData[0] : null;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🔹 TITLE
                const Text(
                  "MRIS Approval History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔹 HEADER CARD (ONE LINE LOOK)
                if (header != null)
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade50,
                            Colors.blue.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 ROW 1 – Slip No (Full Width)
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  header['transactionCode'] ?? "-",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // 🔹 ROW 2 – Date (Left) & Created By (Right)
                          Row(
                            children: [
                              // Date
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatDateTimeSafe(
                                        header['transactionDate']),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),

                              const Spacer(), // 🔥 pushes next item to right

                              // Created By
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    header['createdBy'] ?? "-",
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )),

                const SizedBox(height: 14),

                /// 🔹 HISTORY LIST
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: historyData.length,
                    itemBuilder: (_, index) {
                      final item = historyData[index];

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(
                                context,
                                "Actioned By",
                                item['actionedBy'],
                              ),
                              _infoRow(
                                context,
                                "Received On",
                                formatDateTimeSafe(item['receivedOn']),
                              ),
                              _infoRow(
                                context,
                                "Actioned On",
                                formatDateTimeSafe(item['actionedOn']),
                              ),
                              _infoRow(
                                context,
                                "Action",
                                item['action'],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Remarks",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['remarks'] ?? "—",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Reference: ${item['isReference'] ?? 'No'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                /// 🔹 OK BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(BuildContext context, String label, String? value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90, // label column fixed
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : "-",
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isApprovalMode) {
          return true; // Navigator.pop()
        }
        // FORM → LIST
        if (showForm) {
          setState(() {
            showForm = false;
          });
          return false;
        }
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Material Issue Slip"),
        ),
        floatingActionButton: (selectedProject != null &&
                !showForm &&
                widget.pagePermission.canAdd)
            ? FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    resetForm();
                    isEditable = true;
                    isEditMode = false;
                    isApprovalMode = false;

                    showForm = true;
                  });
                },
              )
            : null,
        body: isDataLoaded
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 🔹 PROJECT DROPDOWN
                    if (!showForm) ...[
                      DropdownButtonFormField<Project>(
                        value: selectedProject,
                        hint: const Text("Select Project"),
                        items: projectList.map((p) {
                          return DropdownMenuItem<Project>(
                            value: p,
                            child: Text(p.name),
                          );
                        }).toList(),
                        onChanged: onProjectChanged,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // 🔹 PROJECT KE NICHE → MRIS LIST
                    if (selectedProject != null && !showForm) ...[
                      if (listLoading) const CircularProgressIndicator(),
                      if (!listLoading && materialIssueList.isEmpty)
                        const Text(
                          "No MRIS found for this project",
                          style: TextStyle(color: Colors.grey),
                        ),
                      if (!listLoading && materialIssueList.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: materialIssueList.length,
                          itemBuilder: (context, index) {
                            final item = materialIssueList[index];
                            // print("FULL ITEM DATA 👉 $item");
                            return GestureDetector(
                              onTap: item.approvalStatus == "Awaiting Approval"
                                  ? () {
                                      // print(
                                      //     "🟢 Disapproved Card Clicked ID 👉 ${item.id}");
                                      onSlipClick(context, item.id);
                                    }
                                  : null,
                              child: Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      /// 🔹 Top Row
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// 🔹 ROW 1 – Slip Number (Full Width)
                                          Text(
                                            "Slip No: ${item.slipNumber}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          const SizedBox(height: 6),

                                          /// 🔹 ROW 2 – Status (Left) & Actions (Right)
                                          Row(
                                            children: [
                                              /// Approval Status
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  gradient: item
                                                              .approvalStatus ==
                                                          "Approved"
                                                      ? const LinearGradient(
                                                          colors: [
                                                              Color(0xFF0F830B),
                                                              Color(0xFF29B324)
                                                            ])
                                                      : item.approvalStatus ==
                                                              "Awaiting Approval"
                                                          ? const LinearGradient(
                                                              colors: [
                                                                  Color(
                                                                      0xFF977171),
                                                                  Color(
                                                                      0xFFB58B8B)
                                                                ])
                                                          : const LinearGradient(
                                                              colors: [
                                                                  Color(
                                                                      0xFF4E8D89),
                                                                  Color(
                                                                      0xFF6FBAB5)
                                                                ]),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  item.approvalStatus,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),

                                              const Spacer(), // 🔥 pushes button to right

                                              /// Actions Button
                                              ElevatedButton.icon(
                                                icon: const Icon(
                                                    Icons.visibility,
                                                    size: 18),
                                                label: const Text("Actions"),
                                                onPressed: () {
                                                  _openActionPopup(item.id);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      /// 🔹 Second Row
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                                "Date: ${formatDateSafe(item.slipDate)}"),
                                          ),
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                                "Floor: ${item.floorName ?? '-'}"),
                                          ),
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                                "Section: ${item.sectionName ?? '-'}"),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      /// 🔹 Other Details
                                      Text(
                                          "Employee: ${item.employeeName ?? '-'}"),
                                      const SizedBox(height: 6),
                                      Text(
                                          "Contractor: ${item.contractorName ?? '-'}"),
                                      const SizedBox(height: 6),
                                      if (item.approvalStatus ==
                                          "Awaiting Approval") ...[
                                        Text(
                                          "Awaiting Approval For: ${item.awaitingApprovalFor ?? '-'}",
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                    ],

                    /// 🔒 FORM AREA (approval me fully disabled)
                    AbsorbPointer(
                      absorbing: isApprovalMode && !isEditable,
                      child: Opacity(
                        opacity: (isApprovalMode && !isEditable) ? 0.6 : 1.0,
                        child: Column(
                          children: [
                            if (showForm) ...[
                              const SizedBox(height: 12),

                              // Slip No
                              TextField(
                                controller: slipNoCtrl,
                                enabled: false,
                                decoration: const InputDecoration(
                                  labelText: "Slip Number",
                                  border: OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Slip Date
                              TextField(
                                controller: slipDateCtrl,
                                readOnly: true,
                                enabled: isEditable,
                                onTap: _pickDate,
                                decoration: const InputDecoration(
                                  labelText: "Slip Date",
                                  suffixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Section
                              DropdownButtonFormField<int>(
                                value: selectedSectionId,
                                hint: const Text("Select Section"),
                                items: sectionList.map((s) {
                                  return DropdownMenuItem<int>(
                                    value: s.id,
                                    child: Text(s.sectionName),
                                  );
                                }).toList(),
                                onChanged: isEditable
                                    ? (v) {
                                        print("Section changed: $v");
                                        setState(() => selectedSectionId = v);
                                      }
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: "Section",
                                  border: OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Floor
                              DropdownButtonFormField<int>(
                                value: selectedFloorId,
                                hint: const Text("Select Floor"),
                                items: floorData.map((f) {
                                  return DropdownMenuItem<int>(
                                    value: f.id,
                                    child: Text(f.floorName),
                                  );
                                }).toList(),
                                onChanged: isEditable
                                    ? (v) => setState(() => selectedFloorId = v)
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: "Floor",
                                  border: OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Employee
                              DropdownSearch<EmployeeModel>(
                                selectedItem: selectedEmployee,
                                asyncItems: loadEmployees,
                                enabled: isEditable,
                                itemAsString: (e) => e.displayName,
                                clearButtonProps: const ClearButtonProps(
                                  isVisible: true,
                                ),
                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  isFilterOnline: true,
                                ),
                                dropdownDecoratorProps:
                                    const DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: "Employee",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    selectedEmployee = v;
                                  });
                                },
                              ),

                              const SizedBox(height: 12),

                              // Contractor
                              DropdownSearch<ContractorModel>(
                                selectedItem: selectedContractor,
                                asyncItems: loadContractors,
                                enabled: isEditable,
                                itemAsString: (c) => c.displayName,
                                compareFn: (a, b) => a.id == b.id,
                                clearButtonProps: const ClearButtonProps(
                                  isVisible: true, // 🔥 clear icon
                                ),
                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  isFilterOnline: true,
                                ),
                                dropdownDecoratorProps:
                                    const DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: "Contractor",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    selectedContractor = v;
                                  });
                                },
                              ),

                              const SizedBox(height: 24),

                              // Item Details Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Item Details",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text("Add Line"),
                                    onPressed: isEditable
                                        ? () async {
                                            resetItemFields();
                                            final result = await openItemSheet(
                                                UiItemDetail());
                                            if (result != null) {
                                              setState(() =>
                                                  itemDetails.add(result));
                                            }
                                          }
                                        : null,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: itemDetails.length,
                                itemBuilder: (_, i) {
                                  final item = itemDetails[i];
                                  print(
                                      "INDEX: $i  QTY: ${item.qty}  HASH: ${item.hashCode}");

                                  print(
                                      "👉 RequiredQty UI: ${item.requiredQty}");
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Row for Item Name + Remove Button
                                          Row(
                                            children: [
                                              Expanded(
                                                // 🔥 IMPORTANT
                                                child: _infoText(
                                                    "Item", item.item),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        color: Colors.blue),
                                                    onPressed: isEditable
                                                        ? () => addItem(
                                                            UiItemDetail.clone(
                                                                item),
                                                            index: i)
                                                        : null,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    onPressed: isEditable
                                                        ? () => deleteItem(i)
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          const Divider(height: 16),

                                          // Qty & Unit
                                          _twoColRow(
                                            _infoText(
                                              "Required Qty",
                                              item.requiredQty.toString(),
                                            ),
                                            item.unit.isNotEmpty
                                                ? _infoText("Unit", item.unit)
                                                : const SizedBox(),
                                          ),

                                          // Available Qty (optional)
                                          if (item.availableQty != null)
                                            _infoText("Available Qty",
                                                item.availableQty!.toString()),

                                          // Place of Issue & Activity No
                                          if (item.placeOfIssue.isNotEmpty ||
                                              item.activityNo != null)
                                            _twoColRow(
                                              item.placeOfIssue.isNotEmpty
                                                  ? _infoText("Place Of Issue",
                                                      item.placeOfIssue)
                                                  : const SizedBox(),
                                              item.activityNo != null
                                                  ? _infoText(
                                                      "Activity",
                                                      item.selectedActivity
                                                              ?.activityName ??
                                                          "-",
                                                    )
                                                  : const SizedBox(),
                                            ),

                                          // Equipment (optional)
                                          if (item.equipmentName != null &&
                                              item.equipmentName!.isNotEmpty)
                                            _infoText("Equipment",
                                                item.equipmentName!),

                                          // Remarks (optional)
                                          if (item.remarks.isNotEmpty)
                                            _infoText("Remarks", item.remarks),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    /// 🔘 ACTION BUTTONS (ALWAYS ENABLED)
                    const SizedBox(height: 16),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        key: ValueKey(showForm),
                        children: [
                          if (showSubmitButton)
                            Expanded(
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: isLoading ? null : saveMRIS,
                                  child: const Text(
                                    "Submit",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          if (showApprovalButtons) ...[
                            Expanded(
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: approveMRIS,
                                  child: const Text(
                                    "Approve",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: disapproveMRIS,
                                  child: const Text(
                                    "Disapprove",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
