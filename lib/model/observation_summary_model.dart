class Project {
  final int id;
  final String projectName;

  Project({
    required this.id,
    required this.projectName,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      projectName: json['projectName'],
    );
  }
}

class ObservationSummary {
  final String stage;
  final int dueCount;
  final int overdueCount;
  final int totalCount;

  ObservationSummary({
    required this.stage,
    required this.dueCount,
    required this.overdueCount,
    required this.totalCount,
  });

  factory ObservationSummary.fromJson(Map<String, dynamic> json) {
    return ObservationSummary(
      stage: json['stage'] ?? '',
      dueCount: json['due_count'] ?? 0,
      overdueCount: json['overdue_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
    );
  }
}

class ObservationTableRow {
  final String stage;
  final int overdue;
  final int due;
  final int total;

  ObservationTableRow({
    required this.stage,
    required this.overdue,
    required this.due,
    required this.total,
  });
}

class ObservationTrend {
  final String stage;
  final int totalCount;
  final int dueCount;
  final int overdueCount;

  ObservationTrend({
    required this.stage,
    required this.totalCount,
    required this.dueCount,
    required this.overdueCount,
  });

  factory ObservationTrend.fromJson(Map<String, dynamic> json) {
    return ObservationTrend(
      stage: json['stage'] ?? '',
      totalCount: (json['totalCount'] ?? 0) is String
          ? int.parse(json['totalCount'])
          : json['totalCount'] ?? 0,
      dueCount: (json['dueCount'] ?? 0) is String
          ? int.parse(json['dueCount'])
          : json['dueCount'] ?? 0,
      overdueCount: (json['overdueCount'] ?? 0) is String
          ? int.parse(json['overdueCount'])
          : json['overdueCount'] ?? 0,
    );
  }
}

// class CategoryTrend {
//   final String month;
//   final int fallHazard;
//   final int ppe;
//   final int campSafety;
//   final int electrical;
//   final int slipTrip;
//   final int fallingObject;

//   CategoryTrend({
//     required this.month,
//     required this.fallHazard,
//     required this.ppe,
//     required this.campSafety,
//     required this.electrical,
//     required this.slipTrip,
//     required this.fallingObject,
//   });
// }

// observation_trend_month.dart
class ObservationTrendMonth {
  final String stage;
  final int issueCount;
  final int ncrCount;
  final int goodPracticeCount;
  final int totalCount;

  ObservationTrendMonth({
    required this.stage,
    required this.issueCount,
    required this.ncrCount,
    required this.goodPracticeCount,
    required this.totalCount,
  });

  factory ObservationTrendMonth.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return ObservationTrendMonth(
      stage: json['stage'] ?? '',
      issueCount: parseInt(json['issue_count']), // ✅ int
      ncrCount: parseInt(json['ncr_count']),
      goodPracticeCount: parseInt(json['good_practice_count']),
      totalCount: parseInt(json['total_count']),
    );
  }
}

class CategoryTrend {
  final String stage;
  final Map<String, int> categoryData;

  CategoryTrend({
    required this.stage,
    required this.categoryData,
  });

  factory CategoryTrend.fromJson(Map<String, dynamic> json) {
    Map<String, int> parsed = {};

    final raw = json['category_data'];

    if (raw != null && raw.toString().trim().isNotEmpty) {
      List<String> items = raw.toString().split(',');

      for (var item in items) {
        var parts = item.split(':');

        if (parts.length >= 2) {
          String key = parts[0].trim().replaceAll(RegExp(r'\s+'), ' ');
          String valueStr = parts[1].trim();

          int value = int.tryParse(valueStr) ?? 0;

          parsed[key] = value;
        }
      }
    }

    return CategoryTrend(
      stage: json['stage'] ?? '',
      categoryData: parsed,
    );
  }
}
