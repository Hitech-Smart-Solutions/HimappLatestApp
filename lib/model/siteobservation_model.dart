class SiteObservation {
  final int id;
  final String siteObservationCode;
  final String observationDescription;
  final String observationType;
  final String issueType;
  final String functionType;
  // final int observationStatusId;
  final String observationStatus;
  final String projectName;
  final DateTime transactionDate;
  final String isoverdue;
  final DateTime dueDate;
  final bool compliancerequired;
  final bool escalationrequired;
  final int rootCauseID;
  final String rootCauseName;
  final String reworkCost;
  final String rootcauseDescription;
  final String corretiveActionToBeTaken;
  final String preventiveActionTaken;
  final String closeRemarks;

  SiteObservation({
    required this.id,
    required this.siteObservationCode,
    required this.observationDescription,
    required this.observationType,
    required this.issueType,
    required this.functionType,
    // required this.observationStatusId,
    required this.observationStatus,
    required this.projectName,
    required this.transactionDate,
    required this.isoverdue,
    required this.dueDate,
    required this.compliancerequired,
    required this.escalationrequired,
    required this.rootCauseID,
    required this.rootCauseName,
    required this.reworkCost,
    required this.rootcauseDescription,
    required this.corretiveActionToBeTaken,
    required this.preventiveActionTaken,
    required this.closeRemarks,
  });

  factory SiteObservation.fromJson(Map<String, dynamic> json) {
    // print("observation33:$json");

    return SiteObservation(
      id: (json['ID'] ?? 0) as int,
      siteObservationCode: json['SiteObservationCode'] ?? 'N/A',
      observationDescription: json['ObservationDescription'] ?? 'N/A',
      observationType: json['observationtype'] ?? 'N/A',
      issueType: json['issuetype'] ?? 'N/A',
      functionType: json['functiontype'] ?? 'N/A',
      // observationStatusId: (json['observationStatusId'] as num).toInt(),
      observationStatus: json['ObservationStatus'] ?? 'N/A',
      projectName: json['ProjectName'] ?? 'N/A',
      transactionDate: _parseDate(json['TrancationDate']),
      isoverdue: json['isoverdue'] ?? 'N/A',
      dueDate: _parseDate(json['DueDate']),
      compliancerequired: json['ComplianceRequired'] ?? false,
      escalationrequired: json['EscalationRequired'] ?? false,
      rootCauseID: (json['rootCauseID'] ?? 0) as int,
      rootCauseName: json['RootCauseName'] ?? 'N/A',
      reworkCost: (json['ReworkCost'] ?? '').toString(),
      rootcauseDescription: (json['rootcauseDescription'] ?? '').toString(),
      corretiveActionToBeTaken:
          (json['CorretiveActionToBeTaken'] ?? '').toString(),
      preventiveActionTaken: (json['PreventiveActionTaken'] ?? '').toString(),
      closeRemarks: (json['closeRemarks'] ?? '').toString(),
    );
  }

  static DateTime _parseDate(dynamic dateStr) {
    if (dateStr == null || (dateStr is String && dateStr.trim().isEmpty)) {
      return DateTime(2000); // default fallback date
    }

    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime(2000); // fallback on parse error
    }
  }
}

class IssueType {
  final int id;
  final String name;
  final int observationTypeID; // optional if you want to keep it

  IssueType({
    required this.id,
    required this.name,
    required this.observationTypeID,
  });

  factory IssueType.fromJson(Map<String, dynamic> json) {
    return IssueType(
      id: json['id'],
      name: json['name'],
      observationTypeID: json['observationTypeID'],
    );
  }
}

// class Activities {
//   final int id;
//   final String activityName;

//   Activities({required this.id, required this.activityName});

//   // From JSON constructor to convert the response data to Activities object
//   factory Activities.fromJson(Map<String, dynamic> json) {
//     return Activities(
//       id: json['id'],
//       activityName: json['activityName'],
//     );
//   }
// }

class Activities {
  final int id;
  final String activityName;

  Activities({required this.id, required this.activityName});

  // From JSON constructor to convert the response data to Activities object
  factory Activities.fromJson(Map<String, dynamic> json) {
    return Activities(
      id: json['id'] ?? 0, // Default to 0 if id is missing or null
      activityName: json['activityName'] ??
          'Unknown', // Default to 'Unknown' if activityName is null
    );
  }
}

class Observation {
  final int id;
  final int observationTypeID;
  final int issueTypeID;
  final String observationDescription;
  final String observationDisplayText;
  final bool complianceRequired;
  final bool escalationRequired;
  final int dueTimeInHrs;
  final String actionToBeTaken;
  final String lastModifiedBy;
  final String lastModifiedDate;

  Observation({
    required this.id,
    required this.observationTypeID,
    required this.issueTypeID,
    required this.observationDescription,
    required this.observationDisplayText,
    required this.complianceRequired,
    required this.escalationRequired,
    required this.dueTimeInHrs,
    required this.actionToBeTaken,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
  });

  factory Observation.fromJson(Map<String, dynamic> json) {
    print("Observation fromJson: $json");
    return Observation(
      id: (json['id'] as num).toInt(),
      observationTypeID: (json['observationTypeID'] as num).toInt(),
      issueTypeID: (json['issueTypeID'] as num).toInt(),
      observationDescription: json['observationDescription'] ?? '',
      observationDisplayText: json['observationDisplayText'] ?? '',
      complianceRequired: json['complianceRequired'] ?? false,
      escalationRequired: json['escalationRequired'] ?? false,
      dueTimeInHrs: (json['dueTimeInHrs'] as num).toInt(),
      actionToBeTaken: json['actionToBeTaken'] ?? '',
      lastModifiedBy: json['lastModifiedBy'].toString(),
      lastModifiedDate: DateTime.parse(json['lastModifiedDate']).toString(),
    );
  }
}

class ObservationType {
  final String uniqueID;
  final int id;
  final String name;
  final int statusID;
  final bool isActive;

  ObservationType({
    required this.uniqueID,
    required this.id,
    required this.name,
    required this.statusID,
    required this.isActive,
  });

  factory ObservationType.fromJson(Map<String, dynamic> json) {
    return ObservationType(
      uniqueID: json['uniqueID'],
      id: json['id'],
      name: json['name'],
      statusID: json['statusID'],
      isActive: json['isActive'],
    );
  }
}

class Area {
  final int id;
  final String sectionName;
  final String labelName;
  final bool selected;

  Area(
      {required this.id,
      required this.sectionName,
      required this.labelName,
      required this.selected});

  // Factory constructor to convert JSON to Area object
  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'],
      sectionName: json['sectionName'],
      labelName: json['labelName'],
      selected: json['selected'],
    );
  }
}

// Factory constructor to convert JSON to Floor object
class Floor {
  final int id;
  final String floorName;
  final String labelName;
  final bool selected;

  Floor(
      {required this.id,
      required this.floorName,
      required this.labelName,
      required this.selected});

  // Factory constructor to convert JSON to Floor object
  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['id'],
      floorName: json['floorName'],
      labelName: json['labelName'],
      selected: json['selected'],
    );
  }
}

// Factory constructor to convert JSON to Floor object
class Part {
  final int id;
  final String partName;
  final String labelName;
  final bool selected;

  Part(
      {required this.id,
      required this.partName,
      required this.labelName,
      required this.selected});

  // Factory constructor to convert JSON to Part object
  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      id: json['id'],
      partName: json['partName'],
      labelName: json['labelName'],
      selected: json['selected'],
    );
  }
}

// Factory constructor to convert JSON to Element object
class Elements {
  final int id;
  final String elementName;
  final String labelName;
  final bool selected;

  Elements(
      {required this.id,
      required this.elementName,
      required this.labelName,
      required this.selected});

  // Factory constructor to convert JSON to Part object
  factory Elements.fromJson(Map<String, dynamic> json) {
    return Elements(
      id: json['id'],
      elementName: json['elementName'],
      labelName: json['labelName'],
      selected: json['selected'],
    );
  }
}

// Factory constructor to convert JSON to Party object
class Party {
  String uniqueID;
  int id;
  String partyName;
  int partyTypeID;
  int createdBy;
  DateTime createdDate;
  int lastModifiedBy;
  DateTime lastModifiedDate;

  // Constructor
  Party({
    required this.uniqueID,
    required this.id,
    required this.partyName,
    required this.partyTypeID,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
  });

  // Convert a JSON object to a Party object
  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      uniqueID: json['uniqueID'],
      id: json['id'],
      partyName: json['partyName'],
      partyTypeID: json['partyTypeID'],
      createdBy: json['createdBy'],
      createdDate: DateTime.parse(json['createdDate']),
      lastModifiedBy: json['lastModifiedBy'],
      lastModifiedDate: DateTime.parse(json['lastModifiedDate']),
    );
  }

  // // Convert a Party object to a JSON object
  // Map<String, dynamic> toJson() {
  //   return {
  //     'uniqueID': uniqueID,
  //     'id': id,
  //     'partyName': partyName,
  //     'partyTypeID': partyTypeID,
  //     'createdBy': createdBy,
  //     'createdDate': createdDate.toIso8601String(),
  //     'lastModifiedBy': lastModifiedBy,
  //     'lastModifiedDate': lastModifiedDate.toIso8601String(),
  //   };
  // }
}

class User {
  final int id;
  final String userName;

  User({required this.id, required this.userName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      userName: json['userName'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => userName; // Optional: for logging
}

class Activity {
  final int id;
  final String activityName;

  Activity({
    required this.id,
    required this.activityName,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      activityName: json['activityName'],
    );
  }
}

class RootCause {
  final int id;
  final String rootCauseName;
  final bool selected;

  RootCause({
    required this.id,
    required this.rootCauseName,
    this.selected = false,
  });

  factory RootCause.fromJson(Map<String, dynamic> json) {
    return RootCause(
      id: json['id'],
      rootCauseName: json['rootCauseName'],
      selected: json['selected'] ?? false, // ✅ default value
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RootCause && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RootCause(id: $id, rootCauseName: $rootCauseName, selected: $selected)';
  }
}

// site_observation_model.dart
class SiteObservationModel {
  final String uniqueID;
  final int id;
  final String siteObservationCode;
  final String trancationDate;
  final int observationRaisedBy;
  final int observationID;
  final int observationTypeID;
  final int issueTypeID;
  final String? dueDate;
  final String observationDescription;
  final String? userDescription;
  final bool complianceRequired;
  final bool escalationRequired;
  final String actionToBeTaken;
  final int companyID;
  final int projectID;
  final int functionID;
  final int activityID;
  final int observedBy;
  final int sectionID;
  final int floorID;
  final int partID;
  final int elementID;
  final int contractorID;
  final double reworkCost;
  final String comments;
  final int rootCauseID;
  final String corretiveActionToBeTaken;
  final String preventiveActionTaken;
  final int? violationTypeID;
  final int statusID;
  final bool isActive;
  final int createdBy;
  final String createdDate;
  final int lastModifiedBy;
  final String lastModifiedDate;
  final List<SiteObservationActivity> siteObservationActivity;

  SiteObservationModel({
    required this.uniqueID,
    required this.id,
    required this.siteObservationCode,
    required this.trancationDate,
    required this.observationRaisedBy,
    required this.observationID,
    required this.observationTypeID,
    required this.issueTypeID,
    required this.dueDate,
    required this.observationDescription,
    this.userDescription,
    required this.complianceRequired,
    required this.escalationRequired,
    required this.actionToBeTaken,
    required this.companyID,
    required this.projectID,
    required this.functionID,
    required this.activityID,
    required this.observedBy,
    required this.sectionID,
    required this.floorID,
    required this.partID,
    required this.elementID,
    required this.contractorID,
    required this.reworkCost,
    required this.comments,
    required this.rootCauseID,
    required this.corretiveActionToBeTaken,
    required this.preventiveActionTaken,
    this.violationTypeID,
    required this.statusID,
    required this.isActive,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
    required this.siteObservationActivity,
  });

  Map<String, dynamic> toJson() {
    return {
      'uniqueID': uniqueID,
      'id': id,
      'siteObservationCode': siteObservationCode,
      'trancationDate': trancationDate,
      'observationRaisedBy': observationRaisedBy,
      "observationID": observationID,
      'observationTypeID': observationTypeID,
      'issueTypeID': issueTypeID,
      'dueDate': dueDate,
      'observationDescription': observationDescription,
      'userDescription': userDescription,
      'complianceRequired': complianceRequired,
      'escalationRequired': escalationRequired,
      'actionToBeTaken': actionToBeTaken,
      'companyID': companyID,
      'projectID': projectID,
      'functionID': functionID,
      'activityID': activityID,
      'observedBy': observedBy,
      'sectionID': sectionID,
      'floorID': floorID,
      'partID': partID,
      'elementID': elementID,
      'contractorID': contractorID,
      'reworkCost': reworkCost,
      'comments': comments,
      'rootCauseID': rootCauseID,
      'corretiveActionToBeTaken': corretiveActionToBeTaken,
      'preventiveActionTaken': preventiveActionTaken,
      'violationTypeID': violationTypeID,
      'statusID': statusID,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdDate': createdDate,
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedDate': lastModifiedDate,
      'siteObservationActivity':
          siteObservationActivity.map((e) => e.toJson()).toList(),
      // 'activityDTO': siteObservationActivity.map((e) => e.toJson()).toList(),
    };
  }
}

// Update & Draft
// class SiteObservationUpdateDraftModel {
//   final int id;
//   final String? dueDate;
//   final String observationDescription;
//   final bool complianceRequired;
//   final bool escalationRequired;
//   final String actionToBeTaken;
//   final int activityID;
//   final int sectionID;
//   final int floorID;
//   final int partID;
//   final int elementID;
//   final int contractorID;
//   final int observedBy;
//   final int statusID;
//   final int lastModifiedBy;
//   final String lastModifiedDate;
//   final List<ActivityDTO> activityDTO;

//   SiteObservationUpdateDraftModel({
//     required this.id,
//     this.dueDate,
//     required this.observationDescription,
//     required this.complianceRequired,
//     required this.escalationRequired,
//     required this.actionToBeTaken,
//     required this.activityID,
//     required this.sectionID,
//     required this.floorID,
//     required this.partID,
//     required this.elementID,
//     required this.contractorID,
//     required this.observedBy,
//     required this.statusID,
//     required this.lastModifiedBy,
//     required this.lastModifiedDate,
//     required this.activityDTO,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'dueDate': dueDate,
//       'observationDescription': observationDescription,
//       'complianceRequired': complianceRequired,
//       'escalationRequired': escalationRequired,
//       'actionToBeTaken': actionToBeTaken,
//       'activityID': activityID,
//       'sectionID': sectionID,
//       'floorID': floorID,
//       'partID': partID,
//       'elementID': elementID,
//       'contractorID': contractorID,
//       "observedBy": observedBy,
//       'statusID': statusID,
//       'lastModifiedBy': lastModifiedBy,
//       'lastModifiedDate': lastModifiedDate,
//       'activityDTO': activityDTO.map((e) => e.toJson()).toList(),
//     };
//   }
// }

class SiteObservationUpdateDraftModel {
  final int id;
  final String? dueDate;
  final String observationDescription;
  final bool complianceRequired;
  final bool escalationRequired;
  final String actionToBeTaken;
  final int violationTypeID;
  final int activityID;
  final int sectionID;
  final int floorID;
  final int partID;
  final int elementID;
  final int contractorID;
  final int observedBy;
  final int statusID;
  final int lastModifiedBy;
  final String lastModifiedDate;
  final List<ActivityDTO> activityDTO;

  SiteObservationUpdateDraftModel({
    required this.id,
    this.dueDate,
    required this.observationDescription,
    required this.complianceRequired,
    required this.escalationRequired,
    required this.actionToBeTaken,
    this.violationTypeID = 0, // Default to 0 if not provided
    required this.activityID,
    required this.sectionID,
    required this.floorID,
    required this.partID,
    required this.elementID,
    required this.contractorID,
    required this.observedBy,
    required this.statusID,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
    required this.activityDTO,
  });

  factory SiteObservationUpdateDraftModel.fromJson(Map<String, dynamic> json) {
    print("SiteObservationUpdateDraftModel fromJson: $json");
    return SiteObservationUpdateDraftModel(
      id: json['id'],
      dueDate: json['dueDate'],
      observationDescription: json['observationDescription'],
      complianceRequired: json['complianceRequired'],
      escalationRequired: json['escalationRequired'],
      actionToBeTaken: json['actionToBeTaken'],
      violationTypeID:
          json['violationTypeID'] ?? 0, // Default to 0 if not provided
      activityID: json['activityID'],
      sectionID: json['sectionID'],
      floorID: json['floorID'],
      partID: json['partID'],
      elementID: json['elementID'],
      contractorID: json['contractorID'],
      observedBy: json['observedBy'],
      statusID: json['statusID'],
      lastModifiedBy: json['lastModifiedBy'],
      lastModifiedDate: json['lastModifiedDate'],
      activityDTO: (json['activityDTO'] as List)
          .map((e) => ActivityDTO.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dueDate': dueDate,
        'observationDescription': observationDescription,
        'complianceRequired': complianceRequired,
        'escalationRequired': escalationRequired,
        'actionToBeTaken': actionToBeTaken,
        'violationTypeID': violationTypeID,
        'activityID': activityID,
        'sectionID': sectionID,
        'floorID': floorID,
        'partID': partID,
        'elementID': elementID,
        'contractorID': contractorID,
        'observedBy': observedBy,
        'statusID': statusID,
        'lastModifiedBy': lastModifiedBy,
        'lastModifiedDate': lastModifiedDate,
        'activityDTO': activityDTO.map((e) => e.toJson()).toList(),
      };
}

// class ActivityDTO {
//   final int siteObservationID;
//   final int actionID;
//   final String comments;
//   final String documentName;
//   final String fileName;
//   final String fileContentType;
//   final String filePath;
//   final int fromStatusID;
//   final int toStatusID;
//   final int assignedUserID;
//   final int createdBy;
//   final String createdDate;

//   ActivityDTO({
//     required this.siteObservationID,
//     required this.actionID,
//     required this.comments,
//     required this.documentName,
//     required this.fileName,
//     required this.fileContentType,
//     required this.filePath,
//     required this.fromStatusID,
//     required this.toStatusID,
//     required this.assignedUserID,
//     required this.createdBy,
//     required this.createdDate,
//   });

//   factory ActivityDTO.fromJson(Map<String, dynamic> json) {
//     return ActivityDTO(
//       siteObservationID: json['siteObservationID'],
//       actionID: json['actionID'],
//       comments: json['comments'],
//       documentName: json['documentName'],
//       fileName: json['fileName'],
//       fileContentType: json['fileContentType'],
//       filePath: json['filePath'],
//       fromStatusID: json['fromStatusID'],
//       toStatusID: json['toStatusID'],
//       assignedUserID: json['assignedUserID'],
//       createdBy: json['createdBy'],
//       createdDate: json['createdDate'],
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'siteObservationID': siteObservationID,
//         'actionID': actionID,
//         'comments': comments,
//         'documentName': documentName,
//         'fileName': fileName,
//         'fileContentType': fileContentType,
//         'filePath': filePath,
//         'fromStatusID': fromStatusID,
//         'toStatusID': toStatusID,
//         'assignedUserID': assignedUserID,
//         'createdBy': createdBy,
//         'createdDate': createdDate,
//       };
// }

class SiteObservationActivity {
  final int id;
  final int? siteObservationID;
  final int actionID;
  final String comments;
  final String documentName;
  final String? fileName;
  final String? fileContentType;
  final String? filePath;
  final int fromStatusID;
  final int toStatusID;
  final int assignedUserID;
  final String? assignedUserName;
  final int createdBy;
  final String? createdByName;
  final String createdDate;

  SiteObservationActivity({
    required this.id,
    this.siteObservationID,
    required this.actionID,
    required this.comments,
    required this.documentName,
    this.fileName,
    this.fileContentType,
    this.filePath,
    required this.fromStatusID,
    required this.toStatusID,
    required this.assignedUserID,
    this.assignedUserName,
    required this.createdBy,
    this.createdByName,
    required this.createdDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (siteObservationID != null) 'siteObservationID': siteObservationID,
      'actionID': actionID,
      'comments': comments,
      'documentName': documentName,
      'fileName': fileName,
      'fileContentType': fileContentType,
      'filePath': filePath,
      'fromStatusID': fromStatusID,
      'toStatusID': toStatusID,
      'assignedUserID': assignedUserID,
      'assignedUserName': assignedUserName,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdDate': createdDate,
    };
  }

  factory SiteObservationActivity.fromJson(Map<String, dynamic> json) {
    return SiteObservationActivity(
      id: json['id'],
      siteObservationID: json['siteObservationID'],
      actionID: json['actionID'],
      comments: json['comments'],
      documentName: json['documentName'],
      fileName: json['fileName'],
      fileContentType: json['fileContentType'],
      filePath: json['filePath'],
      fromStatusID: json['fromStatusID'],
      toStatusID: json['toStatusID'],
      assignedUserID: json['assignedUserID'],
      assignedUserName: json['assignedUserName'],
      createdBy: json['createdBy'],
      createdByName: json['createdByName'],
      createdDate: json['createdDate'],
    );
  }
}
// class SiteObservationActivity {
//   final int id;
//   final int? siteObservationID;
//   final int actionID;
//   final String comments;
//   final String documentName;
//   final String? fileName;
//   final String? fileContentType;
//   final String? filePath;
//   final int fromStatusID;
//   final int toStatusID;
//   final int assignedUserID;
//   final int createdBy;
//   final String createdDate;

//   SiteObservationActivity({
//     required this.id,
//     this.siteObservationID,
//     required this.actionID,
//     required this.comments,
//     required this.documentName,
//     this.fileName,
//     this.fileContentType,
//     this.filePath,
//     required this.fromStatusID,
//     required this.toStatusID,
//     required this.assignedUserID,
//     required this.createdBy,
//     required this.createdDate,
//   });

//   // From JSON factory constructor
//   factory SiteObservationActivity.fromJson(Map<String, dynamic> json) {
//     print("SiteObservationActivity fromJson: $json");
//     return SiteObservationActivity(
//       id: json['id'] as int,
//       siteObservationID: json['siteObservationID'] as int?,
//       actionID: json['actionID'] as int,
//       comments: json['comments'] as String,
//       documentName: json['documentName'] as String,
//       fileName: json['fileName'] as String?,
//       fileContentType: json['fileContentType'] as String?,
//       filePath: json['filePath'] as String?,
//       fromStatusID: json['fromStatusID'] as int,
//       toStatusID: json['toStatusID'] as int,
//       assignedUserID: json['assignedUserID'] as int,
//       createdBy: json['createdBy'] as int,
//       createdDate: json['createdDate'] as String,
//     );
//   }

//   // To JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'siteObservationID': siteObservationID,
//       'actionID': actionID,
//       'comments': comments,
//       'documentName': documentName,
//       'fileName': fileName,
//       'fileContentType': fileContentType,
//       'filePath': filePath,
//       'fromStatusID': fromStatusID,
//       'toStatusID': toStatusID,
//       'assignedUserID': assignedUserID,
//       'createdBy': createdBy,
//       'createdDate': createdDate,
//     };
//   }

//   // Override toString for debugging and printing
//   @override
//   String toString() {
//     return 'SiteObservationActivity('
//         'id: $id, '
//         'siteObservationID: $siteObservationID, '
//         'actionID: $actionID, '
//         'comments: $comments, '
//         'documentName: $documentName, '
//         'fileName: $fileName, '
//         'fileContentType: $fileContentType, '
//         'filePath: $filePath, '
//         'fromStatusID: $fromStatusID, '
//         'toStatusID: $toStatusID, '
//         'assignedUserID: $assignedUserID, '
//         'createdBy: $createdBy, '
//         'createdDate: $createdDate'
//         ')';
//   }
// }

class NCRObservation {
  final String uniqueID;
  final int id;
  final DateTime trancationDate;
  final String siteObservationCode;
  final String? observationRaisedBy;
  final String observationType;
  final String? issueType;
  final DateTime dueDate;
  final String observationDescription;
  final bool complianceRequired;
  final bool escalationRequired;
  final String? actionToBeTaken;
  final String? contractorName;
  final String statusName;
  final String? assignedUserName;

  NCRObservation({
    required this.uniqueID,
    required this.id,
    required this.trancationDate,
    required this.siteObservationCode,
    required this.observationRaisedBy,
    required this.observationType,
    required this.issueType,
    required this.dueDate,
    required this.observationDescription,
    required this.complianceRequired,
    required this.escalationRequired,
    required this.actionToBeTaken,
    required this.contractorName,
    required this.statusName,
    required this.assignedUserName,
    // required this.createdDate,
  });

  // factory NCRObservation.fromJson(Map<String, dynamic> json) {
  //   return NCRObservation(
  //     uniqueID: json['uniqueID'] ?? '',
  //     id: json['id'] ?? 0,
  //     trancationDate: DateTime.parse(json['trancationDate']),
  //     siteObservationCode: json['siteObservationCode'] ?? '',
  //     observationRaisedBy: json['observationRaisedBy'] ?? '',
  //     observationType: json['observationType'] ?? '',
  //     issueType: json['issueType'] ?? '',
  //     dueDate: DateTime.parse(json['dueDate']),
  //     observationDescription: json['observationDescription'],
  //     complianceRequired: json['complianceRequired'] ?? false,
  //     escalationRequired: json['escalationRequired'] ?? false,
  //     actionToBeTaken: json['actionToBeTaken'] ?? '',
  //     contractorName: json['contractorName'] ?? '',
  //     statusName: json['statusName'] ?? '',
  //     assignedUserName: json['assignedUserName'] ?? '',
  //     // createdDate: DateTime.parse(
  //     //     json['createdDate'] ?? DateTime.now().toIso8601String()),
  //   );
  // }

  factory NCRObservation.fromJson(Map<String, dynamic> json) {
    print("NCRObservation681:$json");
    return NCRObservation(
      uniqueID: json['uniqueID'] ?? '',
      id: json['id'] ?? 0,
      trancationDate:
          DateTime.tryParse(json['trancationDate'] ?? '') ?? DateTime.now(),
      siteObservationCode: json['siteObservationCode'] ?? '',
      observationRaisedBy: json['observationRaisedBy']?.toString(),
      observationType: json['observationType'] ?? '',
      issueType: json['issueType'], // ✅ nullable
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      observationDescription: json['observationDescription'] ?? '',
      complianceRequired: json['complianceRequired'] ?? false,
      escalationRequired: json['escalationRequired'] ?? false,
      actionToBeTaken: json['actionToBeTaken'], // ✅ nullable
      contractorName: json['contractorName'], // ✅ nullable
      statusName: json['statusName'] ?? '',
      assignedUserName: json['assignedUserName'] ?? '', // ✅ nullable
    );
  }
}

class GetSiteObservationMasterById {
  final int id;
  final String observationCode;
  final String description;
  final String? observationRaisedBy;
  final String observationType;
  final int? observationTypeID;
  final String issueType;
  final String contractorName;
  final String actionToBeTaken;
  final double materialCost;
  final double labourCost;
  final String reworkCost;
  final String? rootcauseDescription;
  final int? rootCauseID;
  final String? rootCauseName;
  final String? corretiveActionToBeTaken;
  final String? preventiveActionTaken;
  final String statusName;
  final int statusID;
  final int? assignedUserID;
  final DateTime trancationDate;
  final DateTime createdDate;
  final DateTime dueDate;
  final String activityName;
  final String sectionName;
  final String floorName;
  final String partName;
  final bool complianceRequired;
  final bool escalationRequired;
  final String elementName;
  final int? createdBy; // Assuming elementID is a String
  final String? createdByName; // Assuming createdByName is a String
  final int? activityID; // Assuming activityId is an int
  final int? sectionID;
  final int? floorID;
  final int? partID;
  final int? elementID;
  final int? contractorID;
  final int projectID; // Assuming projectId is a String
  final String observedByName;
  final int? violationTypeID;
  final String violationTypeName;
  final String closeRemarks;
  final String reopenRemarks;
  final String assignedUsersName;
  final String observationNameWithCategory;

  final List<ActivityDTO> activityDTO;
  final List<AssignmentStatusDTO> assignmentStatusDTO;

  GetSiteObservationMasterById({
    required this.id,
    required this.observationCode,
    required this.description,
    this.observationRaisedBy,
    required this.observationType,
    this.observationTypeID,
    required this.issueType,
    required this.contractorName,
    required this.actionToBeTaken,
    required this.materialCost,
    required this.labourCost,
    required this.reworkCost,
    this.rootcauseDescription,
    this.rootCauseID,
    this.rootCauseName,
    this.corretiveActionToBeTaken,
    this.preventiveActionTaken,
    required this.statusName,
    required this.statusID,
    this.assignedUserID,
    required this.trancationDate,
    required this.createdDate,
    required this.dueDate,
    required this.activityName,
    required this.sectionName,
    required this.floorName,
    required this.partName,
    required this.elementName,
    this.complianceRequired = false,
    this.escalationRequired = false,
    required this.createdBy,
    required this.createdByName,
    required this.activityID,
    required this.sectionID,
    required this.floorID,
    required this.partID,
    required this.elementID,
    required this.contractorID,
    required this.projectID,
    required this.observedByName,
    this.violationTypeID,
    this.violationTypeName = '',
    required this.activityDTO,
    required this.assignmentStatusDTO,
    required this.closeRemarks,
    required this.reopenRemarks,
    required this.assignedUsersName,
    required this.observationNameWithCategory,
  });

  factory GetSiteObservationMasterById.fromJson(Map<String, dynamic> json) {
    // print('GetSiteObservationMasterById.fromJson: $json');
    return GetSiteObservationMasterById(
      id: json['id'] ?? 0,
      observationCode: json['siteObservationCode'] ?? '',
      description: json['observationDescription'] ?? '',
      observationRaisedBy: json['observationRaisedBy']?.toString(),
      observationType: json['observationType'] ?? '',
      observationTypeID: json['observationTypeID'] ?? 0,
      issueType: json['issueType'],
      contractorName: json['contractorName'],
      actionToBeTaken: json['actionToBeTaken'],
      materialCost: (json['materialCost'] ?? 0).toDouble(),
      labourCost: double.tryParse(json['labourCost']?.toString() ?? '0') ?? 0,
      reworkCost: (json['reworkCost'] ?? 0).toString(),
      rootcauseDescription: json['rootcauseDescription'],
      rootCauseID: json['rootCauseID'] as int?,
      rootCauseName: json['rootCauseName'],
      corretiveActionToBeTaken: json['corretiveActionToBeTaken'],
      preventiveActionTaken: json['preventiveActionTaken'],
      statusID: json['statusID'] ?? 0,
      statusName: json['statusName'] ?? '',
      assignedUserID: json['assignedUserID'],
      trancationDate: DateTime.parse(json['trancationDate']),
      createdDate: DateTime.parse(json['createdDate']),
      createdByName: json['createdByName']?.toString(),
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      activityName: json['activityName'] ?? '',
      sectionName: json['sectionName'] ?? '',
      floorName: json['floorName'] ?? '',
      partName: json['partName'] ?? '',
      elementName: json['elementName'] ?? '',
      complianceRequired: json['complianceRequired'] ?? false,
      escalationRequired: json['escalationRequired'] ?? false,
      createdBy: json['createdBy'] is int
          ? json['createdBy']
          : int.tryParse(json['createdBy']?.toString() ?? '0'),
      activityID: json['activityID'] as int?,
      sectionID: json['sectionID'] as int?,
      floorID: json['floorID'] as int?,
      partID: json['partID'] as int?,
      elementID: json['elementID'] as int?,
      contractorID: json['contractorID'] as int?,
      // projectID: json['projectID'] as int,
      projectID: json['projectID'] != null ? json['projectID'] as int : 0,
      observedByName: json["observedByName"],
      violationTypeID: json['violationTypeID'] as int?,
      violationTypeName: json['violationTypeName'] ?? '',
      activityDTO: (json['activityDTO'] as List<dynamic>?)
              ?.map((item) => ActivityDTO.fromJson(item))
              .toList() ??
          [],
      assignmentStatusDTO: (json['assignmentStatusDTO'] as List<dynamic>?)
              ?.map((e) => AssignmentStatusDTO.fromJson(e))
              .toList() ??
          [],
      closeRemarks: json['closeRemarks'] ?? '',
      reopenRemarks: json['reopenRemarks'] ?? '',
      assignedUsersName: json['assignedUsersName'] ?? '',
      observationNameWithCategory: json['observationNameWithCategory'] ?? '',
    );
  }

  @override
  String toString() {
    return '''
GetSiteObservationMasterById(
  id: $id,
  observationCode: $observationCode,
  description: $description,
  observationRaisedBy: $observationRaisedBy,
  observationType: $observationType,
  observationTypeID: $observationTypeID,
  issueType: $issueType,
  contractorName: $contractorName,
  actionToBeTaken: $actionToBeTaken,
  materialCost: $materialCost,
  labourCost: $labourCost,
  reworkCost: $reworkCost,
  rootCauseID: $rootCauseID,
  rootCauseName: $rootCauseName,
  corretiveActionToBeTaken: $corretiveActionToBeTaken,
  preventiveActionTaken: $preventiveActionTaken,
  statusName: $statusName,
  assignedUserID: $assignedUserID,
  trancationDate: $trancationDate,
  createdDate: $createdDate,
  dueDate: $dueDate,
  activityName: $activityName,
  sectionName: $sectionName,
  floorName: $floorName,
  partName: $partName,
  complianceRequired: $complianceRequired,
  escalationRequired: $escalationRequired,
  elementName: $elementName,
  createdBy: $createdBy,
  activityID: $activityID,
  projectID: $projectID,
  activityDTO: $activityDTO
  closeRemarks: $closeRemarks
  reopenRemarks: $reopenRemarks
)
''';
  }
}

class ActivityDTO {
  final int? id;
  final int? siteObservationID;
  final int? actionID;
  final String actionName;
  final String comments;
  final String documentName;
  final String? fileName;
  final String? fileContentType;
  final String? filePath;
  final int? fromStatusID;
  final String? fromStatusName;
  final int? toStatusID;
  final String? toStatusName;
  final int? assignedUserID;
  final String? assignedUserName;
  final int?
      createdBy; // changed from int to String because JSON sends string (like "Hardik")
  final String? createdByName;
  final DateTime createdDate;

  ActivityDTO({
    this.id,
    this.siteObservationID,
    this.actionID,
    required this.actionName,
    required this.comments,
    required this.documentName,
    this.fileName,
    this.fileContentType,
    this.filePath,
    this.fromStatusID,
    this.fromStatusName,
    this.toStatusID,
    this.toStatusName,
    this.assignedUserID,
    this.assignedUserName,
    this.createdBy,
    this.createdByName,
    required this.createdDate,
  });

  factory ActivityDTO.fromJson(Map<String, dynamic> json) {
    return ActivityDTO(
      id: json['id'] as int?,
      siteObservationID: json['siteObservationID'] as int?,
      actionID: json['actionID'] as int?,
      actionName: json['actionName'] ?? '',
      comments: json['comments'] ?? '',
      documentName: json['documentName'] ?? '',
      fileName: json['fileName'] as String?,
      fileContentType: json['fileContentType'] as String?,
      filePath: json['filePath'] as String?,
      fromStatusID: json['fromStatusID'] as int?,
      fromStatusName: json['fromStatusName'] as String?,
      toStatusID: json['toStatusID'] as int?,
      toStatusName: json['toStatusName'] as String?,
      assignedUserID: json['assignedUserID'] ?? 0,
      assignedUserName: json['assignedUserName'] as String?,
      createdBy: json['createdBy'] is int
          ? json['createdBy']
          : int.tryParse(json['createdBy']?.toString() ?? '0') ?? 0,
      createdByName: json['createdByName'] as String?,
      createdDate: DateTime.parse(json['createdDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'siteObservationID': siteObservationID,
      'actionID': actionID,
      'actionName': actionName,
      'comments': comments,
      'documentName': documentName,
      'fileName': fileName,
      'fileContentType': fileContentType,
      'filePath': filePath,
      'fromStatusID': fromStatusID,
      'fromStatusName': fromStatusName,
      'toStatusID': toStatusID,
      'toStatusName': toStatusName,
      'assignedUserID': assignedUserID,
      'assignedUserName': assignedUserName,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ActivityDTO(id: $id, actionName: $actionName, comments: $comments, documentName: $documentName, createdBy: $createdBy, createdDate: $createdDate)';
  }

  static String _getActionNameFromID(int? actionID) {
    switch (actionID) {
      case 1:
        return 'Created';
      case 2:
        return 'Assigned';
      case 3:
        return 'DocUploaded';
      default:
        return 'Unknown';
    }
  }

  factory ActivityDTO.fromSiteObservationActivity(
      SiteObservationActivity activity) {
    return ActivityDTO(
      id: activity.id,
      siteObservationID: activity.siteObservationID,
      actionID: activity.actionID,
      actionName: _getActionNameFromID(activity.actionID),
      comments: activity.comments,
      documentName: activity.documentName,
      fileName: activity.fileName,
      fileContentType: activity.fileContentType,
      filePath: activity.filePath,
      fromStatusID: activity.fromStatusID,
      fromStatusName: null,
      toStatusID: activity.toStatusID,
      toStatusName: null,
      assignedUserID: activity.assignedUserID,
      assignedUserName: activity.assignedUserName,
      createdBy: activity.createdBy,
      createdByName: activity.createdByName,
      createdDate:
          DateTime.parse(activity.createdDate), // assuming it's a String
    );
  }
}

class AssignmentStatusDTO {
  final int siteObservationID;
  final int assignedUserID;
  final String assignedUserName;
  final String statusName;
  final int statusID;

  AssignmentStatusDTO({
    required this.siteObservationID,
    required this.assignedUserID,
    required this.assignedUserName,
    required this.statusName,
    required this.statusID,
  });

  factory AssignmentStatusDTO.fromJson(Map<String, dynamic> json) {
    // print("json974:$json");
    return AssignmentStatusDTO(
      siteObservationID: json['siteObservationID'] ?? 0,
      assignedUserID: json['assignedUserID'] ?? 0,
      assignedUserName: json['assignedUserName'] ?? '',
      statusName: json['statusName'] ?? '',
      statusID: json['statusID'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siteObservationID': siteObservationID,
      'assignedUserID': assignedUserID,
      'assignedUserName': assignedUserName,
      'statusName': statusName,
      'statusID': statusID,
    };
  }
}

class UpdateSiteObservation {
  int id;
  int? rootCauseID; // ✅ Made nullable
  String? rootcauseDescription;
  String? corretiveActionToBeTaken; // ✅ Nullable if API allows
  String? preventiveActionTaken; // ✅ Nullable if API allows
  double materialCost;
  double labourCost;
  double reworkCost;
  int statusID;
  String? reopenRemarks;
  String? closeRemarks;
  String? inprogressRemarks;
  String? readytoinspectRemarks;
  int lastModifiedBy;
  DateTime lastModifiedDate;
  List<ActivityDTO> activityDTO;

  UpdateSiteObservation({
    required this.id,
    this.rootCauseID,
    this.rootcauseDescription,
    this.corretiveActionToBeTaken,
    this.preventiveActionTaken,
    required this.materialCost,
    required this.labourCost,
    required this.reworkCost,
    required this.statusID,
    required this.reopenRemarks,
    required this.closeRemarks,
    required this.inprogressRemarks,
    required this.readytoinspectRemarks,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
    required this.activityDTO,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rootCauseID': rootCauseID,
      'rootcauseDescription': rootcauseDescription,
      'corretiveActionToBeTaken': corretiveActionToBeTaken,
      'preventiveActionTaken': preventiveActionTaken,
      'materialCost': materialCost,
      'labourCost': labourCost,
      'reworkCost': reworkCost,
      'statusID': statusID,
      'reopenRemarks': reopenRemarks,
      'closeRemarks': closeRemarks,
      'inprogressRemarks': inprogressRemarks,
      'readytoinspectRemarks': readytoinspectRemarks,
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
      'activityDTO': activityDTO.map((a) => a.toJson()).toList(),
    };
  }
}

// class ActivityDTO {
//   int siteObservationID;
//   int actionID;
//   String comments;
//   String documentName;
//   int fromStatusID;
//   int toStatusID;
//   int assignedUserID;
//   int createdBy;
//   DateTime createdDate;

//   ActivityDTO({
//     required this.siteObservationID,
//     required this.actionID,
//     required this.comments,
//     required this.documentName,
//     required this.fromStatusID,
//     required this.toStatusID,
//     required this.assignedUserID,
//     required this.createdBy,
//     required this.createdDate,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'siteObservationID': siteObservationID,
//       'actionID': actionID,
//       'comments': comments,
//       'documentName': documentName,
//       'fromStatusID': fromStatusID,
//       'toStatusID': toStatusID,
//       'assignedUserID': assignedUserID,
//       'createdBy': createdBy,
//       'createdDate': createdDate.toIso8601String(),
//     };
//   }
// }

class UserList {
  final int id;
  final String userName;
  final String firstName;
  final String lastName;
  final String? email;
  final String? mobileNumber;

  UserList({
    required this.id,
    required this.userName,
    required this.firstName,
    required this.lastName,
    this.email,
    this.mobileNumber,
  });

  factory UserList.fromJson(Map<String, dynamic> json) {
    return UserList(
      id: json['ID'],
      userName: json['UserName'] ?? '',
      firstName: json['FirstName'] ?? '',
      lastName: json['LastName'] ?? '',
      email: json['EmailID'],
      mobileNumber: json['MobileNumber'],
    );
  }

  // ✅ Add this getter for full name
  String get fullName => "$firstName $lastName".trim();

  Map<String, dynamic> toMentionMap() {
    return {
      'id': id.toString(),
      'display': userName,
      'full_name': fullName,
    };
  }
}

class AssignedUser {
  final int siteObservationID;
  final int assignedUserID;
  final String? assignedUserName;
  final String? statusName;
  final int? statusID;

  AssignedUser({
    required this.siteObservationID,
    required this.assignedUserID,
    this.assignedUserName,
    this.statusName,
    this.statusID,
  });

  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(
      siteObservationID: json['siteObservationID'] ?? 0,
      assignedUserID: json['assignedUserID'] ?? 0,
      assignedUserName: json['assignedUserName']?.toString(),
      statusName: json['statusName']?.toString(),
      statusID: json['statusID'],
    );
  }

  @override
  String toString() {
    return 'AssignedUser(siteObservationID: $siteObservationID, assignedUserID: $assignedUserID, assignedUserName: $assignedUserName, statusName: $statusName, statusID: $statusID)';
  }
}

// labelname show
class SectionModel {
  final String labelName;

  SectionModel({required this.labelName});

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    // print(json);
    return SectionModel(
      labelName: json['labelName'] ?? '',
    );
  }
}

class FloorModel {
  final String floorName;

  FloorModel({required this.floorName});

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    // print('Parsing Floor JSON: $json');
    return FloorModel(
      floorName: json['floorName'] ?? '',
    );
  }
}

class PourModel {
  final String partName;
  final String labelName;

  PourModel({required this.partName, required this.labelName});

  factory PourModel.fromJson(Map<String, dynamic> json) {
    return PourModel(
      partName: json['partName'] ?? '',
      labelName: json['labelName'] ?? '',
    );
  }
}

class ElementModel {
  final String labelName;

  ElementModel({required this.labelName});

  factory ElementModel.fromJson(Map<String, dynamic> json) {
    // print('Parsing Element JSON: $json');
    return ElementModel(
      labelName: json['labelName'] ?? '',
    );
  }
}

class NotificationModel {
  final int id;
  final String userName;
  final String notificationDescription;
  final String programName;
  final String programRowCode;
  final bool isMobileRead;
  final bool isWebRead;
  final String createdByName;
  final String createdDate;
  final int actionID;

  NotificationModel({
    required this.id,
    required this.userName,
    required this.notificationDescription,
    required this.programName,
    required this.programRowCode,
    required this.isMobileRead,
    required this.isWebRead,
    required this.createdByName,
    required this.createdDate,
    required this.actionID,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userName: json['userName'],
      notificationDescription: json['notificationDescription'],
      programName: json['programName'],
      programRowCode: json['programRowCode'],
      isMobileRead: json['isMobileRead'],
      isWebRead: json['isWebRead'],
      createdByName: json['createdByName'],
      createdDate: json['createdDate'],
      actionID: json['actionID'],
    );
  }
}
