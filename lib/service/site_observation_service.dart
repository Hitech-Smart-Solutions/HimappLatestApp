import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';

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
    print(
        "Fetching observations for companyID: $companyID and screentypeID: $screentypeID");
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

      print("📦 JSON Payload Sent");
      print("Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // ❗ Throw backend error message to show it in UI
        throw response.body;
      }
    } catch (e) {
      print('❌ Error occurred: $e');
      throw e.toString(); // Re-throw to let UI handle it
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

  Future<List<RootCause>> fatchRootCausesByActivityID(int activityID) async {
    try {
      final String? token = await SharedPrefsHelper.getToken();

      final Uri url = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/RootCause/GetRootCauseByActivityID/$activityID',
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
    print("📤 Token: $token");
    print("📤 Calling API with UserId: $userId");

    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetSiteObservationSafetyByUserID/$userId'),
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

  Future<List<GetSiteObservationMasterById>> fetchGetSiteObservationMasterById(
      int Id) async {
    String? token = await SharedPrefsHelper.getToken();
    print("📤 Token: $token");
    print("📤 Calling API with UserId: $Id");

    final response = await http.get(
      Uri.parse(
          'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/GetSiteObservationMasterById/$Id'),
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
          print('⚠️ No observations returned for userId $Id');
        }

        return jsonData
            .map((item) => GetSiteObservationMasterById.fromJson(item))
            .toList();
      } catch (e) {
        print("❌ JSON Parsing Error: $e");
        throw Exception('Failed to load Observation');
      }
    } else {
      throw Exception('Failed to load Observation: ${response.statusCode}');
    }
  }

  // Future<String?> uploadFile(File file) async {
  //   try {
  //     var request = http.MultipartRequest(
  //       'POST',
  //       Uri.parse(
  //           'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/upload'),
  //     );

  //     String? token = await SharedPrefsHelper.getToken();
  //     print('🔑 Token: $token');

  //     request.headers.addAll({
  //       'Authorization': 'Bearer $token',
  //       'Content-Type': 'application/json',
  //     });

  //     request.files.add(
  //       await http.MultipartFile.fromPath(
  //         'file',
  //         file.path,
  //         filename: basename(file.path),
  //         contentType: MediaType('image', 'jpeg'),
  //       ),
  //     );

  //     print('📤 Sending request to: ${request.url}');
  //     print('📎 File path: ${file.path}');
  //     print('📎 File name: ${basename(file.path)}');

  //     var response = await request.send();
  //     final responseBody = await response.stream.bytesToString();

  //     print('📥 Status Code: ${response.statusCode}');
  //     print('📥 Response Body: $responseBody');

  //     if (response.statusCode == 200) {
  //       // Response format: "file uploaded|<url>"
  //       final parts = responseBody.split('|');
  //       if (parts.length == 2) {
  //         final uploadedUrl = parts[1].trim();
  //         return uploadedUrl; // ✅ Return the URL
  //       } else {
  //         print('❌ Unexpected response format');
  //         return null;
  //       }
  //     } else {
  //       print('❌ Upload failed: ${response.statusCode}');
  //       return null;
  //     }
  //   } catch (e) {
  //     print('❌ Exception during upload: $e');
  //     return null;
  //   }
  // }

  // Future<void> sendSiteObservationActivity(
  //     List<ActivityDTO> activities, int siteObservationID) async {
  //   String? token = await SharedPrefsHelper.getToken();
  //   final url = Uri.parse(
  //       'https://d94acvrm8bvo5.cloudfront.net/api/SiteObservation/AddSiteObservationActivity/$siteObservationID');

  //   // Convert your ActivityDTO list to JSON list
  //   final body = jsonEncode(activities.map((a) => a.toJson()).toList());

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: body,
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       print('Activity posted successfully!');
  //     } else {
  //       print('Failed to post activity: ${response.statusCode}');
  //       print('Response body: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Error posting activity: $e');
  //   }
  // }

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
      'Authorization': 'Bearer $token', // Adjust format if API needs different
    };

    final body = jsonEncode(activities.map((a) => a.toJson()).toList());
    print("📤 POST Body: $body");

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
    print("Sending payload: ${jsonEncode(data.toJson())}");
    print("Sending to URL: $url");
    // print("GET Status123: ${response.statusCode}");
    // print("Body123: ${response.body}");
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

    print("Uploading file: $fileName");

    request.headers['Authorization'] = 'Bearer $token';
    // NO Content-Type header here, MultipartRequest sets it automatically

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 200 &&
          response.body.contains('file uploaded|')) {
        final path = response.body.split('|')[1];
        print('🟢 File uploaded successfully! Path: $path');
        final fileNameFromPath = path.split('/').last;
        print('🟢 Extracted file name: $fileNameFromPath');
        return fileNameFromPath;
      } else {
        print('❌ Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Upload error: $e');
    }

    return null;
  }
}
