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
