import 'dart:convert';
import '../network/api_client.dart';
import '../model/page_permission.dart';

class PagePermissionService {
  Future<List<PagePermission>> fetchPagePermissions(int userId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/UserRolePermission/GetUserRolePermissionbyProjectandUserid/$userId',
      );

      final data = response.data;

      // 🔥 string ya map dono handle karega
      final Map<String, dynamic> json =
          data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);

      final value = json['Value'];
      if (value == null) throw Exception('Value missing');

      final table1 = value['Table1'];
      if (table1 == null || table1 is! List) {
        throw Exception('Table1 missing or invalid');
      }

      return table1
          .map<PagePermission>((e) => PagePermission.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load page permissions: $e');
    }
  }
}
