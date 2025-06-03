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
  static const int Completed = 4;
  static const int Reopen = 5;
  static const int WaitingFromThirdParty = 6;
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
