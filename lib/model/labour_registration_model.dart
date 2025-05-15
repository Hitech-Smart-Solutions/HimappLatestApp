// class LabourModel {
//   final int id;
//   final String fullName;
//   final String contactNo;
//   final String labourRegistrationCode;

//   LabourModel({
//     required this.id,
//     required this.fullName,
//     required this.contactNo,
//     required this.labourRegistrationCode,
//   });

//   factory LabourModel.fromJson(Map<String, dynamic> json) {
//     return LabourModel(
//       id: json['id'],
//       fullName: json['fullName'],
//       contactNo: json['contactNo'],
//       labourRegistrationCode: json['labourRegistrationCode'],
//     );
//   }
// }

class LabourModel {
  final int id;
  final String code;
  final DateTime date;
  final String fullName;
  final String contactNo;
  final bool isActive;
  final int partyId;
  final int tradeId;

  LabourModel({
    required this.id,
    required this.code,
    required this.date,
    required this.fullName,
    required this.contactNo,
    required this.isActive,
    required this.partyId,
    required this.tradeId,
  });

  factory LabourModel.fromJson(Map<String, dynamic> json) {
    return LabourModel(
      id: json['ID'],
      code: json['LabourRegistrationCode'],
      date: DateTime.parse(json['LabourRegistrationDate']),
      fullName: json['FullName'],
      contactNo: json['ContactNo'],
      isActive: json['IsActive'],
      partyId: json['PartyID'],
      tradeId: json['TradeID'],
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

class LabourRegistration {
  String? uniqueId;
  int? id;
  DateTime? labourRegistrationDate;
  String? labourRegistrationCode;
  int? partyId;
  String? partyContactNo;
  String? fullName;
  DateTime? birthDate;
  int? genderId;
  String? contactNo;
  int? tradeId;
  int? projectId;
  String? uanNo;
  String? aadharNo;
  String? panNo;
  String? voterIDNo;
  String? bankAccNo;
  String? profileImagePath;
  String? profileFileName;
  int? statusId;
  bool? isActive;
  int? createdBy;
  DateTime? createdDate;
  int? lastModifiedBy;
  DateTime? lastModifiedDate;
  DateTime? labourArrivalDate;
  String? idMark;
  String? bloodGroup;
  int? maritalStatusId;
  String? address;
  int? cityId;
  int? stateId;
  int? countryId;
  DateTime? firstVaccineDate;
  String? firstVaccineReferenceID;
  DateTime? secorndVaccineDate;
  String? secorndVaccineReferenceID;
  List<LabourRegistrationDocumentDetail>? labourRegistrationDocumentDetails;

  LabourRegistration({
    this.uniqueId,
    this.id,
    this.labourRegistrationDate,
    this.labourRegistrationCode,
    this.partyId,
    this.partyContactNo,
    this.fullName,
    this.birthDate,
    this.genderId,
    this.contactNo,
    this.tradeId,
    this.projectId,
    this.uanNo,
    this.aadharNo,
    this.panNo,
    this.voterIDNo,
    this.bankAccNo,
    this.profileImagePath,
    this.profileFileName,
    this.statusId,
    this.isActive,
    this.createdBy,
    this.createdDate,
    this.lastModifiedBy,
    this.lastModifiedDate,
    this.labourArrivalDate,
    this.idMark,
    this.bloodGroup,
    this.maritalStatusId,
    this.address,
    this.cityId,
    this.stateId,
    this.countryId,
    this.firstVaccineDate,
    this.firstVaccineReferenceID,
    this.secorndVaccineDate,
    this.secorndVaccineReferenceID,
    this.labourRegistrationDocumentDetails,
  });

  factory LabourRegistration.fromJson(Map<String, dynamic> json) {
    return LabourRegistration(
      uniqueId: json['uniqueId'],
      id: json['id'],
      labourRegistrationDate: DateTime.tryParse(json['labourRegistrationDate']),
      labourRegistrationCode: json['labourRegistrationCode'],
      partyId: json['partyId'],
      partyContactNo: json['partyContactNo'],
      fullName: json['fullName'],
      birthDate: DateTime.tryParse(json['birthDate']),
      genderId: json['genderId'],
      contactNo: json['contactNo'],
      tradeId: json['tradeId'],
      projectId: json['projectId'],
      uanNo: json['uanNo'],
      aadharNo: json['aadharNo'],
      panNo: json['panNo'],
      voterIDNo: json['voterIDNo'],
      bankAccNo: json['bankAccNo'],
      profileImagePath: json['profileImagePath'],
      profileFileName: json['profileFileName'],
      statusId: json['statusId'],
      isActive: json['isActive'],
      createdBy: json['createdBy'],
      createdDate: DateTime.tryParse(json['createdDate']),
      lastModifiedBy: json['lastModifiedBy'],
      lastModifiedDate: DateTime.tryParse(json['lastModifiedDate']),
      labourArrivalDate: DateTime.tryParse(json['labourArrivalDate']),
      idMark: json['idMark'],
      bloodGroup: json['bloodGroup'],
      maritalStatusId: json['maritalStatusId'],
      address: json['address'],
      cityId: json['cityId'],
      stateId: json['stateId'],
      countryId: json['countryId'],
      firstVaccineDate: DateTime.tryParse(json['firstVaccineDate']),
      firstVaccineReferenceID: json['firstVaccineReferenceID'],
      secorndVaccineDate: DateTime.tryParse(json['secorndVaccineDate']),
      secorndVaccineReferenceID: json['secorndVaccineReferenceID'],
      labourRegistrationDocumentDetails:
          (json['labourRegistrationDocumentDetails'] as List?)
              ?.map((e) => LabourRegistrationDocumentDetail.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uniqueId': uniqueId,
      'id': id,
      'labourRegistrationDate': labourRegistrationDate?.toIso8601String(),
      'labourRegistrationCode': labourRegistrationCode,
      'partyId': partyId,
      'partyContactNo': partyContactNo,
      'fullName': fullName,
      'birthDate': birthDate?.toIso8601String(),
      'genderId': genderId,
      'contactNo': contactNo,
      'tradeId': tradeId,
      'projectId': projectId,
      'uanNo': uanNo,
      'aadharNo': aadharNo,
      'panNo': panNo,
      'voterIDNo': voterIDNo,
      'bankAccNo': bankAccNo,
      'profileImagePath': profileImagePath,
      'profileFileName': profileFileName,
      'statusId': statusId,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdDate': createdDate?.toIso8601String(),
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedDate': lastModifiedDate?.toIso8601String(),
      'labourArrivalDate': labourArrivalDate?.toIso8601String(),
      'idMark': idMark,
      'bloodGroup': bloodGroup,
      'maritalStatusId': maritalStatusId,
      'address': address,
      'cityId': cityId,
      'stateId': stateId,
      'countryId': countryId,
      'firstVaccineDate': firstVaccineDate?.toIso8601String(),
      'firstVaccineReferenceID': firstVaccineReferenceID,
      'secorndVaccineDate': secorndVaccineDate?.toIso8601String(),
      'secorndVaccineReferenceID': secorndVaccineReferenceID,
      'labourRegistrationDocumentDetails':
          labourRegistrationDocumentDetails?.map((e) => e.toJson()).toList(),
    };
  }
}

class LabourRegistrationDocumentDetail {
  String? uniqueId;
  int? id;
  int? labourRegistrationId;
  String? documentName;
  String? fileName;
  String? fileContentType;
  String? filePath;
  bool? isActive;
  int? createdBy;
  DateTime? createdDate;
  int? lastModifiedBy;
  DateTime? lastModifiedDate;
  int? documentTypeId; // Added documentTypeId
  String? documentPath; // Added documentPath
  String? documentFileName; // Added documentFileName

  LabourRegistrationDocumentDetail({
    this.uniqueId,
    this.id,
    this.labourRegistrationId,
    this.documentName,
    this.fileName,
    this.fileContentType,
    this.filePath,
    this.isActive,
    this.createdBy,
    this.createdDate,
    this.lastModifiedBy,
    this.lastModifiedDate,
    this.documentTypeId, // Added documentTypeId
    this.documentPath, // Added documentPath
    this.documentFileName, // Added documentFileName
  });

  factory LabourRegistrationDocumentDetail.fromJson(Map<String, dynamic> json) {
    return LabourRegistrationDocumentDetail(
      uniqueId: json['uniqueId'],
      id: json['id'],
      labourRegistrationId: json['labourRegistrationId'],
      documentName: json['documentName'],
      fileName: json['fileName'],
      fileContentType: json['fileContentType'],
      filePath: json['filePath'],
      isActive: json['isActive'],
      createdBy: json['createdBy'],
      createdDate: DateTime.tryParse(json['createdDate']),
      lastModifiedBy: json['lastModifiedBy'],
      lastModifiedDate: DateTime.tryParse(json['lastModifiedDate']),
      documentTypeId: json['documentTypeId'], // Added documentTypeId
      documentPath: json['documentPath'], // Added documentPath
      documentFileName: json['documentFileName'], // Added documentFileName
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uniqueId': uniqueId,
      'id': id,
      'labourRegistrationId': labourRegistrationId,
      'documentName': documentName,
      'fileName': fileName,
      'fileContentType': fileContentType,
      'filePath': filePath,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdDate': createdDate?.toIso8601String(),
      'lastModifiedBy': lastModifiedBy,
      'lastModifiedDate': lastModifiedDate?.toIso8601String(),
      'documentTypeId': documentTypeId, // Added documentTypeId
      'documentPath': documentPath, // Added documentPath
      'documentFileName': documentFileName, // Added documentFileName
    };
  }
}
