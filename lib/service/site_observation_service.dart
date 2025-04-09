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

// Fetch observation types
  Future<List<ObservationType>> fetchObservationType() async {
    String? token = await SharedPrefsHelper.getToken();

    final response = await http.get(
      Uri.parse(
          'http://192.168.1.130:8000/api/SiteObservation/GetObservationType'),
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
          'http://192.168.1.130:8000/api/ProjectSectionMapping/GetSectionsByProjectID/$projectID'),
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
          'http://192.168.1.130:8000/api/ProjectFloorMapping/GetFloorsByProjectID/$projectID'),
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
          'http://192.168.1.130:8000/api/ProjectPartMapping/GetPartsByProjectID/$projectID'),
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
          'http://192.168.1.130:8000/api/ProjectElementMapping/GetElementsByProjectID/$projectID'),
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
          'http://192.168.1.130:8000/api/SiteObservation/GetPartyMasters/'),
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
      Uri.parse('http://192.168.1.130:8000/api/UserMaster/GetUsers/'),
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
  //     'http://192.168.1.130:8000/api/UserMaster/GetUsers/'; // Replace with your API URL

  // Method to submit the site observation
  Future<bool> submitSiteObservation(
      SiteObservationModel siteObservation) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://192.168.1.130:8000/api/SiteObservation/CreateSiteObservationMaster'),
        headers: {'Content-Type': 'application/json'},
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
}
