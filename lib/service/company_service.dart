// company_service.dart

import 'dart:convert';
import 'package:himappnew/model/company_model.dart';
import 'package:http/http.dart' as http;

class CompanyService {
  // Fetch data from the API
  Future<List<Company>> fetchCompanies(int userId) async {
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/UserRolePermission/GetCompanyPermissionByUserID/$userId'),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is Map<String, dynamic> &&
          jsonData.containsKey("Value") &&
          jsonData["Value"] is Map<String, dynamic> &&
          jsonData["Value"].containsKey("Table1") &&
          jsonData["Value"]["Table1"] is List) {
        List<dynamic> projectList = jsonData["Value"]["Table1"];

        return projectList.map((json) => Company.fromJson(json)).toList();
      } else {
        throw Exception(
          "Invalid API response format: Expected 'Value.Table1' to be a list",
        );
      }
    } else {
      throw Exception('Failed to load projects');
    }
  }
}
