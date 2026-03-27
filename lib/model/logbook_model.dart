// class LogBookModal {
//   final int id;
//   final String? logBookCode;
//   final String? logBookDate;
//   final String? startTime;
//   final String? endTime;
//   final String? name;
//   final bool? isNoWorkDone;

//   LogBookModal({
//     required this.id,
//     this.logBookCode,
//     this.logBookDate,
//     this.startTime,
//     this.endTime,
//     this.name,
//     this.isNoWorkDone,
//   });

//   factory LogBookModal.fromJson(Map<String, dynamic> json) {
//     return LogBookModal(
//       id: json['id'] ?? 0,
//       logBookCode: json['logBookCode'],
//       logBookDate: json['logBookDate'],
//       startTime: json['startTime'],
//       endTime: json['endTime'],
//       name: json['name'],
//       isNoWorkDone: json['isNoWorkDone'],
//     );
//   }

//   @override
//   String toString() {
//     return 'LogBook(id: $id, name: $name, code: $logBookCode)';
//   }
// }

class EquipmentModel {
  final int id;
  final String? displayText;
  final String? label;
  final String? value;
  final String? assetType;

  EquipmentModel({
    required this.id,
    this.displayText,
    this.label,
    this.value,
    this.assetType,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'] ?? 0,
      displayText: json['displayText'],
      label: json['label'],
      value: json['value'],
      assetType: json['assetType'],
    );
  }
}

class AssetTypeModel {
  final int id;
  final String? displayText;
  final String? label;
  final String? value; // 🔥 ADD THIS

  AssetTypeModel({
    required this.id,
    this.displayText,
    this.label,
    this.value,
  });

  factory AssetTypeModel.fromJson(Map<String, dynamic> json) {
    return AssetTypeModel(
      id: json['id'] ?? 0,
      displayText: json['displayText'],
      label: json['label'],
      value: json['value'], // 🔥 IMPORTANT
    );
  }
}

class Operator {
  final int id;
  final String userName;

  Operator({required this.id, required this.userName});

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      id: json['id'] ?? 0, // ✅ small 'id'
      userName: json['userName'] ?? '',
    );
  }
}

class ReadingType {
  final int id;
  final String name;

  ReadingType({
    required this.id,
    required this.name,
  });

  factory ReadingType.fromJson(Map<String, dynamic> json) {
    return ReadingType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class WorkDescription {
  final int? id;
  final String? name;

  WorkDescription({
    this.id,
    this.name,
  });

  factory WorkDescription.fromJson(Map<String, dynamic> json) {
    return WorkDescription(
      id: json['id'],
      name: json['name'],
    );
  }
}

class BreakDownReason {
  int? id;
  String? name;
  String? counterTypeId;

  BreakDownReason({this.id, this.name, this.counterTypeId});

  factory BreakDownReason.fromJson(Map<String, dynamic> json) {
    return BreakDownReason(
      id: json['id'],
      name: json['name'],
      counterTypeId: json['counterTypeId'],
    );
  }

  @override
  String toString() {
    return 'id: $id, name: $name, counterTypeId: $counterTypeId';
  }
}

class UomModel {
  final int? id;
  final String? symbol;

  UomModel({this.id, this.symbol});

  factory UomModel.fromJson(Map<String, dynamic> json) {
    return UomModel(
      id: json['id'],
      symbol: json['symbol'],
    );
  }
}

class BreakdownType {
  final int id;
  final String name;

  BreakdownType({required this.id, required this.name});
}

List<BreakdownType> breakdownTypeList = [
  BreakdownType(id: 1, name: 'Breakdown'),
  BreakdownType(id: 2, name: 'Maintenance'),
];

class BreakdownModel {
  int? typeID;
  int? reasonID;
  List<BreakDownReason> reasonsList;
  int? categoryId;

  BreakdownModel(
      {this.typeID,
      this.reasonID,
      this.reasonsList = const [],
      this.categoryId});
}

class AssetCounter {
  int? id;
  String? name;

  AssetCounter({this.id, this.name});

  factory AssetCounter.fromJson(Map<String, dynamic> json) {
    return AssetCounter(
      id: json['id'],
      name: json['name'],
    );
  }
}

class RmType {
  int? id;
  String? name;

  RmType({this.id, this.name});

  factory RmType.fromJson(Map<String, dynamic> json) {
    return RmType(
      id: json['id'],
      name: json['name'],
    );
  }
}

class LogBookModal {
  int? id;
  int? equipmentCategoryID;
  String? logBookDate;
  String? logBookCode;
  int? projectID;
  int? equipmentID;
  String? startTime;
  String? endTime;
  String? remarks;
  double? idleHours;
  int? operatorID;
  bool? isNoWorkDone;
  double? lunchHours;
  int? operatorID2;
  int? createdBy;
  String? name;

  List<LogBookReadingDetails> logBookReadingDetails;
  List<WorkDescriptionDetails> workDescriptionDetails;
  List<BreakDownDetails> breakDownDetails;

  LogBookModal({
    this.id,
    this.equipmentCategoryID,
    this.logBookDate,
    this.logBookCode,
    this.projectID,
    this.equipmentID,
    this.startTime,
    this.endTime,
    this.remarks,
    this.idleHours,
    this.operatorID,
    this.isNoWorkDone,
    this.lunchHours,
    this.operatorID2,
    this.createdBy,
    this.name,
    this.logBookReadingDetails = const [],
    this.workDescriptionDetails = const [],
    this.breakDownDetails = const [],
  });

  /// ✅ API JSON
  Map<String, dynamic> toJson() {
    return {
      "ID": id,
      "EquipmentCategoryID": equipmentCategoryID,
      "LogBookDate": logBookDate,
      "LogBookCode": logBookCode,
      "ProjectID": projectID,
      "EquipmentID": equipmentID,
      "StartTime": startTime,
      "EndTime": endTime,
      "Remarks": remarks,
      "IdleHours": idleHours,
      "OperatorID": operatorID,
      "IsNoWorkDone": isNoWorkDone,
      "LunchHours": lunchHours,
      "OperatorID2": operatorID2,
      "CreatedBy": createdBy,
      "Name": name,
      "LogBookReadingDetails":
          logBookReadingDetails.map((e) => e.toJson()).toList(),
      "WorkDescriptionDetails":
          workDescriptionDetails.map((e) => e.toJson()).toList(),
      "BreakDownDetails": breakDownDetails.map((e) => e.toJson()).toList(),
    };
  }

  /// (Optional) for GET
  factory LogBookModal.fromJson(Map<String, dynamic> json) {
    return LogBookModal(
      id: json['id'],
      equipmentCategoryID: json['equipmentCategoryID'],
      logBookDate: json['logBookDate'],
      logBookCode: json['logBookCode'],
      projectID: json['projectID'],
      equipmentID: json['equipmentID'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      remarks: json['remarks'],
      idleHours: (json['idleHours'] as num?)?.toDouble(),
      operatorID: json['operatorID'],
      isNoWorkDone: json['isNoWorkDone'],
      lunchHours: (json['lunchHours'] as num?)?.toDouble(),
      operatorID2: json['operatorID2'],
      createdBy: json['createdBy'],
      name: json['name'],

      /// 🔥 READING DETAILS
      logBookReadingDetails: (json['logBookReadingDetails'] as List? ?? [])
          .map((e) => LogBookReadingDetails(
                readingID: e['readingID'],
                openning: (e['openning'] as num?)?.toDouble(),
                closing: (e['closing'] as num?)?.toDouble(),
                remarks: e['remarks'],
              ))
          .toList(),

      /// 🔥 WORK DETAILS
      workDescriptionDetails: (json['workDescriptionDetails'] as List? ?? [])
          .map((e) => WorkDescriptionDetails(
                fromTime: e['fromTime'],
                toTime: e['toTime'],
                workDownHours: (e['workDownHours'] as num?)?.toDouble(),
                workDescriptionID: e['workDescriptionID'],
                uomID: e['uomID'],
                machineOutput: (e['machineOutput'] as num?)?.toDouble(),
                remarks: e['remarks'],
                projectID: e['projectID'],
              ))
          .toList(),

      /// 🔥 BREAKDOWN
      breakDownDetails: (json['breakDownDetails'] as List? ?? [])
          .map((e) => BreakDownDetails(
                fromTime: e['fromTime'],
                toTime: e['toTime'],
                spentHours: (e['spentHours'] as num?)?.toDouble(),
                reading: (e['reading'] as num?)?.toDouble(),
                readingID: e['readingID'],
                rmTypeID: e['rmTypeID'],
                reasonID: e['reasonID'],
                typeID: e['typeID'],
                remarks: e['remarks'],
              ))
          .toList(),
    );
  }
}

class LogBookReadingDetails {
  int? readingID;
  double? openning;
  double? closing;
  String? remarks;

  LogBookReadingDetails({
    this.readingID,
    this.openning,
    this.closing,
    this.remarks,
  });

  Map<String, dynamic> toJson() => {
        "ReadingID": readingID,
        "Openning": openning,
        "Closing": closing,
        "Remarks": remarks,
      };
}

class WorkDescriptionDetails {
  String? fromTime;
  String? toTime;
  double? workDownHours;
  int? workDescriptionID;
  int? uomID;
  double? machineOutput;
  String? remarks;
  int? projectID;

  WorkDescriptionDetails({
    this.fromTime,
    this.toTime,
    this.workDownHours,
    this.workDescriptionID,
    this.uomID,
    this.machineOutput,
    this.remarks,
    this.projectID,
  });

  Map<String, dynamic> toJson() => {
        "FromTime": fromTime,
        "ToTime": toTime,
        "WorkDownHours": workDownHours,
        "WorkDescriptionID": workDescriptionID,
        "UomID": uomID,
        "MachineOutput": machineOutput,
        "Remarks": remarks,
        "ProjectID": projectID,
      };
}

class BreakDownDetails {
  String? fromTime;
  String? toTime;
  double? spentHours;
  double? reading;
  int? readingID;
  String? reason;
  String? remarks;
  int? subPartId;
  double? maintenanceHours;
  int? rmTypeID;
  int? reasonID;
  int? typeID;

  BreakDownDetails({
    this.fromTime,
    this.toTime,
    this.spentHours,
    this.reading,
    this.readingID,
    this.reason,
    this.remarks,
    this.subPartId,
    this.maintenanceHours,
    this.rmTypeID,
    this.reasonID,
    this.typeID,
  });

  Map<String, dynamic> toJson() => {
        "FromTime": fromTime,
        "ToTime": toTime,
        "SpentHours": spentHours,
        "Reading": reading,
        "ReadingID": readingID,
        "Reason": reason,
        "Remarks": remarks,
        "SubPartId": subPartId,
        "MaintenanceHours": maintenanceHours,
        "RMTypeID": rmTypeID,
        "ReasonID": reasonID,
        "TypeID": typeID,
      };
}
