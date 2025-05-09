import 'dart:convert';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;
import 'package:himappnew/model/labour_registration_model.dart';

class LabourRegistrationService {
  // URL to fetch labour data
  // final String apiUrl = 'https://your-api-url.com/labours';

  // // Function to fetch labours from the API
  // Future<List<LabourModel>> fetchLabours() async {
  //   final response = await http.get(
  //     Uri.parse(
  //       'http://192.168.1.130:8000/api/LabourRegistration/GetLabourRegistrations',
  //     ),
  //   );

  //   if (response.statusCode == 200) {
  //     List<dynamic> jsonList = jsonDecode(response.body);
  //     return jsonList.map((json) => LabourModel.fromJson(json)).toList();
  //   } else {
  //     throw Exception('Failed to load labour data');
  //   }
  // }

  Future<List<LabourModel>> fetchLabours() async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.130:8000/api/LabourRegistration/GetLabourRegistrations'),
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
        return jsonData.map((item) => LabourModel.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data: $e");
        throw Exception('Failed to load Observation');
      }
    } else {
      throw Exception('Failed to load Observation');
    }
  }

  //Party List
  Future<List<PartyModel>> fetchParties() async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.130:8000/api/SiteObservation/GetPartyMasters'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => PartyModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load cities');
    }
  }

  //Labour Type List
  Future<List<LabourTypeModel>> fetchLabourTypes() async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.130:8000/api/LabourCategoryType/GetLabourCategories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => LabourTypeModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load cities');
    }
  }

  //country list

  Future<List<CountriesModel>> fetchCountries() async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse('http://192.168.1.130:8000/api/Country/GetCountries'),
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
        return jsonData.map((item) => CountriesModel.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data: $e");
        throw Exception('Failed to load Observation');
      }
    } else {
      throw Exception('Failed to load Observation');
    }
  }

  //State list

  Future<List<StateModel>> fetchState(int CountryID) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.130:8000/api/State/GetStatesByCountryID/$CountryID'),
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
        return jsonData.map((item) => StateModel.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data: $e");
        throw Exception('Failed to load Observation');
      }
    } else {
      throw Exception('Failed to load Observation');
    }
  }

  // City List

  Future<List<CityModel>> fetchCities(int stateId) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'http://192.168.1.130:8000/api/State/GetCitiesByStateID/$stateId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => CityModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load cities');
    }
  }

  // Future<List<Project>> fetchProject(int userID, int companyID) async {
  //   final response = await http.get(
  //     Uri.parse(
  //       'http://192.168.1.130:8000/api/UserRolePermission/GetProjectPermissionByUserandCompanyID/$userID/$companyID',
  //     ),
  //   );

  //   if (response.statusCode == 200) {
  //     final jsonData = jsonDecode(response.body);
  //     if (jsonData is Map<String, dynamic> &&
  //         jsonData.containsKey("Value") &&
  //         jsonData["Value"] is Map<String, dynamic> &&
  //         jsonData["Value"].containsKey("Table1") &&
  //         jsonData["Value"]["Table1"] is List) {
  //       List<dynamic> projectList = jsonData["Value"]["Table1"];

  //       return projectList.map((json) => Project.fromJson(json)).toList();
  //     } else {
  //       throw Exception(
  //         "Invalid API response format: Expected 'Value.Table1' to be a list",
  //       );
  //     }
  //   } else {
  //     throw Exception('Failed to load projects');
  //   }
  // }
}
