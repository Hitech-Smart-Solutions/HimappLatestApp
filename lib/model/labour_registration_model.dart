class LabourModel {
  final int id;
  final String fullName;
  final String contactNo;
  final String labourRegistrationCode;

  LabourModel({
    required this.id,
    required this.fullName,
    required this.contactNo,
    required this.labourRegistrationCode,
  });

  factory LabourModel.fromJson(Map<String, dynamic> json) {
    return LabourModel(
      id: json['id'],
      fullName: json['fullName'],
      contactNo: json['contactNo'],
      labourRegistrationCode: json['labourRegistrationCode'],
    );
  }
}

class PartyModel {
  final int id;
  final String partyName;

  PartyModel({required this.id, required this.partyName});

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    return PartyModel(
      id: json['id'],
      partyName: json['partyName'],
    );
  }
}

class LabourTypeModel {
  final int id;
  final String labourCategoryFullName;

  LabourTypeModel({
    required this.id,
    required this.labourCategoryFullName,
  });

  factory LabourTypeModel.fromJson(Map<String, dynamic> json) {
    return LabourTypeModel(
      id: json['id'],
      labourCategoryFullName: json['labourCategoryFullName'],
    );
  }
}

class CountriesModel {
  final int id;
  final String name;

  CountriesModel({required this.id, required this.name});

  factory CountriesModel.fromJson(Map<String, dynamic> json) {
    return CountriesModel(id: json['id'], name: json['name']);
  }
}

class StateModel {
  final int id;
  final String name;

  StateModel({required this.id, required this.name});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'],
      name: json['name'],
    );
  }
}

class CityModel {
  final int id;
  final String name;

  CityModel({required this.id, required this.name});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'],
      name: json['name'],
    );
  }
}
