import 'dart:convert';
import 'package:himappnew/model/SiteObservation.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;

class SiteObservationService {
  Future<List<SiteObservation>> fetchSiteObservation() async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.130:8000/api/SiteObservation/GetSiteObservationMaster'),
      headers: {
        'Authorization': 'Bearer $token', // 👈 Add this line
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);

      // ✅ Convert JSON response to List<SiteObservation>
      return jsonData.map((item) => SiteObservation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load site observations');
    }
  }
}
