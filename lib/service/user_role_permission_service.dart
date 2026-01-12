import '../network/api_client.dart';

class UserRolePermissionService {
  Future<List<dynamic>> getRolePermission(int userId, int companyId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/UserRolePermission/GetUserRolePermissionbyProjectandUserid/$userId',
        queryParameters: {
          "companyId": companyId,
        },
      );

      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Role permission API failed: $e');
    }
  }
}
