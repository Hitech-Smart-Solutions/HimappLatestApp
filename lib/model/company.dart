// company.dart

class Company {
  final int id;
  final String name;

  Company({required this.id, required this.name});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['ID'], // Assuming 'id' is the field name for company ID
      name: json['CompanyName'], // Replace with actual field name
    );
  }
}
