import '../network/api_client.dart';
import '../model/company_model.dart';
import 'dart:convert';

class CompanyService {
  Future<List<Company>> fetchCompanies(int userId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/UserRolePermission/GetCompanyPermissionByUserID/$userId',
      );

      final data = response.data;

      // 🔥 Handle string response (very important)
      final Map<String, dynamic> json =
          data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);

      final value = json['Value'];
      if (value == null) {
        throw Exception('Value key missing');
      }

      final table1 = value['Table1'];
      if (table1 == null || table1 is! List) {
        throw Exception('Table1 missing or not a list');
      }

      return table1.map<Company>((e) => Company.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load companies: $e');
    }
  }
}
