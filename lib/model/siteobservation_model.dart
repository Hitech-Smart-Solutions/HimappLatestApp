class SiteObservation {
  final String siteObservationCode;
  final String observationDescription;
  final String actionToBeTaken;

  SiteObservation({
    required this.siteObservationCode,
    required this.observationDescription,
    required this.actionToBeTaken,
  });

  factory SiteObservation.fromJson(Map<String, dynamic> json) {
    return SiteObservation(
      siteObservationCode: json['siteObservationCode'] ?? 'No Code',
      observationDescription:
          json['observationDescription'] ?? 'No Description',
      actionToBeTaken: json['actionToBeTaken'] ?? 'No Action',
    );
  }

  @override
  String toString() {
    return 'SiteObservation(code: $siteObservationCode, desc: $observationDescription, action: $actionToBeTaken)';
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
