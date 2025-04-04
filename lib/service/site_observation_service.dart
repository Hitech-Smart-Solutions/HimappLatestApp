import 'dart:convert';
import 'package:himappnew/model/siteobservation_model.dart';
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

  Future<List<IssueType>> fetchIssueTypes() async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse('http://192.168.1.130:8000/api/SiteObservation/GetIssueType'),
      headers: {
        'Authorization': 'Bearer $token', // 👈 Add this line
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);

      // ✅ Convert JSON response to List<SiteObservation>
      return jsonData.map((item) => IssueType.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load site observations');
    }
  }

  Future<List<Activities>> fetchActivities(
      int companyID, int screentypeID) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.130:8000/api/ActivityMaster/GetActivitiesByCompanyIDandScreenTypeID/$companyID/$screentypeID'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        // Check if the "value" field exists and is not null
        if (jsonData['value'] == null) {
          throw Exception('"value" field is null');
        }
        final List<dynamic> activitiesJson = jsonData['value'] ?? [];
        // If activitiesJson is empty, log the message
        if (activitiesJson.isEmpty) {
          print('No activities found');
        }

        // Map the JSON data to Activities objects
        return activitiesJson.map((item) => Activities.fromJson(item)).toList();
      } catch (e) {
        throw Exception('Failed to load activities');
      }
    } else {
      throw Exception('Failed to load activities');
    }
  }

  Future<List<Observation>> fetchObservations(
      int companyID, int screentypeID) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.130:8000/api/SiteObservation/GetObservationsByCompanyandfucntionID/$companyID/$screentypeID'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      try {
        // Directly decode the JSON response as a List
        final List<dynamic> jsonData = jsonDecode(response.body);

        // Check if the list is empty
        if (jsonData.isEmpty) {
          print('No activities found');
        }

        // Map the List of dynamic objects to Observation objects
        return jsonData.map((item) => Observation.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data: $e");
        throw Exception('Failed to load Observation');
      }
    } else {
      throw Exception('Failed to load Observation');
    }
  }
}
