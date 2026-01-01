import 'dart:convert';
import 'package:himappnew/model/project_model.dart';
import 'package:himappnew/network/api_client.dart';

class ProjectService {
  Future<List<Project>> fetchProject(int userID, int companyID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/UserRolePermission/GetProjectPermissionByUserandCompanyID/$userID/$companyID',
      );

      // Response ko json me decode karo agar string ho
      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (data is Map<String, dynamic> &&
          data.containsKey("Value") &&
          data["Value"] is Map<String, dynamic> &&
          data["Value"].containsKey("Table1") &&
          data["Value"]["Table1"] is List) {
        List<dynamic> projectList = data["Value"]["Table1"];
        return projectList.map((json) => Project.fromJson(json)).toList();
      } else {
        throw Exception(
          "Invalid API response format: Expected 'Value.Table1' to be a list",
        );
      }
    } catch (e) {
      print('❌ Failed to load projects: $e');
      throw Exception('Failed to load projects');
    }
  }
}
