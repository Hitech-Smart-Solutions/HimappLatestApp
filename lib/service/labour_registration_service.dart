import 'dart:convert';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:http/http.dart' as http;
import 'package:himappnew/model/labour_registration_model.dart';
import 'package:himappnew/network/api_client.dart';

class LabourRegistrationService {
  Future<List<LabourModel>> fetchLabours({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 10,
    bool isActive = true,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/LabourRegistration/GetLabourRegistrationByProjectID',
        queryParameters: {
          'ProjectID': projectId,
          'SortColumn': sortColumn,
          'PageIndex': pageIndex,
          'PageSize': pageSize,
          'IsActive': isActive,
        },
      );

      /// 🔒 SAFE parsing (String / Map both supported)
      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> table1 = data['Value']['Table1'];

      return table1.map((e) => LabourModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load labours: $e');
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
    try {
      final response = await ApiClient.dio.get(
        '/api/LabourCategoryType/GetLabourCategories',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (data is List) {
        return data.map((item) => LabourTypeModel.fromJson(item)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      throw Exception('Failed to load labour types: $e');
    }
  }

  //country list

  Future<List<CountriesModel>> fetchCountries() async {
    try {
      final response = await ApiClient.dio.get(
        '/api/Country/GetCountries',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (data is List) {
        if (data.isEmpty) {
          print('No activities found');
        }

        return data.map((item) => CountriesModel.fromJson(item)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print("Error parsing the JSON data: $e");
      throw Exception('Failed to load Observation');
    }
  }

  //State list

  Future<List<StateModel>> fetchState(int CountryID) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/State/GetStatesByCountryID/$CountryID',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (data is List) {
        if (data.isEmpty) {
          print('No activities found');
        }

        return data.map((item) => StateModel.fromJson(item)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print("Error parsing the JSON data: $e");
      throw Exception('Failed to load Observation');
    }
  }

  // City List

  Future<List<CityModel>> fetchCities(int stateId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/State/GetCitiesByStateID/$stateId',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (data is List) {
        return data.map((item) => CityModel.fromJson(item)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      throw Exception('Failed to load cities');
    }
  }

  Future<bool> submitLabourRegistration(LabourRegistration data) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/LabourRegistration/CreateLabourRegistrationMaster',
        data: data.toJson(),
      );

      // Dio me success status pe response aata hai
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Registration successful');
        return true;
      } else {
        print('❌ Error: ${response.statusCode}');
        print('Body: ${response.data}');
        return false;
      }
    } catch (e) {
      print('❌ Error submitting registration: $e');
      return false;
    }
  }

  Future<bool> updateLabourRegistration(LabourRegistration data) async {
    try {
      print("Labour ID: ${data.id}");

      final response = await ApiClient.dio.put(
        '/api/LabourRegistration/UpdateLabourRegistrationByID/${data.id}',
        data: data.toJson(),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        print('✅ Labour Registration Update successful');
        return true;
      } else {
        print('❌ Error: ${response.statusCode}');
        print('Body: ${response.data}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating labour registration: $e');
      return false;
    }
  }

  Future<LabourRegistration> getLabourById(int id) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/LabourRegistration/GetLabourRegistrationMasterById/$id',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      print('Raw API Response: $data');
      print("API Response: $data");

      final valueData = data['value']; // same as before

      if (valueData != null) {
        print("Full Name: ${valueData['fullName']}");
        print("Contact No: ${valueData['contactNo']}");
        return LabourRegistration.fromJson(valueData);
      } else {
        throw Exception("No data found for labour ID $id");
      }
    } catch (e) {
      throw Exception('Failed to load Labour Registration');
    }
  }
}
