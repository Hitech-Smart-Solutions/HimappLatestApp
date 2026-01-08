import 'dart:convert';
import 'dart:typed_data';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;
import 'package:himappnew/network/api_client.dart';
import 'package:dio/dio.dart';

class SiteObservationService {
  Future<List<SiteObservation>> fetchSiteObservationsSafety({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 10,
    bool isActive = true,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/SiteObservation/GetSiteObservationSafetyByProjectID',
        queryParameters: {
          'ProjectID': projectId,
          'SortColumn': sortColumn,
          'PageIndex': pageIndex,
          'PageSize': pageSize,
          'IsActive': isActive,
        },
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> table1 = data['Value']['Table1'];

      return table1.map((e) => SiteObservation.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load labours');
    }
  }

  Future<List<SiteObservation>> fetchSiteObservationsQuality({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 100,
    bool isActive = true,
  }) async {
    try {
      print(projectId);

      final response = await ApiClient.dio.get(
        '/api/SiteObservation/GetSiteObservationQualityByProjectID',
        queryParameters: {
          'ProjectID': projectId,
          'SortColumn': sortColumn,
          'PageIndex': pageIndex,
          'PageSize': pageSize,
          'IsActive': isActive,
        },
      );

      print("Response status code: ${response.statusCode}");

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> table1 = data['Value']['Table1'];

      return table1.map((e) => SiteObservation.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load labours');
    }
  }

  Future<List<IssueType>> fetchIssueTypes(int observationTypeId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/Observation/GetIssueTypeByObservationTypeID/$observationTypeId',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (data is List) {
        return data.map((item) => IssueType.fromJson(item)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      throw Exception('Failed to load issue types: $e');
    }
  }

  Future<List<Activities>> fetchActivities(
      int companyID, int screentypeID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ActivityMaster/GetActivitiesByCompanyIDandScreenTypeID/$companyID/$screentypeID',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (data['value'] == null) {
        throw Exception('"value" field is null');
      }

      final List<dynamic> activitiesJson = data['value'] ?? [];

      if (activitiesJson.isEmpty) {
        print('No activities found');
      }

      return activitiesJson.map((item) => Activities.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load activities');
    }
  }

  Future<List<Observation>> fetchObservations(
      int companyID, int screentypeID, int selectedIssueTypeId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/SiteObservation/GetObservationsByCompanyFunctionAndIssueTypeID/$companyID/$screentypeID/$selectedIssueTypeId',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (data is List && data.isEmpty) {
        print('No activities found');
      }

      if (data is List) {
        return data.map((item) => Observation.fromJson(item)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print("Error parsing the JSON data: $e");
      throw Exception('Failed to load Observation');
    }
  }

// Fetch observation types
  Future<List<ObservationType>> fetchObservationType() async {
    try {
      final response = await ApiClient.dio.get(
        '/api/SiteObservation/GetObservationType',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (data is List && data.isEmpty) {
        print('No ObservationType found');
      }

      if (data is List) {
        return data.map((item) => ObservationType.fromJson(item)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print("Error parsing JSON: $e");
      throw Exception('Failed to load ObservationType');
    }
  }

// Fetch Area list
  Future<List<Area>> fetchAreaList(int projectID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ProjectSectionMapping/GetSectionsByProjectID/$projectID',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> areaData = data['value'];

      if (areaData.isEmpty) {
        print('No Area found');
        return [];
      }

      return areaData.map((item) => Area.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing the JSON data: $e");
      throw Exception('Failed to load Area');
    }
  }

// Fetch floor list
  Future<List<Floor>> fetchFloorList(int projectID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ProjectFloorMapping/GetFloorsByProjectID/$projectID',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> floorData = data['value'];

      if (floorData.isEmpty) {
        print('No Floor found');
        return [];
      }

      return floorData.map((item) => Floor.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing the JSON data: $e");
      throw Exception('Failed to load Floor');
    }
  }

  // Fetch part list
  Future<List<Part>> fetchPartList(int projectID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ProjectPartMapping/GetPartsByProjectID/$projectID',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> partData = data['value'];

      if (partData.isEmpty) {
        print('No Part found');
        return [];
      }

      return partData.map((item) => Part.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing the JSON data: $e");
      throw Exception('Failed to load Part');
    }
  }

  // Fetch Element list
  Future<List<Elements>> fetchElementList(int projectID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ProjectElementMapping/GetElementsByProjectID/$projectID',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> partData = data['value'];

      if (partData.isEmpty) {
        print('No Element found');
        return [];
      }

      return partData.map((item) => Elements.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing the JSON data: $e");
      throw Exception('Failed to load Element');
    }
  }

  // Fetch contractor list
  Future<List<Party>> fetchContractorList() async {
    try {
      final response = await ApiClient.dio.get(
        '/api/SiteObservation/GetPartyMasters/',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> partData = data;

      if (partData.isEmpty) {
        print('No Party found');
        return [];
      }

      return partData.map((item) => Party.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing the JSON data: $e");
      throw Exception('Failed to load Party');
    }
  }

  // Fetch user list
  Future<List<User>> fetchUserList() async {
    try {
      final response = await ApiClient.dio.get(
        '/api/UserMaster/GetUsers/',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> userData = data;

      if (userData.isEmpty) {
        print('No Users found');
        return [];
      }

      return userData.map((item) => User.fromJson(item)).toList();
    } catch (e) {
      print("Error parsing the JSON data: $e");
      throw Exception('Failed to load Users');
    }
  }

  // Method to submit the site observation
  Future<bool> submitSiteObservation(
      SiteObservationModel siteObservation) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/SiteObservation/CreateSiteObservationMaster',
        data: siteObservation.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error occurred: $e');
      throw e.toString();
    }
  }

  Future<bool> updateSiteObservationDraft(
      SiteObservationUpdateDraftModel updateDraft) async {
    try {
      final response = await ApiClient.dio.put(
        '/api/SiteObservation/UpdateSiteObservationDraftByID/${updateDraft.id}',
        data: updateDraft.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error occurred: $e');
      throw e.toString();
    }
  }

  Future<List<Activity>> fatchActivityByCompanyIdAndScreenTypeId(
      int companyID, int screentypeID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ActivityMaster/GetActivitiesByCompanyIDandScreenTypeID/$companyID/$screentypeID',
      );

      final List<dynamic> jsonData = response.data['value'] ?? [];

      return jsonData.map((item) => Activity.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Error fetching activities: $e');
    }
  }

  Future<List<RootCause>> fatchRootCausesByActivityID(int companyId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/RootCause/GetRootCauseByCompanyID/$companyId',
      );

      final List<dynamic> jsonData =
          response.data is String ? jsonDecode(response.data) : response.data;

      return jsonData.map((item) => RootCause.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Error fetching root causes: $e');
    }
  }

  Future<List<NCRObservation>> fetchNCRSafetyObservations(int userId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/SiteObservation/GetSiteObservationSafetyByUserID/$userId',
      );

      final List<dynamic> jsonData =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (jsonData.isEmpty) {
        print('⚠️ No observations returned for userId $userId');
      }

      return jsonData.map((item) => NCRObservation.fromJson(item)).toList();
    } catch (e) {
      print("❌ Error fetching NCR Safety Observations: $e");
      throw Exception('Failed to load Observation');
    }
  }

  Future<List<NCRObservation>> fetchNCRQualityObservations(int userId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/SiteObservation/GetSiteObservationQualityByUserID/$userId',
      );

      final List<dynamic> jsonData =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (jsonData.isEmpty) {
        print('⚠️ No observations returned for userId $userId');
      }

      return jsonData.map((item) => NCRObservation.fromJson(item)).toList();
    } catch (e) {
      print("❌ Error fetching NCR Quality Observations: $e");
      throw Exception('Failed to load Observation');
    }
  }

  Future<List<GetSiteObservationMasterById>> fetchGetSiteObservationMasterById(
      int Id) async {
    try {
      final response = await ApiClient.dio
          .get('/api/SiteObservation/GetSiteObservationMasterById/$Id');

      final List<dynamic> jsonData =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (jsonData.isEmpty) {
        print('⚠️ No observations returned for ID $Id');
      }

      return jsonData
          .map((item) => GetSiteObservationMasterById.fromJson(item))
          .toList();
    } catch (e) {
      print("❌ JSON Parsing Error fetchGetSiteObservationMasterById: $e");
      throw Exception('Failed to load Observation');
    }
  }

  Future<bool> sendSiteObservationActivity({
    required List<ActivityDTO> activities,
    required int siteObservationID,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/SiteObservation/AddSiteObservationActivity/$siteObservationID',
        data: activities.map((a) => a.toJson()).toList(),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        print('✅ Activity posted successfully!');
        return true;
      } else {
        print('❌ Failed to post activity: ${response.statusCode}');
        print('📝 Response: ${response.data}');
        return false;
      }
    } catch (e) {
      print('❌ Error posting activity: $e');
      return false;
    }
  }

  Future<bool> updateSiteObservationByID(UpdateSiteObservation data) async {
    try {
      final response = await ApiClient.dio.put(
        '/api/SiteObservation/UpdateSiteObservationByID/${data.id}',
        data: data.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Update successful!");
        return true;
      } else {
        print("Failed to update: ${response.statusCode} ${response.data}");
        return false;
      }
    } catch (e) {
      print('❌ Error updating site observation: $e');
      return false;
    }
  }

  Future<List<UserList>> fetchUsersForList({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 100,
    bool isActive = true,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/UserMaster/GetUsersForList',
        queryParameters: {
          'CompanyID': projectId.toString(),
          'SortColumn': sortColumn,
          'PageIndex': pageIndex.toString(),
          'PageSize': pageSize.toString(),
          'IsActive': isActive.toString(),
        },
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> users = data['Value']['Table1'] ?? [];
      return users.map((e) => UserList.fromJson(e)).toList();
    } catch (e) {
      print('❌ Failed to fetch users: $e');
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<UserList>> getUsersForSiteObservation({
    required int siteObservationId,
    required int flag, // 1 = comment, 2 = assign
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/UserMaster/GetUsersForSiteObservation/$siteObservationId/$flag',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> users = data['Value']['Table1'] ?? [];

      return users.map((e) => UserList.fromJson(e)).toList();
    } catch (e) {
      print('❌ Failed to fetch users: $e');
      return [];
    }
  }

  Future<String?> uploadFileAndGetFileName(
      String fileName, Uint8List fileBytes) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
      });

      final response = await ApiClient.dio.post(
        '/api/SiteObservation/upload',
        data: formData,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;

        final storedFileName = data['storedFileName'];

        if (storedFileName != null && storedFileName.toString().isNotEmpty) {
          print("✅ Upload success: $storedFileName");
          return storedFileName;
        }
      }

      print("❌ Upload failed: ${response.statusCode} - ${response.data}");
      return null;
    } catch (e) {
      print("❌ Upload error: $e");
      return null;
    }
  }

  Future<List<AssignedUser>> fetchGetassignedusersforReopen(int Id) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/SiteObservation/GetSiteObservationAssignedPersonsForReopen/$Id',
      );

      final List<dynamic> jsonData =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (jsonData.isEmpty) {
        print('⚠️ No assigned users returned for SiteObservation $Id');
      }

      return jsonData.map((item) => AssignedUser.fromJson(item)).toList();
    } catch (e) {
      print("❌ JSON Parsing Error fetchGetassignedusersforReopen: $e");
      throw Exception('Failed to load assigned users');
    }
  }

  // Fetch FatchSiteObservationSafetyByUserID list
  Future<List<SiteObservation>> fatchSiteObservationSafetyByUserID(
      int? userID) async {
    try {
      print("Fetching safety observations for userID: $userID");

      final response = await ApiClient.dio.get(
        '/api/SiteObservation/GetSiteObservationSafetyByUserID/$userID',
      );

      final List<dynamic> jsonData =
          response.data is String ? jsonDecode(response.data) : response.data;

      print("Decoded JSON: $jsonData");

      if (jsonData.isEmpty) {
        print('⚠️ No safety observations found');
        return [];
      }

      return jsonData.map((item) => SiteObservation.fromJson(item)).toList();
    } catch (e) {
      print("❌ Error fetching safety observations: $e");
      throw Exception('Failed to load safety observations');
    }
  }

  Future<List<SiteObservation>> fatchSiteObservationQualityByUserID(
      int? userID) async {
    try {
      print("Fetching quality observations for userID: $userID");

      final response = await ApiClient.dio.get(
        '/api/SiteObservation/GetSiteObservationQualityByUserID/$userID',
      );

      final List<dynamic> jsonData =
          response.data is String ? jsonDecode(response.data) : response.data;

      print("Decoded JSON: $jsonData");

      if (jsonData.isEmpty) {
        print('⚠️ No quality observations found');
        return [];
      }

      return jsonData.map((item) => SiteObservation.fromJson(item)).toList();
    } catch (e) {
      print("❌ Error fetching quality observations: $e");
      throw Exception('Failed to load quality observations');
    }
  }

  Future<List<SectionModel>> getSectionsByProjectID(int projectID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ProjectSectionMapping/GetSectionsByProjectID/$projectID',
      );

      final decoded =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (decoded is List) {
        return decoded.map((json) => SectionModel.fromJson(json)).toList();
      } else if (decoded is Map && decoded.containsKey('value')) {
        final data = decoded['value'] as List<dynamic>;
        return data.map((json) => SectionModel.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for sections');
      }
    } catch (e) {
      print("❌ Error fetching sections: $e");
      throw Exception('Failed to load sections');
    }
  }

  Future<List<FloorModel>> getFloorByProjectID(int projectID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ProjectFloorMapping/GetFloorsByProjectID/$projectID',
      );

      final decoded =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (decoded is List) {
        return decoded.map((json) => FloorModel.fromJson(json)).toList();
      } else if (decoded is Map && decoded.containsKey('value')) {
        final data = decoded['value'] as List<dynamic>;
        return data.map((json) => FloorModel.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for floors');
      }
    } catch (e) {
      print("❌ Error fetching floors: $e");
      throw Exception('Failed to load floors');
    }
  }

  Future<List<PourModel>> getPourByProjectID(int projectID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ProjectPartMapping/GetPartsByProjectID/$projectID',
      );

      final decoded =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (decoded is List) {
        return decoded.map((json) => PourModel.fromJson(json)).toList();
      } else if (decoded is Map && decoded.containsKey('value')) {
        final data = decoded['value'] as List<dynamic>;
        return data.map((json) => PourModel.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for pours');
      }
    } catch (e) {
      print("❌ Error fetching pours: $e");
      throw Exception('Failed to load pours');
    }
  }

  Future<List<ElementModel>> getElementByProjectID(int projectID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ProjectElementMapping/GetElementsByProjectID/$projectID',
      );

      final decoded =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (decoded is List) {
        return decoded.map((json) => ElementModel.fromJson(json)).toList();
      } else if (decoded is Map && decoded.containsKey('value')) {
        final data = decoded['value'] as List<dynamic>;
        return data.map((json) => ElementModel.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected response format for elements');
      }
    } catch (e) {
      print("❌ Error fetching elements: $e");
      throw Exception('Failed to load elements');
    }
  }

  Future<List<NotificationModel>> getNotificationsByUserID(int userID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/Notification/GetNotificationByUserID/$userID',
      );

      // Response ko decode karo agar string hai
      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (data is List) {
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else if (data is Map && data.containsKey('value')) {
        final List<dynamic> notifications = data['value'];
        return notifications
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Unexpected response format for notifications');
      }
    } catch (e) {
      print('❌ Failed to fetch notifications: $e');
      throw Exception('Failed to fetch notifications');
    }
  }

//   Future<bool> deleteNotification(
//       String notificationId, int userId, int deviceId) async {
//     try {
//       final response = await ApiClient.dio.put(
//         '/api/Notification/UpdateNotificationReadFlag/$notificationId/$userId/$deviceId',
//       );

//       if (response.statusCode == 200 || response.statusCode == 204) {
//         // 204 ka matlab hai body empty, direct true
//         if (response.statusCode == 204) return true;

//         final decoded =
//             response.data is String ? jsonDecode(response.data) : response.data;
//         if (decoded is bool) return decoded;
//         if (response.data.toString().toLowerCase() == 'true') return true;
//         return false;
//       } else {
//         print('❌ Failed to delete notification: ${response.statusCode}');
//         return false;
//       }
//     } catch (e) {
//       print('❌ Error deleting notification: $e');
//       return false;
//     }
//   }
// }
  Future<bool> deleteNotification(
      String notificationId, int userId, int deviceId) async {
    String? token = await SharedPrefsHelper.getToken();

    final url = Uri.parse(
        'https://d94acvrm8bvo5.cloudfront.net/api/Notification/UpdateNotificationReadFlag/$notificationId/$userId/$deviceId');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token', // Agar token required hai to
        'Content-Type': 'application/json',
      },
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 204) {
      // 204 ke case me body empty hota hai, to directly true return karo
      if (response.statusCode == 204) {
        return true;
      }
      // Agar 200 hai to existing logic
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is bool) return decoded;
        if (response.body.toLowerCase() == 'true') return true;
        return false;
      } catch (e) {
        print('Error decoding response: $e');
        return false;
      }
    } else {
      return false;
    }
  }
}
