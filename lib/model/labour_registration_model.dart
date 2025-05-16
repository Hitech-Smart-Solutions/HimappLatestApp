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
  DateTime? secondVaccineDate;
  String? secondVaccineReferenceID;
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
    this.secondVaccineDate,
    this.secondVaccineReferenceID,
    this.labourRegistrationDocumentDetails,
  });

  factory LabourRegistration.fromJson(Map<String, dynamic> json) {
    return LabourRegistration(
      uniqueId: json['uniqueId'] ?? '', // Default to empty string if null
      id: json['id'] ?? 0, // Default to 0 if null
      labourRegistrationDate: json['labourRegistrationDate'] != null
          ? DateTime.tryParse(json['labourRegistrationDate'])
          : null, // Handle invalid or null date gracefully
      labourRegistrationCode:
          json['labourRegistrationCode'] ?? 'N/A', // Default if null
      partyId: json['partyId'] ?? 0, // Default to 0 if null
      partyContactNo: json['partyContactNo'] ??
          'No Contact', // Default to 'No Contact' if null
      fullName: json['fullName'] ?? 'No Name', // Default to 'No Name' if null
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'])
          : null, // Handle null date gracefully
      genderId: json['genderId'] ?? 0, // Default to 0 if null
      contactNo:
          json['contactNo'] ?? 'No Contact', // Default to 'No Contact' if null
      tradeId: json['tradeId'] ?? 0, // Default to 0 if null
      projectId: json['projectId'] ?? 0, // Default to 0 if null
      uanNo: json['uanNo'] ?? 'N/A', // Default to 'N/A' if null
      aadharNo: json['aadharNo'] ?? 'N/A', // Default to 'N/A' if null
      panNo: json['panNo'] ?? 'N/A', // Default to 'N/A' if null
      voterIDNo: json['voterIDNo'] ?? 'N/A', // Default to 'N/A' if null
      bankAccNo: json['bankAccNo'] ?? 'N/A', // Default to 'N/A' if null
      profileImagePath:
          json['profileImagePath'] ?? '', // Default to empty string if null
      profileFileName:
          json['profileFileName'] ?? '', // Default to empty string if null
      statusId: json['statusId'] ?? 0, // Default to 0 if null
      isActive: json['isActive'] ?? false, // Default to false if null
      createdBy: json['createdBy'] ?? 0, // Default to 0 if null
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'])
          : null, // Handle null date gracefully
      lastModifiedBy: json['lastModifiedBy'] ?? 0, // Default to 0 if null
      lastModifiedDate: json['lastModifiedDate'] != null
          ? DateTime.tryParse(json['lastModifiedDate'])
          : null, // Handle null date gracefully
      labourArrivalDate: json['labourArrivalDate'] != null
          ? DateTime.tryParse(json['labourArrivalDate'])
          : null, // Handle null date gracefully
      idMark: json['idMark'] ?? 'No ID Mark', // Default to 'No ID Mark' if null
      bloodGroup: json['bloodGroup'] ?? 'N/A', // Default to 'N/A' if null
      maritalStatusId: json['maritalStatusId'] ?? 0, // Default to 0 if null
      address:
          json['address'] ?? 'No Address', // Default to 'No Address' if null
      cityId: json['cityId'] ?? 0, // Default to 0 if null
      stateId: json['stateId'] ?? 0, // Default to 0 if null
      countryId: json['countryId'] ?? 0, // Default to 0 if null
      firstVaccineDate: json['firstVaccineDate'] != null
          ? DateTime.tryParse(json['firstVaccineDate'])
          : null, // Handle null date gracefully
      firstVaccineReferenceID:
          json['firstVaccineReferenceID'] ?? 'N/A', // Default to 'N/A' if null
      secondVaccineDate: json['secondVaccineDate'] != null
          ? DateTime.tryParse(json['secondVaccineDate'])
          : null, // Handle null date gracefully
      secondVaccineReferenceID: json['secorndVaccineReferenceID'] ??
          'N/A', // Default to 'N/A' if null
      labourRegistrationDocumentDetails:
          (json['labourRegistrationDocumentDetails'] as List?)
                  ?.map((e) => LabourRegistrationDocumentDetail.fromJson(e))
                  .toList() ??
              [], // Default to empty list if null
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
      'secondVaccineDate': secondVaccineDate?.toIso8601String(),
      'secondVaccineReferenceID': secondVaccineReferenceID,
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
      uniqueId: json['uniqueId'] ?? '', // Default to empty string if null
      id: json['id'] ?? 0, // Default to 0 if null
      labourRegistrationId:
          json['labourRegistrationId'] ?? 0, // Default to 0 if null
      documentName: json['documentName'] ??
          'No Document', // Default to 'No Document' if null
      fileName: json['fileName'] ?? 'No File', // Default to 'No File' if null
      fileContentType:
          json['fileContentType'] ?? 'Unknown', // Default to 'Unknown' if null
      filePath: json['filePath'] ?? '', // Default to empty string if null
      isActive: json['isActive'] ?? false, // Default to false if null
      createdBy: json['createdBy'] ?? 0, // Default to 0 if null
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'])
          : null, // Handle null or invalid date gracefully
      lastModifiedBy: json['lastModifiedBy'] ?? 0, // Default to 0 if null
      lastModifiedDate: json['lastModifiedDate'] != null
          ? DateTime.tryParse(json['lastModifiedDate'])
          : null, // Handle null or invalid date gracefully
      documentTypeId: json['documentTypeId'] ?? 0, // Default to 0 if null
      documentPath:
          json['documentPath'] ?? '', // Default to empty string if null
      documentFileName:
          json['documentFileName'] ?? '', // Default to empty string if null
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
