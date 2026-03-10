// material_requisition_slip_model.dart
class MaterialIssue {
  final int id;
  final String slipNumber;
  final DateTime slipDate;
  final String? floorName;
  final String? sectionName;
  final String? employeeName;
  final String? contractorName;
  final String syncStatus;
  final bool isActive;
  final String approvalStatus;
  final String? AwaitingApprovalFor;

  MaterialIssue({
    required this.id,
    required this.slipNumber,
    required this.slipDate,
    this.floorName,
    this.sectionName,
    this.employeeName,
    this.contractorName,
    required this.syncStatus,
    required this.isActive,
    required this.approvalStatus,
    this.AwaitingApprovalFor,
  });

  factory MaterialIssue.fromJson(Map<String, dynamic> json) {
    return MaterialIssue(
      id: json['ID'],
      slipNumber: json['SlipNumber'] ?? '',
      slipDate: json['SlipDate'] != null
          ? DateTime.parse(json['SlipDate'])
          : DateTime.now(),
      floorName: json['FloorName'],
      sectionName: json['SectionName'],
      employeeName: json['EmployeeName'],
      contractorName: json['ContractorName'],
      syncStatus: json['SyncStatus'] ?? '',
      isActive: json['IsActive'] ?? false,
      approvalStatus: json['ApprovalStatus'] ?? '',
      AwaitingApprovalFor: json['AwaitingApprovalFor'],
    );
  }

  /// 🔹 Convert to Map for debug
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slipNumber': slipNumber,
      'slipDate': slipDate.toIso8601String(),
      'floorName': floorName,
      'sectionName': sectionName,
      'employeeName': employeeName,
      'contractorName': contractorName,
      'syncStatus': syncStatus,
      'isActive': isActive,
      'approvalStatus': approvalStatus,
      'AwaitingApprovalFor': AwaitingApprovalFor,
    };
  }

  /// 🔹 Optional: override toString() for easy console print
  @override
  String toString() {
    return 'MaterialIssue(id: $id, slipNumber: $slipNumber, status: $approvalStatus, floor: $floorName, section: $sectionName, employee: $employeeName, contractor: $contractorName, awaitingApprovalFor: $AwaitingApprovalFor)';
  }
}

class SectionModel {
  final int id;
  final String sectionName;

  SectionModel({
    required this.id,
    required this.sectionName,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'],
      sectionName: json['sectionName'],
    );
  }
}

class FloorModel {
  final int id;
  final String floorName;

  FloorModel({
    required this.id,
    required this.floorName,
  });

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'],
      floorName: json['floorName'],
    );
  }
}

class EmployeeModel {
  final int id;
  final String displayName;

  EmployeeModel({
    required this.id,
    required this.displayName,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'],
      displayName: json['displayName'],
    );
  }
}

class ContractorModel {
  final int id;
  final String displayName;

  ContractorModel({
    required this.id,
    required this.displayName,
  });

  factory ContractorModel.fromJson(Map<String, dynamic> json) {
    return ContractorModel(
      id: json['id'],
      displayName: json['displayName'],
    );
  }
}

class ItemModel {
  final int id;
  final String displayText;
  final String? unit;

  ItemModel({
    required this.id,
    required this.displayText,
    this.unit,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      displayText: json['displayText'],
      unit: json['unit'], // 👈 API se aa raha ho to
    );
  }
}

class EquipmentModel {
  final int id;
  final String displayName;

  EquipmentModel({required this.id, required this.displayName});

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'],
      displayName: json['displayName'],
    );
  }
}

class ActivityModel {
  final int id;
  final String activityName;

  ActivityModel({
    required this.id,
    required this.activityName,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'],
      activityName: json['activityname'] ?? '',
    );
  }
}

class MaterialIssueRequest {
  int? id; // 👈 New field for ID (used in update)
  String dataAreaId;
  String slipNumber;
  String site;
  int sectionID;
  int floorID;
  String status;
  DateTime slipDate;
  int projectID;
  int? contractorID;
  int isplMaterialIssueType;
  int? employeeID;
  bool isActive;
  int? programId;
  int? createdBy; // 👈 New field for CreatedBy
  int? LastModifiedBy; // 👈 New field for LastModifiedBy
  List<ItemDetail> details;

  MaterialIssueRequest({
    required this.id, // 👈 Optional in constructor
    required this.dataAreaId,
    required this.slipNumber,
    required this.site,
    required this.sectionID,
    required this.floorID,
    required this.status,
    required this.slipDate,
    required this.projectID,
    this.contractorID,
    required this.isplMaterialIssueType,
    this.employeeID,
    required this.isActive,
    this.programId,
    this.createdBy, // 👈 Initialize in constructor
    this.LastModifiedBy, // 👈 Initialize in constructor
    required this.details,
  });

  // Map<String, dynamic> toJson() => {
  //       "DataAreaId": dataAreaId,
  //       "SlipNumber": slipNumber,
  //       "Site": site,
  //       "SectionID": sectionID,
  //       "FloorID": floorID,
  //       "Status": status,
  //       "SlipDate": slipDate.toIso8601String(),
  //       "ProjectID": projectID,
  //       "ContractorID": contractorID,
  //       "ISPLMaterialIsssueType": isplMaterialIssueType,
  //       "EmployeeID": employeeID,
  //       "IsActive": isActive,
  //       "ProgramId": programId,
  //       "Details": details.map((e) => e.toJson()).toList(),
  //     };
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "Id": id, // 👈 Include ID in JSON for update operations
      "DataAreaId": dataAreaId,
      "SlipNumber": slipNumber,
      "Site": site,
      "SectionID": sectionID,
      "FloorID": floorID,
      "Status": status,
      "SlipDate": slipDate.toIso8601String(),
      "ProjectID": projectID,
      "ISPLMaterialIsssueType": isplMaterialIssueType,
      "IsActive": isActive,
      "ProgramId": programId,
      "CreatedBy": createdBy,
      "LastModifiedBy": LastModifiedBy,
      "Details": details.map((e) => e.toJson()).toList(),
    };

    // ✅ EXACT ANGULAR BEHAVIOUR
    if (employeeID != null) {
      data["EmployeeID"] = employeeID;
    }

    if (contractorID != null) {
      data["ContractorID"] = contractorID;
    }

    return data;
  }
}

class ItemDetail {
  int? id; // ✅ backend detail ID for update
  int lineNumber;
  int itemID;
  String equipmentIdISPL;
  String placeOfIssue;
  String unit;
  int activityID;
  int projectID;
  String remarks;
  int requiredQty;
  int issueQty;
  int qty;
  String journalNum;

  ItemDetail({
    this.id, // ✅ add this
    required this.lineNumber,
    required this.itemID,
    required this.equipmentIdISPL,
    required this.placeOfIssue,
    required this.unit,
    required this.activityID,
    required this.projectID,
    required this.remarks,
    required this.requiredQty,
    required this.issueQty,
    required this.qty,
    required this.journalNum,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) "ID": id, // ✅ include if exists
        "LineNumber": lineNumber,
        "ItemID": itemID,
        "EquipmentId_ISPL": equipmentIdISPL,
        "PlaceOfIssue": placeOfIssue,
        "Unit": unit,
        "ActivityID": activityID,
        "ProjectID": projectID,
        "Remarks": remarks,
        "RequiredQty": requiredQty,
        "IssueQty": issueQty,
        "Qty": qty,
        "JournalNum": journalNum,
      };
}

class UiItemDetail {
  String item;
  String unit;
  int qty;
  String remarks;
  String placeOfIssue;

  UiItemDetail({
    this.item = '',
    this.unit = '',
    this.qty = 1,
    this.remarks = '',
    this.placeOfIssue = '',
  });

  UiItemDetail.clone(UiItemDetail other)
      : item = other.item,
        unit = other.unit,
        qty = other.qty,
        remarks = other.remarks,
        placeOfIssue = other.placeOfIssue;
}
