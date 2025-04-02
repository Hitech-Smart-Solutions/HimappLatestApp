class Project {
  final int id;
  final String name;

  Project({required this.id, required this.name});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['ID'], // Assuming 'id' is the field name for company ID
      name: json['ProjectName'], // Replace with actual field name
    );
  }
}
