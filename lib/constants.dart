class ScreenTypes {
  static const int All = 11;
  static const int Quality = 12;
  static const int Safety = 13;
}

class AppSettings {
  static const String url =
      'https://s3.ap-south-1.amazonaws.com/documents.himapp.test'; //Production
  static const Map<String, int> DEVICEID = {
    'Web': 1,
    'Mobile': 2,
  };
}

// class DEVICEID {
//   static const int Web = 1;
//   static const int Mobile = 2;
// }

class SiteObservationActions {
  static const int Created = 1;
  static const int Assigned = 2;
  static const int DocUploaded = 3; // ✅ Ye confirm hona chahiye
  static const int Commented = 4;
  static const int Closed = 5;
  static const int ReOpened = 6;
}

class SiteObservationStatus {
  static const int Open = 1;
  static const int InProgress = 2;
  static const int ReadyToInspect = 3;
  static const int Closed = 4;
  static const int Reopen = 5;
  static const int WaitingFromThirdParty = 6;
  static const int Draft = 7;

  static const Map<String, int> nameToId = {
    "Open": Open,
    "In Progress": InProgress,
    "Ready To Inspect": ReadyToInspect,
    "Closed": Closed,
    "Reopen": Reopen,
    "Waiting From Third Party": WaitingFromThirdParty,
    "Draft": Draft,
  };

  static const Map<int, String> idToName = {
    Open: "Open",
    InProgress: "In Progress",
    ReadyToInspect: "Ready To Inspect",
    Closed: "Closed",
    Reopen: "Reopen",
    WaitingFromThirdParty: "Waiting From Third Party",
    Draft: "Draft",
  };
}

class ObservationConstants {
  static const List<Map<String, Object>> observedBy = [
    {
      "id": 1,
      "observedBy": "Internal",
    },
    {
      "id": 2,
      "observedBy": "Client",
    },
  ];
}

class ObservationViolationTypeConstants {
  static const List<Map<String, Object>> violationType = [
    {
      "id": 1,
      "violationType": "Unsafe Condition",
    },
    {
      "id": 2,
      "violationType": "Unsafe Act",
    },
  ];
}

//  class SiteObservationActions {
//    static const int Created = 1;
//    static const int Assigned = 2;
//    static const int DocUploaded = 3;
//    static const int Commented = 4;
//   }

//  static readonly ScreenTypes = {
//     "All": 11,
//     'Quality': 12,
//     'Safety': 13
//   };
// class violationType {
//   static const int violationTypeID = 11;
//   static const int Quality = 12;
//   static const int Safety = 13;
// }

class ViolationTypes {
  static const List<Map<String, Object>> violationType = [
    {
      "id": 1,
      "violationTypeID": "UnsafeCondition",
    },
    {
      "id": 2,
      "violationTypeID": "UnsafeAct",
    },
  ];
}
