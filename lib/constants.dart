class ScreenTypes {
  static const int All = 11;
  static const int Quality = 12;
  static const int Safety = 13;
}

class AppSettings {
  static const String url =
      'https://s3.ap-south-1.amazonaws.com/documents.himapp.test';
}

class SiteObservationActions {
  static const int Created = 1;
  static const int Assigned = 2;
  static const int DocUploaded = 3;
  static const int Commented = 4;
}

class SiteObservationStatus {
  static const int Open = 1;
  static const int InProgress = 2;
  static const int ReadyToInspect = 3;
  static const int Closed = 4;
  static const int Reopen = 5;
  static const int WaitingFromThirdParty = 6;

  static const Map<String, int> nameToId = {
    "Open": Open,
    "In Progress": InProgress,
    "Ready To Inspect": ReadyToInspect,
    "Closed": Closed,
    "Reopen": Reopen,
    "Waiting From Third Party": WaitingFromThirdParty,
  };

  static const Map<int, String> idToName = {
    Open: "Open",
    InProgress: "In Progress",
    ReadyToInspect: "Ready To Inspect",
    Closed: "Closed",
    Reopen: "Reopen",
    WaitingFromThirdParty: "Waiting From Third Party",
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
