class QualityChecklist {
  final int id;
  final String checklistCode;
  final String checklistFor;
  final String frequency;
  final String createdBy;
  final String status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool isActive;

  QualityChecklist({
    required this.id,
    required this.checklistCode,
    required this.checklistFor,
    required this.frequency,
    required this.createdBy,
    required this.status,
    this.fromDate,
    this.toDate,
    required this.isActive,
  });

  factory QualityChecklist.fromJson(Map<String, dynamic> json) {
    return QualityChecklist(
      id: json['ID'],
      checklistCode: json['CheckListCode'] ?? '',
      checklistFor: json['ChecklistFor'] ?? '',
      frequency: json['Frequency'] ?? '',
      createdBy: json['CreatedBy'] ?? '',
      status: json['Status'] ?? '',
      fromDate:
          json['FromDate'] != null ? DateTime.parse(json['FromDate']) : null,
      toDate: json['ToDate'] != null ? DateTime.parse(json['ToDate']) : null,
      isActive: json['IsActive'] ?? false,
    );
  }
}

class ChecklistMapping {
  final int id;
  final String checklistFor;
  final String mappingCode;
  final String pointType;
  final bool isVisible;

  ChecklistMapping({
    required this.id,
    required this.checklistFor,
    required this.mappingCode,
    required this.pointType,
    required this.isVisible,
  });

  factory ChecklistMapping.fromJson(Map<String, dynamic> json) {
    return ChecklistMapping(
      id: json['ID'],
      checklistFor: json['ChecklistFor'] ?? '',
      mappingCode: json['MappingCode'] ?? '',
      pointType: json['PointType'] ?? '',
      isVisible: json['isvisible'] ?? false,
    );
  }
}

class FrequencyOption {
  final String label;
  final int value;

  FrequencyOption({required this.label, required this.value});
}

class AreaModel {
  final int id;
  final String sectionName;

  AreaModel({required this.id, required this.sectionName});

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'],
      sectionName: json['sectionName'] ?? '',
    );
  }
}

class ElementModel {
  final int id;
  final String elementName;

  ElementModel({required this.id, required this.elementName});

  factory ElementModel.fromJson(Map<String, dynamic> json) {
    return ElementModel(
      id: json['id'],
      elementName: json['elementName'] ?? '',
    );
  }
}

class FloorModel {
  final int id;
  final String floorName;

  FloorModel({required this.id, required this.floorName});

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'],
      floorName: json['floorName'] ?? '',
    );
  }
}

class PartModel {
  final int id;
  final String partName;

  PartModel({required this.id, required this.partName});

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      id: json['id'],
      partName: json['partName'] ?? '',
    );
  }
}

class SectionMaster {
  int id;
  String name;

  SectionMaster({required this.id, required this.name});
}
