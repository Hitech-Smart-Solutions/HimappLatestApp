import 'dart:convert';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;

class SiteObservationService {
  // Future<List<SiteObservation>> fetchSiteObservation() async {
  //   String? token = await SharedPrefsHelper.getToken();
  //   final response = await http.get(
  //     Uri.parse(
  //         'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetSiteObservationMaster'),
  //     headers: {
  //       'Authorization': 'Bearer $token', // 👈 Add this line
  //       'Content-Type': 'application/json',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final List<dynamic> jsonData = jsonDecode(response.body);

  //     // ✅ Convert JSON response to List<SiteObservation>
  //     return jsonData.map((item) => SiteObservation.fromJson(item)).toList();
  //   } else {
  //     throw Exception('Failed to load site observations');
  //   }
  // }

  Future<List<SiteObservation>> fetchSiteObservations({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 10,
    bool isActive = true,
  }) async {
    final uri = Uri.https(
      'd94acvrm8bvo5.cloudfront.net',
      '/api/SiteObservation/GetSiteObservationByProjectID',
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
      return table1.map((e) => SiteObservation.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load labours');
    }
  }

  Future<List<IssueType>> fetchIssueTypes() async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetIssueType'),
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
          'https://d94acvrm8bvo5.cloudfront.net/api/ActivityMaster/GetActivitiesByCompanyIDandScreenTypeID/$companyID/$screentypeID'),
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
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetObservationsByCompanyandfucntionID/$companyID/$screentypeID'),
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

// Fetch observation types
  Future<List<ObservationType>> fetchObservationType() async {
    String? token = await SharedPrefsHelper.getToken();

    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetObservationType'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonData = jsonDecode(response.body);
        if (jsonData.isEmpty) {
          print('No ObservationType found');
        }
        return jsonData.map((item) => ObservationType.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing JSON: $e");
        throw Exception('Failed to load ObservationType');
      }
    } else {
      throw Exception('Failed to load ObservationType');
    }
  }

// Fetch Area list
  Future<List<Area>> fetchAreaList(int projectID) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/ProjectSectionMapping/GetSectionsByProjectID/$projectID'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonData =
            jsonDecode(response.body); // Decode the response as a Map
        final List<dynamic> areaData =
            jsonData['value']; // Extract the list of areas from the 'value' key

        if (areaData.isEmpty) {
          print('No Area found');
          return []; // Return empty list if no areas are found
        }

        // Map the List of dynamic objects to Area objects
        return areaData.map((item) => Area.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data: $e");
        throw Exception('Failed to load Area');
      }
    } else {
      print("Error: ${response.statusCode}");
      throw Exception('Failed to load Area');
    }
  }

// Fetch floor list
  Future<List<Floor>> fetchFloorList(int projectID) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/ProjectFloorMapping/GetFloorsByProjectID/$projectID'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonData =
            jsonDecode(response.body); // Decode the response as a Map
        final List<dynamic> floorData =
            jsonData['value']; // Extract the list of Floor from the 'value' key

        if (floorData.isEmpty) {
          print('No Floor found');
          return []; // Return empty list if no Floor are found
        }

        // Map the List of dynamic objects to Floor objects
        return floorData.map((item) => Floor.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data: $e");
        throw Exception('Failed to load Floor');
      }
    } else {
      print("Error: ${response.statusCode}");
      throw Exception('Failed to load Floor');
    }
  }

  // Fetch part list
  Future<List<Part>> fetchPartList(int projectID) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/ProjectPartMapping/GetPartsByProjectID/$projectID'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonData =
            jsonDecode(response.body); // Decode the response as a Map
        final List<dynamic> partData =
            jsonData['value']; // Extract the list of Part from the 'value' key

        if (partData.isEmpty) {
          print('No Part found');
          return []; // Return empty list if no Part are found
        }

        // Map the List of dynamic objects to part objects
        return partData.map((item) => Part.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data: $e");
        throw Exception('Failed to load Floor');
      }
    } else {
      print("Error: ${response.statusCode}");
      throw Exception('Failed to load Floor');
    }
  }

  // Fetch Element list
  Future<List<Elements>> fetchElementList(int projectID) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/ProjectElementMapping/GetElementsByProjectID/$projectID'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> jsonData =
            jsonDecode(response.body); // Decode the response as a Map
        final List<dynamic> partData = jsonData[
            'value']; // Extract the list of Element from the 'value' key

        if (partData.isEmpty) {
          print('No Part found');
          return []; // Return empty list if no Element are found
        }

        // Map the List of dynamic objects to Element objects
        return partData.map((item) => Elements.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data: $e");
        throw Exception('Failed to load Element');
      }
    } else {
      print("Error: ${response.statusCode}");
      throw Exception('Failed to load Element');
    }
  }

  // Fetch contractor list
  Future<List<Party>> fetchContractorList() async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetPartyMasters/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> partData =
            jsonDecode(response.body); // Decode as List<dynamic>

        if (partData.isEmpty) {
          print('No Party found');
          return []; // Return empty list if no Party are found
        }

        // Map the List of dynamic objects to Party objects
        return partData.map((item) => Party.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data: $e");
        throw Exception('Failed to load Party');
      }
    } else {
      print("Error: ${response.statusCode}");
      throw Exception('Failed to load Party');
    }
  }

  // Fetch user list
  Future<List<User>> fetchUserList() async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/UserMaster/GetUsers/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("Response status1: ${response.statusCode}"); // Log the status code

    if (response.statusCode == 200) {
      try {
        final List<dynamic> userData = jsonDecode(
            response.body); // Extract the list of Users from the 'value' key
        if (userData.isEmpty) {
          print('No Users found');
          return []; // Return empty list if no users are found
        }

        // Map the List of dynamic objects to User objects
        return userData.map((item) => User.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data1: $e");
        throw Exception('Failed to load Users');
      }
    } else {
      print("Error: ${response.statusCode}"); // Log the error status code
      throw Exception('Failed to load Users');
    }
  }

  // final String apiUrl =
  //     'https://d94acvrm8bvo5.cloudfront.net/api/UserMaster/GetUsers/'; // Replace with your API URL

  // Method to submit the site observation
  Future<bool> submitSiteObservation(
      SiteObservationModel siteObservation) async {
    String? token = await SharedPrefsHelper.getToken();
    if (token == null) {
      print("❌ Token not found.");
      return false;
    }
    try {
      final response = await http.post(
        Uri.parse(
            'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/CreateSiteObservationMaster'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ✅ Add token here},
        },
        body: json.encode(siteObservation.toJson()), // Convert model to JSON
      );
      print("📦 JSON Payload:");
      print("response, $response"); // Log the response body
      if (response.statusCode == 200 || response.statusCode == 201) {
        final parsed = jsonDecode(response.body);
        print("Parsed: $parsed");
        // Success
        return true;
      } else {
        // Handle failure response
        print('Failed to submit: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Handle error
      print('Error occurred: $e');
      return false;
    }
  }

  // Future<bool> submitSiteObservation(
  //     SiteObservationModel siteObservation) async {
  //   String? token = await SharedPrefsHelper.getToken();

  //   if (token == null) {
  //     print("❌ Token not found.");
  //     return false;
  //   }

  //   final url = Uri.parse(
  //       'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/CreateSiteObservationMaster');

  //   final headers = {
  //     'Content-Type': 'application/json',
  //     'Authorization': 'Bearer $token', // ✅ Add token here
  //   };

  //   final response = await http.post(
  //     url,
  //     headers: headers,
  //     body: jsonEncode(data.toJson()),
  //   );

  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     print('✅ Registration successful');
  //     return true;
  //   } else {
  //     print('❌ Error: ${response.statusCode}');
  //     print('Body: ${response.body}');
  //     return false;
  //   }
  // }

  Future<List<NCRObservation>> fetchNCRObservations(int userId) async {
    String? token = await SharedPrefsHelper.getToken();
    print("📤 Token: $token");
    print("📤 Calling API with UserId: $userId");

    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetSiteObservationSafetyByUserID?UserId=$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("📥 API Status: ${response.statusCode}");
    print("📥 API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonData = jsonDecode(response.body);
        print("🔍 JSON Length: ${jsonData.length}");

        if (jsonData.isEmpty) {
          print('⚠️ No observations returned for userId $userId');
        }

        return jsonData.map((item) => NCRObservation.fromJson(item)).toList();
      } catch (e) {
        print("❌ JSON Parsing Error: $e");
        throw Exception('Failed to load Observation');
      }
    } else {
      throw Exception('Failed to load Observation: ${response.statusCode}');
    }
  }
}
