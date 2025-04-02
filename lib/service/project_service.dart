import 'dart:convert';
import 'package:himappnew/model/project.dart';
import 'package:http/http.dart' as http;

class ProjectService {
  Future<List<Project>> fetchProject(int userID, int companyID) async {
    final response = await http.get(
      Uri.parse(
        'http://192.168.1.130:8000/api/UserRolePermission/GetProjectPermissionByUserandCompanyID/$userID/$companyID',
      ),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is Map<String, dynamic> &&
          jsonData.containsKey("Value") &&
          jsonData["Value"] is Map<String, dynamic> &&
          jsonData["Value"].containsKey("Table1") &&
          jsonData["Value"]["Table1"] is List) {
        List<dynamic> projectList = jsonData["Value"]["Table1"];

        return projectList.map((json) => Project.fromJson(json)).toList();
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
