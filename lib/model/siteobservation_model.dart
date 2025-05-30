class SiteObservation {
  final int id;
  final String siteObservationCode;
  final String observationDescription;
  final String observationType;
  final String issueType;
  final String functionType;
  final String observationStatus;
  final String projectName;
  final DateTime transactionDate;

  SiteObservation({
    required this.id,
    required this.siteObservationCode,
    required this.observationDescription,
    required this.observationType,
    required this.issueType,
    required this.functionType,
    required this.observationStatus,
    required this.projectName,
    required this.transactionDate,
  });

  factory SiteObservation.fromJson(Map<String, dynamic> json) {
    return SiteObservation(
      id: json['ID'],
      siteObservationCode: json['SiteObservationCode'] ?? 'N/A',
      observationDescription: json['ObservationDescription'] ?? 'N/A',
      observationType: json['ObservationType'] ?? 'N/A',
      issueType: json['IssueType'] ?? 'N/A',
      functionType: json['FunctionType'] ?? 'N/A',
      observationStatus: json['ObservationStatus'] ?? 'N/A',
      projectName: json['ProjectName'] ?? 'N/A',
      transactionDate: DateTime.parse(json['TrancationDate']),
    );
  }
}

class IssueType {
  String uniqueID;
  int id;
  String name;
  int statusID;
  bool isActive;

  IssueType({
    required this.uniqueID,
    required this.id,
    required this.name,
    required this.statusID,
    required this.isActive,
  });

  factory IssueType.fromJson(Map<String, dynamic> json) {
    return IssueType(
      uniqueID: json['uniqueID'],
      id: json['id'],
      name: json['name'],
      statusID: json['statusID'],
      isActive: json['isActive'],
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
    required this.complianceRequired,
    required this.escalationRequired,
    required this.dueTimeInHrs,
    required this.actionToBeTaken,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
  });

  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      id: json['id'],
      observationTypeID: json['observationTypeID'],
      issueTypeID: json['issueTypeID'],
      observationDescription: json['observationDescription'],
      complianceRequired: json['complianceRequired'],
      escalationRequired: json['escalationRequired'],
      dueTimeInHrs: json['dueTimeInHrs'],
      actionToBeTaken: json['actionToBeTaken'],
      lastModifiedBy: json['lastModifiedBy'].toString(),
      lastModifiedDate: json['lastModifiedDate'],
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
  String uniqueId;
  int id;
  String userName;
  String password;
  String firstName;
  String lastName;
  String mobileNumber;
  String emailId;
  int userTypeId;
  int reportingUserId;
  String? webTokenID;
  String? mobileAppTokenID;
  int statusId;
  bool isActive;
  int createdBy;
  DateTime createdDate;
  int lastModifiedBy;
  DateTime lastModifiedDate;

  // Constructor
  User({
    required this.uniqueId,
    required this.id,
    required this.userName,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.emailId,
    required this.userTypeId,
    required this.reportingUserId,
    this.webTokenID,
    this.mobileAppTokenID,
    required this.statusId,
    required this.isActive,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
  });

  // Convert a JSON object to a User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uniqueId: json['uniqueId'],
      id: json['id'],
      userName: json['userName'],
      password: json['password'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      mobileNumber: json['mobileNumber'],
      emailId: json['emailId'],
      userTypeId: json['userTypeId'],
      reportingUserId: json['reportingUserId'],
      webTokenID: json['webTokenID'], // Can be null
      mobileAppTokenID: json['mobileAppTokenID'], // Can be null
      statusId: json['statusId'],
      isActive: json['isActive'],
      createdBy: json['createdBy'],
      createdDate: DateTime.parse(json['createdDate']),
      lastModifiedBy: json['lastModifiedBy'],
      lastModifiedDate: DateTime.parse(json['lastModifiedDate']),
    );
  }

  // Convert a User object to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'uniqueId': uniqueId,
      'id': id,
      'userName': userName,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'emailId': emailId,
      'userTypeId': userTypeId,
      'reportingUserId': reportingUserId,
      'webTokenID': webTokenID,
      'mobileAppTokenID': mobileAppTokenID,
      'statusId': statusId,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdDate': createdDate.toIso8601String(),
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
    };
  }
}

// site_observation_model.dart
class SiteObservationModel {
  final String uniqueID;
  final int id;
  final String siteObservationCode;
  final String trancationDate;
  final int observationRaisedBy;
  final int observationTypeID;
  final int issueTypeID;
  final String dueDate;
  final String observationDescription;
  final String userDescription;
  final bool complianceRequired;
  final bool escalationRequired;
  final String actionToBeTaken;
  final int companyID;
  final int projectID;
  final int functionID;
  final int activityID;
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
    required this.observationTypeID,
    required this.issueTypeID,
    required this.dueDate,
    required this.observationDescription,
    required this.userDescription,
    required this.complianceRequired,
    required this.escalationRequired,
    required this.actionToBeTaken,
    required this.companyID,
    required this.projectID,
    required this.functionID,
    required this.activityID,
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
      'statusID': statusID,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdDate': createdDate,
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedDate': lastModifiedDate,
      'siteObservationActivity':
          siteObservationActivity.map((e) => e.toJson()).toList(),
    };
  }
}

class SiteObservationActivity {
  final int id;
  final int? siteObservationID;
  final int actionID;
  final String comments;
  final String documentName;
  final int fromStatusID;
  final int toStatusID;
  final int assignedUserID;
  final int createdBy;
  final String createdDate;

  SiteObservationActivity({
    required this.id,
    required this.siteObservationID,
    required this.actionID,
    required this.comments,
    required this.documentName,
    required this.fromStatusID,
    required this.toStatusID,
    required this.assignedUserID,
    required this.createdBy,
    required this.createdDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (siteObservationID != null)
        'siteObservationID':
            siteObservationID, // 👈 Yeh line conditionally add karo
      'actionID': actionID,
      'comments': comments,
      'documentName': documentName,
      'fromStatusID': fromStatusID,
      'toStatusID': toStatusID,
      'assignedUserID': assignedUserID,
      'createdBy': createdBy,
      'createdDate': createdDate,
    };
  }
}

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
  });

  factory NCRObservation.fromJson(Map<String, dynamic> json) {
    return NCRObservation(
      uniqueID: json['uniqueID'] ?? '',
      id: json['id'] ?? 0,
      trancationDate: DateTime.parse(json['trancationDate']),
      siteObservationCode: json['siteObservationCode'] ?? '',
      observationRaisedBy: json['observationRaisedBy'] ?? '',
      observationType: json['observationType'] ?? '',
      issueType: json['issueType'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      observationDescription: json['observationDescription'],
      complianceRequired: json['complianceRequired'] ?? false,
      escalationRequired: json['escalationRequired'] ?? false,
      actionToBeTaken: json['actionToBeTaken'] ?? '',
      contractorName: json['contractorName'] ?? '',
      statusName: json['statusName'] ?? '',
      assignedUserName: json['assignedUserName'] ?? '',
    );
  }
}

class GetSiteObservationMasterById {
  // Existing fields
  final String observationCode;
  final String description;
  final String observationRaisedBy;
  // Add the activityDTO field:
  final List<ActivityDTO> activityDTO;

  GetSiteObservationMasterById({
    required this.observationCode,
    required this.description,
    required this.observationRaisedBy,
    required this.activityDTO,
  });

  factory GetSiteObservationMasterById.fromJson(Map<String, dynamic> json) {
    return GetSiteObservationMasterById(
      observationCode: json['siteObservationCode'] ?? '',
      description: json['observationDescription'] ?? '',
      observationRaisedBy: json['observationRaisedBy'] ?? '',
      activityDTO: (json['activityDTO'] as List<dynamic>?)
              ?.map((item) => ActivityDTO.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ActivityDTO {
  final int id;
  final int siteObservationID;
  final String actionName;
  final String comments;
  final String documentName;
  final String fromStatusName;
  final String toStatusName;
  final String? assignedUserName;
  final String createdBy;
  final DateTime createdDate;

  ActivityDTO({
    required this.id,
    required this.siteObservationID,
    required this.actionName,
    required this.comments,
    required this.documentName,
    required this.fromStatusName,
    required this.toStatusName,
    this.assignedUserName,
    required this.createdBy,
    required this.createdDate,
  });

  factory ActivityDTO.fromJson(Map<String, dynamic> json) {
    return ActivityDTO(
      id: json['id'],
      siteObservationID: json['siteObservationID'],
      actionName: json['actionName'] ?? '',
      comments: json['comments'] ?? '',
      documentName: json['documentName'] ?? '',
      fromStatusName: json['fromStatusName'] ?? '',
      toStatusName: json['toStatusName'] ?? '',
      assignedUserName: json['assignedUserName'],
      createdBy: json['createdBy'] ?? '',
      createdDate: DateTime.parse(json['createdDate']),
    );
  }
}
