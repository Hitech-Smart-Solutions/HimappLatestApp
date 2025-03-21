// company_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:himappnew/model/company.dart'; // Assuming Company model is in company.dart

class CompanyService {
  // Fetch data from the API
  Future<List<Company>> fetchCompanies() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.130:8000/api/CompanyMaster/GetCompanies'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Company.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load companies');
    }
  }
}
