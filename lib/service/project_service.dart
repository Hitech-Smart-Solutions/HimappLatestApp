import 'dart:convert';
import 'package:himappnew/model/project_model.dart';
import 'package:himappnew/network/api_client.dart';

class ProjectService {
  Future<List<Project>> fetchProject(int userID, int companyID) async {
    print('🔍 Fetching projects for UserID: $userID, CompanyID: $companyID');
    try {
      final response = await ApiClient.dio.get(
        '/api/UserRolePermission/GetProjectPermissionByUserandCompanyID/$userID/$companyID',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;
      print('✅ Raw API Response: $data');

      /// 🔹 Handle all possible API formats
      final table1 = data?['Value']?['Table1'] ??
          data?['value']?['table1'] ??
          data?['Table1'] ??
          data?['table1'] ??
          [];

      if (table1 is List) {
        return table1.map((json) => Project.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('❌ Failed to load projects: $e');
      return [];
    }
  }
}
