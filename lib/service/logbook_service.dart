import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:himappnew/model/logbook_model.dart';
import '../network/api_client.dart';
import '../shared_prefs_helper.dart';

class LogbookService {
  // Future<Map<String, dynamic>> getOperatorLogBookByProjectID(
  //     Map<String, dynamic> params) async {
  //   try {
  //     final response = await ApiClient.dio.get(
  //       '/api/LogBook/GetOperatorLogBookByProjectID',
  //       queryParameters: params,
  //     );

  //     final data =
  //         response.data is String ? jsonDecode(response.data) : response.data;

  //     return data;
  //   } catch (e) {
  //     print("❌ API Error: $e");
  //     throw Exception("Failed to load logbook");
  //   }
  // }

  Future<List<LogBookModal>> getOperatorLogBookByProjectID({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 100,
    bool isActive = true,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/LogBook/GetOperatorLogBookByProjectID',
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

      // print("🔥 FULL RESPONSE: $data");

      final List<dynamic> table1 = data['table1'] ?? [];

      // print("🔥 TABLE1 LENGTH: ${table1.length}");

      return table1.map((e) => LogBookModal.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load logbook');
    }
  }

  Future<List<EquipmentModel>> getAssetMastersByProjectID(int projectId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/LogBook/GetAssetMasterByProjectId/$projectId', // ✅ FIXED
      );

      final data = response.data;
      // print("🔥 Equipment API: $data");

      return (data as List).map((e) => EquipmentModel.fromJson(e)).toList();
    } catch (e) {
      print("❌ API Error: $e");
      return [];
    }
  }

  Future<List<AssetTypeModel>> getAllAssetTypes() async {
    try {
      final response = await ApiClient.dio.get(
        '/api/LogBook/GetAllAssetTypesAsync', // 🔥 FIXED
      );

      final data = response.data;

      // print("🔥 AssetType API: $data");

      return (data as List).map((e) => AssetTypeModel.fromJson(e)).toList();
    } catch (e) {
      print("❌ AssetType API Error: $e");
      return [];
    }
  }

  Future<List<Operator>> getItemsForUsersDropdown(
      String search, int pageIndex, int pageSize) async {
    final response = await ApiClient.dio.get(
      "/api/UserMaster/dropdown",
      queryParameters: {
        "search": search,
        "pageIndex": pageIndex,
        "pageSize": pageSize,
      },
    );
    // print("API RESPONSE => ${response.data}");
    return (response.data as List).map((e) => Operator.fromJson(e)).toList();
  }

  Future<List<dynamic>> getReadingsByObjectType(int objectTypeId) async {
    try {
      final response = await ApiClient.dio.get(
        "/api/LogBook/GetReadingsByObjectType/$objectTypeId",
      );

      // print("🔥 API RESPONSE => ${response.data}");

      return response.data as List;
    } catch (e) {
      print("❌ Error getReadingsByObjectType: $e");
      return [];
    }
  }

  Future<double> getLastClosingReading(int equipmentId, int readingId) async {
    try {
      final response = await ApiClient.dio.get(
        "/api/LogBook/GetLastClosingReadingAsync/$equipmentId/$readingId",
      );

      // 🔥 Dio me body nahi hota → response.data hota hai
      final data = response.data;

      // direct number ya string handle
      return double.tryParse(data.toString()) ?? 0;
    } catch (e) {
      print("Error in getLastClosingReading: $e");
      return 0;
    }
  }

  // getWorkDescriptionsByCategoryId(objectTypeId: any): Observable<any> {
  //   return this.http.get(`${this.BASE_URL}GetWorkDescriptionsByObjectType/${objectTypeId}`);
  // }

  Future<List<WorkDescription>> getWorkDescriptionsByCategoryId(
      int objectTypeId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/LogBook/GetWorkDescriptionsByObjectType/$objectTypeId', // ✅ FIXED
      );

      final data = response.data;
      // print("🔥 Equipment API: $data");

      return (data as List).map((e) => WorkDescription.fromJson(e)).toList();
    } catch (e) {
      print("❌ API Error: $e");
      return [];
    }
  }

  Future<List<BreakDownReason>> getBreakDownReasons(int objectTypeId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/LogBook/GetBreakDownReasonsbyObjectTypeID/$objectTypeId', // ✅ correct API
      );

      final data = response.data;

      return (data as List).map((e) => BreakDownReason.fromJson(e)).toList();
    } catch (e) {
      print("❌ API Error: $e");
      return [];
    }
  }

  Future<List<BreakDownReason>> getInHouseMaintenance(int objectTypeId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/LogBook/GetInHouseMaintenanceByObjectTypeID/$objectTypeId', // ✅ correct API
      );

      final data = response.data;

      return (data as List).map((e) => BreakDownReason.fromJson(e)).toList();
    } catch (e) {
      print("❌ API Error: $e");
      return [];
    }
  }

  Future<List<UomModel>> getUomDropdown() async {
    try {
      final response = await ApiClient.dio.get(
        '/api/LogBook/GetUomDropdown',
      );

      final data = response.data;

      return (data as List).map((e) => UomModel.fromJson(e)).toList();
    } catch (e) {
      print("❌ API Error: $e");
      return [];
    }
  }

  Future<List<AssetCounter>> getAllAssetCounters() async {
    try {
      final response =
          await ApiClient.dio.get('/api/LogBook/GetAllAssetCounters');

      final data = response.data;

      return (data as List).map((e) => AssetCounter.fromJson(e)).toList();
    } catch (e) {
      print("❌ Error fetching counters: $e");
      return [];
    }
  }

  Future<List<RmType>> getRmTypes() async {
    try {
      final response = await ApiClient.dio.get('/api/LogBook/GetRMTypes');

      final data = response.data;

      return (data as List).map((e) => RmType.fromJson(e)).toList();
    } catch (e) {
      print("❌ Error fetching RM Types: $e");
      return [];
    }
  }

  // Future<bool> createLogBook(LogBookModal logBook) async {
  //   try {
  //     final response = await ApiClient.dio.post(
  //       '/api/LogBook/CreateLogBook',
  //       data: logBook.toJson(),
  //     );

  //     print("📦 Create Response: ${response.data}");

  //     return response.statusCode == 200 || response.statusCode == 201;
  //   } catch (e) {
  //     print('❌ Create Error: $e');
  //     throw e.toString();
  //   }
  // }
  Future<bool> createLogBook(LogBookModal logBook) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/LogBook/CreateLogBook',
        data: logBook.toJson(),
      );
      print("response: $response");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error occurred: $e');
      throw e.toString();
    }
  }

  /// ✅ UPDATE LOGBOOK
  Future<bool> updateLogBook(LogBookModal logBook) async {
    try {
      if (logBook.id == null) {
        throw "ID is required for update";
      }

      final response = await ApiClient.dio.put(
        '/api/LogBook/UpdateOperatorLogBook/${logBook.id}',
        data: logBook.toJson(),
      );

      print("📦 Update Response: ${response.data}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Update Error: $e');
      throw e.toString();
    }
  }

  Future<LogBookModal> getOperatorLogBookByID(int id) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/LogBook/GetOperatorLogBookByID/$id',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      // If API returns single object directly
      return LogBookModal.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load logbook by ID');
    }
  }
}
