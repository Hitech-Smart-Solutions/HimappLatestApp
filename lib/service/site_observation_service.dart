import 'dart:convert';
// import 'dart:io';
import 'dart:typed_data';
// import 'package:file_picker/file_picker.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;
// import 'package:path/path.dart';
// import 'package:http_parser/http_parser.dart';

class SiteObservationService {
  Future<List<SiteObservation>> fetchSiteObservationsSafety({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 10,
    bool isActive = true,
  }) async {
    final uri = Uri.https(
      'd94acvrm8bvo5.cloudfront.net',
      '/api/SiteObservation/GetSiteObservationSafetyByProjectID',
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

  Future<List<SiteObservation>> fetchSiteObservationsQuality({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 10,
    bool isActive = true,
  }) async {
    final uri = Uri.https(
      'd94acvrm8bvo5.cloudfront.net',
      '/api/SiteObservation/GetSiteObservationQualityByProjectID',
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
    print("Response status code: $response");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> table1 = data['Value']['Table1'];
      return table1.map((e) => SiteObservation.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load labours');
    }
  }

  Future<List<IssueType>> fetchIssueTypes(int observationTypeId) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/Observation/GetIssueTypeByObservationTypeID/$observationTypeId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => IssueType.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load issue types');
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
      int companyID, int screentypeID, int selectedIssueTypeId) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetObservationsByCompanyFunctionAndIssueTypeID/$companyID/$screentypeID/$selectedIssueTypeId'),
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
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List<dynamic> areaData = jsonData['value'];

        if (areaData.isEmpty) {
          print('No Area found');
          return [];
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
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List<dynamic> floorData = jsonData['value'];

        if (floorData.isEmpty) {
          print('No Floor found');
          return [];
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
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List<dynamic> partData = jsonData['value'];

        if (partData.isEmpty) {
          print('No Part found');
          return [];
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
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List<dynamic> partData = jsonData['value'];

        if (partData.isEmpty) {
          print('No Part found');
          return [];
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
        final List<dynamic> partData = jsonDecode(response.body);

        if (partData.isEmpty) {
          print('No Party found');
          return [];
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

    if (response.statusCode == 200) {
      try {
        final List<dynamic> userData = jsonDecode(response.body);
        if (userData.isEmpty) {
          print('No Users found');
          return [];
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

  // Method to submit the site observation
  Future<bool> submitSiteObservation(
      SiteObservationModel siteObservation) async {
    String? token = await SharedPrefsHelper.getToken();
    if (token == null) {
      print("❌ Token not found.");
      throw 'Authorization token not found.';
    }

    try {
      final response = await http.post(
        Uri.parse(
            'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/CreateSiteObservationMaster'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(siteObservation.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw response.body;
      }
    } catch (e) {
      print('❌ Error occurred: $e');
      throw e.toString();
    }
  }

  Future<List<Activity>> fatchActivityByCompanyIdAndScreenTypeId(
      int companyID, int screentypeID) async {
    try {
      final String? token = await SharedPrefsHelper.getToken();

      final Uri url = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/ActivityMaster/GetActivitiesByCompanyIDandScreenTypeID/$companyID/$screentypeID',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> jsonData = jsonResponse['value'] ?? [];

        return jsonData.map((item) => Activity.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load activities. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching activities: $e');
    }
  }

  Future<List<RootCause>> fatchRootCausesByActivityID(int companyId) async {
    try {
      final String? token = await SharedPrefsHelper.getToken();

      final Uri url = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/RootCause/GetRootCauseByCompanyID/$companyId',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => RootCause.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load root causes. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching root causes: $e');
    }
  }

  Future<List<NCRObservation>> fetchNCRObservations(int userId) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetSiteObservationSafetyByUserID/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonData = jsonDecode(response.body);
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

  Future<List<NCRObservation>> fetchNCRQualityObservations(int userId) async {
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetSiteObservationQualityByUserID/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonData = jsonDecode(response.body);
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

  Future<List<GetSiteObservationMasterById>> fetchGetSiteObservationMasterById(
      int Id) async {
    String? token = await SharedPrefsHelper.getToken();

    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetSiteObservationMasterById/$Id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonData = jsonDecode(response.body);
        if (jsonData.isEmpty) {
          print('⚠️ No observations returned for userId $Id');
        }

        return jsonData
            .map((item) => GetSiteObservationMasterById.fromJson(item))
            .toList();
      } catch (e) {
        print("❌ JSON Parsing Error fetchGetSiteObservationMasterById: $e");
        throw Exception('Failed to load Observation');
      }
    } else {
      throw Exception('Failed to load Observation: ${response.statusCode}');
    }
  }

  Future<bool> sendSiteObservationActivity({
    required List<ActivityDTO> activities,
    required int siteObservationID,
  }) async {
    String? token = await SharedPrefsHelper.getToken();

    if (token == null || token.isEmpty) {
      print('❌ No auth token found.');
      return false;
    }

    final url = Uri.parse(
        "https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/AddSiteObservationActivity/$siteObservationID");
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode(activities.map((a) => a.toJson()).toList());

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        print('✅ Activity posted successfully!');
        return true;
      } else {
        print('❌ Failed to post activity: ${response.statusCode}');
        print('📝 Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error posting activity: $e');
      return false;
    }
  }

  Future<bool> updateSiteObservationByID(UpdateSiteObservation data) async {
    String? token = await SharedPrefsHelper.getToken();
    final url = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/UpdateSiteObservationByID/${data.id}');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      print("Update successful!");
      return true;
    } else {
      print("Failed to update: ${response.statusCode} ${response.body}");
      return false;
    }
  }

  Future<List<UserList>> fetchUsersForList({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 10,
    bool isActive = true,
  }) async {
    final uri = Uri.https(
      'd94acvrm8bvo5.cloudfront.net',
      '/api/UserMaster/GetUsersForList',
      {
        'CompanyID': projectId.toString(),
        'SortColumn': sortColumn,
        'PageIndex': pageIndex.toString(),
        'PageSize': pageSize.toString(),
        'IsActive': isActive.toString(),
      },
    );

    final token = await SharedPrefsHelper.getToken();

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> users = data['Value']['Table1'];
      return users.map((e) => UserList.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<String?> uploadFileAndGetFileName(
      String fileName, Uint8List fileBytes) async {
    final uri = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/upload');

    final token = await SharedPrefsHelper.getToken();

    final request = http.MultipartRequest('POST', uri);

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    request.headers['Authorization'] = 'Bearer $token';

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 &&
          response.body.contains('file uploaded|')) {
        final path = response.body.split('|')[1];
        final fileNameFromPath = path.split('/').last;
        return fileNameFromPath;
      } else {
        print('❌ Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Upload error: $e');
    }

    return null;
  }

  Future<List<AssignedUser>> fetchGetassignedusersforReopen(int Id) async {
    String? token = await SharedPrefsHelper.getToken();

    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetSiteObservationAssignedPersonsForReopen/$Id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonData = jsonDecode(response.body);

        if (jsonData.isEmpty) {
          print('⚠️ No assigned users returned for SiteObservation $Id');
        }

        return jsonData.map((item) => AssignedUser.fromJson(item)).toList();
      } catch (e) {
        print("❌ JSON Parsing Error: $e");
        throw Exception('Failed to load assigned users');
      }
    } else {
      throw Exception('Failed to load assigned users: ${response.statusCode}');
    }
  }

  // Fetch FatchSiteObservationSafetyByUserID list
  Future<List<SiteObservation>> fatchSiteObservationSafetyByUserID(
      int? userID) async {
    print("Fetching safety observations for userID: $userID");
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetSiteObservationSafetyByUserID/$userID'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      print("Decoded JSON: $jsonData");
      if (jsonData.isEmpty) {
        print('No safety observations found');
        return [];
      }
      return jsonData.map((item) => SiteObservation.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load safety observations');
    }
  }

  Future<List<SiteObservation>> fatchSiteObservationQualityByUserID(
      int? userID) async {
    print("Fetching quality observations for userID: $userID");
    String? token = await SharedPrefsHelper.getToken();
    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetSiteObservationQualityByUserID/$userID'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    // print("Response body: ${response.body}");
    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonData = jsonDecode(response.body);
        print("Decoded JSON: $jsonData");
        if (jsonData.isEmpty) {
          print('No quality observations found');
          return [];
        }
        return jsonData.map((item) => SiteObservation.fromJson(item)).toList();
      } catch (e) {
        print("Error parsing the JSON data: $e");
        throw Exception('Failed to load quality observations');
      }
    } else {
      throw Exception('Failed to load quality observations');
    }
  }
}

Future<List<SectionModel>> getSectionsByProjectID(int projectID) async {
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
    // print('Response body: ${response.body}');
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((json) => SectionModel.fromJson(json)).toList();
    } else if (decoded is Map && decoded.containsKey('value')) {
      List<dynamic> data = decoded['value'];
      return data.map((json) => SectionModel.fromJson(json)).toList();
    } else {
      throw Exception('Unexpected response format');
    }
  } else {
    throw Exception('Failed to load sections');
  }
}

Future<List<FloorModel>> getFloorByProjectID(int projectID) async {
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
    // print('Floor API response: ${response.body}');
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((json) => FloorModel.fromJson(json)).toList();
    } else if (decoded is Map && decoded.containsKey('value')) {
      List<dynamic> data = decoded['value'];
      return data.map((json) => FloorModel.fromJson(json)).toList();
    } else {
      throw Exception('Unexpected response format for floor');
    }
  } else {
    throw Exception('Failed to load floors');
  }
}

Future<List<ElementModel>> getElementByProjectID(int projectID) async {
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
    // print('Element API response: ${response.body}');
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((json) => ElementModel.fromJson(json)).toList();
    } else if (decoded is Map && decoded.containsKey('value')) {
      List<dynamic> data = decoded['value'];
      return data.map((json) => ElementModel.fromJson(json)).toList();
    } else {
      throw Exception('Unexpected response format for elements');
    }
  } else {
    throw Exception('Failed to load elements');
  }
}
