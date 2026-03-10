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
  final int overdueCount;
  final int dueCount;
  final int totalCount;

  ObservationSummary({
    required this.stage,
    required this.overdueCount,
    required this.dueCount,
    required this.totalCount,
  });

  factory ObservationSummary.fromJson(Map<String, dynamic> json) {
    return ObservationSummary(
      stage: json['stage'],
      overdueCount: json['overdue_count'],
      dueCount: json['due_count'],
      totalCount: json['total_count'],
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
