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
  //       'https://d94acvrm8bvo5.cloudfront.net/api/LabourRegistration/GetLabourRegistrations',
  //     ),
  //   );

  //   if (response.statusCode == 200) {
  //     List<dynamic> jsonList = jsonDecode(response.body);
  //     return jsonList.map((json) => LabourModel.fromJson(json)).toList();
  //   } else {
  //     throw Exception('Failed to load labour data');
  //   }
  // }

  // Future<List<LabourModel>> fetchLabours() async {
  //   String? token = await SharedPrefsHelper.getToken();

  //   final response = await http.get(
  //     Uri.parse(
  //         'https://d94acvrm8bvo5.cloudfront.net/api/LabourRegistration/GetLabourRegistrationByProjectID?ProjectID=32796&SortColumn=ID%20desc&PageIndex=0&PageSize=10&IsActive=true'),
  //     headers: {
  //       'Authorization': 'Bearer $token',
  //       'Content-Type': 'application/json',
  //     },
  //   );
  //   if (response.statusCode == 200) {
  //     try {
  //       // Directly decode the JSON response as a List
  //       final data = jsonDecode(response.body);
  //       final rows = data['Value']['Table1'] as List;
  //       // Check if the list is empty
  //       if (data.isEmpty) {
  //         print('No activities found');
  //       }

  //       // Map the List of dynamic objects to Observation objects
  //       return rows.map((e) => LabourModel.fromJson(e)).toList();
  //     } catch (e) {
  //       print("Error parsing the JSON data: $e");
  //       throw Exception('Failed to load Observation');
  //     }
  //   } else {
  //     throw Exception('Failed to load Observation');
  //   }
  // }

  Future<List<LabourModel>> fetchLabours({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 10,
    bool isActive = true,
  }) async {
    final uri = Uri.https(
      'd94acvrm8bvo5.cloudfront.net',
      '/api/LabourRegistration/GetLabourRegistrationByProjectID',
      {
        'ProjectID': projectId.toString(),
        'SortColumn': sortColumn,
        'PageIndex': pageIndex.toString(),
        'PageSize': pageSize.toString(),
        'IsActive': isActive.toString(),
      },
    );
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> table1 = data['Value']['Table1'];
      return table1.map((e) => LabourModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load labours');
    }
  }

  //Party List
  Future<List<PartyModel>> fetchParties() async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetPartyMasters'),
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
          'https://d94acvrm8bvo5.cloudfront.net/api/LabourCategoryType/GetLabourCategories'),
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
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/Country/GetCountries'),
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
          'https://d94acvrm8bvo5.cloudfront.net/api/State/GetStatesByCountryID/$CountryID'),
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
          'https://d94acvrm8bvo5.cloudfront.net/api/State/GetCitiesByStateID/$stateId'),
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
  //       'https://d94acvrm8bvo5.cloudfront.net/api/UserRolePermission/GetProjectPermissionByUserandCompanyID/$userID/$companyID',
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

  Future<bool> submitLabourRegistration(LabourRegistration data) async {
    String? token = await SharedPrefsHelper.getToken();

    if (token == null) {
      print("❌ Token not found.");
      return false;
    }

    final url = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/LabourRegistration/CreateLabourRegistrationMaster');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // ✅ Add token here
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ Registration successful');
      return true;
    } else {
      print('❌ Error: ${response.statusCode}');
      print('Body: ${response.body}');
      return false;
    }
  }

  Future<bool> updateLabourRegistration(LabourRegistration data) async {
    String? token = await SharedPrefsHelper.getToken();
    print("Labour ID: ${data.id}");

    if (token == null) {
      print("❌ Token not found.");
      return false;
    }

    final url = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/LabourRegistration/UpdateLabourRegistrationByID/${data.id}');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(data.toJson()),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print('✅ Labour Registration Update successful');
      return true;
    } else {
      print('❌ Error: ${response.statusCode}');
      print('Body: ${response.body}');
      return false;
    }
  }

  Future<LabourRegistration> getLabourById(int id) async {
    String? token = await SharedPrefsHelper.getToken();
    final url = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/LabourRegistration/GetLabourRegistrationMasterById/$id');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);
    print('Raw API Response: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);

      print("API Response: $json"); // ✅ You're already seeing this log

      final valueData = json['value']; // ✅ extract just the value

      if (valueData != null) {
        print("Full Name: ${valueData['fullName']}");
        print("Contact No: ${valueData['contactNo']}");
        return LabourRegistration.fromJson(valueData); // ✅ CORRECT LINE
      } else {
        throw Exception("No data found for labour ID $id");
      }
    } else {
      throw Exception('Failed to load Labour Registration');
    }
  }
}
