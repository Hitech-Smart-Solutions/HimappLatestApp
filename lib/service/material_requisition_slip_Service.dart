import 'package:himappnew/model/material_requisition_slip_model.dart';
import 'package:himappnew/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class MaterialRequisitionSlipService {
  Future<List<MaterialIssue>> fetchMaterialIssueRequestByProjectID({
    required int projectId,
    String sortColumn = 'ID Desc',
    int pageIndex = 0,
    int pageSize = 10,
    bool isActive = true,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/MaterialIssueRequest/GetMaterialIssueRequestByProjectID',
        queryParameters: {
          'ProjectID': projectId,
          'SortColumn': sortColumn,
          'PageIndex': pageIndex,
          'PageSize': pageSize,
          'IsActive': isActive,
        },
      );

      final rawData = response.data;

      // ✅ Safety: decode if String
      final Map<String, dynamic> data =
          rawData is String ? jsonDecode(rawData) : rawData;

      final table1 = data['Table1'];

      // ✅ MOST IMPORTANT GUARD
      if (table1 == null || table1 is! List) {
        print("⚠️ Table1 empty or not List => $table1");
        return [];
      }

      return table1
          .map((e) => MaterialIssue.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      print("❌ MATERIAL ISSUE API ERROR => $e");
      print("📍 STACK TRACE => $s");
      rethrow;
    }
  }

  Future<List<SectionModel>> getSectionsByProjectID(int projectId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ProjectSectionMapping/GetSectionsByProjectID/$projectId',
      );
      if (response.statusCode == 200) {
        final List list = response.data['value'] ?? [];
        return list.map((e) => SectionModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      print("❌ SECTION API ERROR => $e");
      return [];
    }
  }

  Future<List<FloorModel>> getFloorByProjectID(int projectId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/ProjectFloorMapping/GetFloorsByProjectID/$projectId',
      );

      // print("🟢 FLOOR API STATUS => ${response.statusCode}");

      if (response.statusCode == 200) {
        final List list = response.data['value'] ?? [];
        return list.map((e) => FloorModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("❌ FLOOR API ERROR => $e");
      return [];
    }
  }

  Future<List<EmployeeModel>> getEmployees({
    required String search,
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/MaterialIssueRequest/GetEmployeesForDropdown',
        queryParameters: {
          'search': search,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );

      final List list = response.data['data'] ?? [];

      return list.map((e) => EmployeeModel.fromJson(e)).toList();
    } catch (e) {
      print("❌ EMPLOYEE API ERROR => $e");
      return [];
    }
  }

  Future<List<ContractorModel>> getVendors({
    required String search,
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/MaterialIssueRequest/GetVendorsForDropdown',
        queryParameters: {
          'search': search,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );

      final List list = response.data['data'] ?? [];
      return list.map((e) => ContractorModel.fromJson(e)).toList();
    } catch (e) {
      print("❌ CONTRACTOR API ERROR => $e");
      return [];
    }
  }

  // Future<List<ItemModel>> getReleasedProducts({
  //   required String search,
  //   required int pageNumber,
  //   required int pageSize,
  // }) async {
  //   try {
  //     final response = await ApiClient.dio.get(
  //       '/api/MaterialIssueRequest/GetReleasedProductsDropdown',
  //       queryParameters: {
  //         'search': search,
  //         'pageNumber': pageNumber,
  //         'pageSize': pageSize,
  //       },
  //     );

  //     final List list = response.data['data'] ?? [];

  //     return list.map((e) => ItemModel.fromJson(e)).toList();
  //   } catch (e) {
  //     print("❌ ITEM API ERROR => $e");
  //     return [];
  //   }
  // }

  Future<List<ItemModel>> getReleasedProducts({
    required String search,
    required int pageNumber,
    required int pageSize,
    required int projectID,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/MaterialIssueRequest/GetReleasedProductsDropdown',
        queryParameters: {
          'search': search,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
          'projectID': projectID, // ✅ IMPORTANT
        },
      );

      final List list = response.data['data'] ?? [];
      return list.map((e) => ItemModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ItemModel?> getItemById(int itemId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/MaterialIssueRequest/GetItemById',
        queryParameters: {'itemId': itemId},
      );

      return ItemModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<EquipmentModel>> getEquipment({
    required String search,
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/MaterialIssueRequest/GetEquipmentForDropdown',
        queryParameters: {
          'search': search,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );

      final List list = response.data['data'] ?? [];
      return list.map((e) => EquipmentModel.fromJson(e)).toList();
    } catch (e) {
      print("❌ EQUIPMENT API ERROR => $e");
      return [];
    }
  }

  Future<List<ActivityModel>> getActivities({
    required String search,
    required int projectID,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/MaterialIssueRequest/GetWBSActivityForDropdown',
        queryParameters: {
          'search': search.trim().isEmpty ? "" : search.trim(),
          'pageNumber': 1,
          'pageSize': 10000,
          'projectID': projectID,
        },
      );

      // print("PROJECT SENT => $projectID");
      // print("SEARCH SENT => '$search'");
      // print("ACTIVITY API RESPONSE => ${response.data}");

      final List list = response.data['data'] ?? [];

      return list.map((e) => ActivityModel.fromJson(e)).toList();
    } catch (e) {
      print("❌ ACTIVITY API ERROR => $e");
      return [];
    }
  }

  Future<bool> submitMaterialIssue(MaterialIssueRequest request) async {
    try {
      final payload = request.toJson();

      debugPrint("===== MRIS API PAYLOAD =====");
      debugPrint(payload.toString());

      final response = await ApiClient.dio.post(
        '/api/MaterialIssueRequest/CreateMaterialIssue',
        data: payload,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
        debugPrint("❌ STATUS: ${e.response?.statusCode}");
        debugPrint("❌ DATA: ${e.response?.data}");
        debugPrint("❌ HEADERS: ${e.response?.headers}");
      } else {
        debugPrint("❌ ERROR: $e");
      }
      rethrow;
    }
  }

  /// 🔹 UPDATE (Angular: updateMaterialIssue)
  Future<bool> updateMaterialIssue(MaterialIssueRequest request) async {
    try {
      final response = await ApiClient.dio.put(
        '/api/MaterialIssueRequest/UpdateMaterialIssue',
        data: request.toJson(),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      return false;
    }
  }

  /// 🔹 APPROVE (Angular: ChangeApproval)
  Future<bool> approveMRIS(Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/MaterialIssueRequest/ChangeApproval',
        data: payload,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      return false;
    }
  }

  /// 🔹 DISAPPROVE (Angular: DisapproveMris)
  Future<bool> disapproveMRIS(Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/MaterialIssueRequest/DisapproveMris',
        data: payload,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      return false;
    }
  }

  Future<double> getAvailableQuantityByProject(
      int projectId, int itemId) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/MaterialIssueRequest/GetAvailableQuantityByProjectAsync/$projectId/$itemId',
      );

      print("AVAILABLE QTY RAW RESPONSE => ${response.data}");

      return (response.data['availableQuantity'] ?? 0).toDouble();
    } catch (e) {
      print("❌ Available Qty API Error: $e");
      return 0;
    }
  }

  Future<List<dynamic>> getMaterialIssuesAwaitingApproval(
    int userId,
    int programId,
  ) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/MaterialIssueRequest/GetMaterialIssuesAwaitingApproval/$userId/$programId',
      );

      if (response.data != null && response.data['table1'] != null) {
        return List.from(response.data['table1']);
      }

      return [];
    } catch (e) {
      debugPrint('❌ API Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMaterialIssueById(
    int id,
    int programId,
  ) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/MaterialIssueRequest/GetMaterialIssueByID/$id/$programId',
      );
      return response.data;
    } catch (e) {
      debugPrint("❌ Get By ID Error: $e");
      return null;
    }
  }

  // Future<List<dynamic>> getMaterialIssuesAwaitingApproval(
  //   int userId,
  //   int programId,
  // ) async {
  //   final response = await ApiClient.dio.get(
  //     '/api/MaterialIssueRequest/GetMaterialIssuesAwaitingApproval/$userId/$programId',
  //   );

  //   if (response.statusCode == 200) {
  //     final body = response.data; // ✅ YAHI FIX HAI
  //     return body['table1'] ?? []; // 🔥 list
  //   } else {
  //     throw Exception("Failed to load awaiting approvals");
  //   }
  // }

  Future<List<dynamic>> getMrisApprovalHistory({
    required int id,
    required int programId,
  }) async {
    final response = await ApiClient.dio.get(
      '/api/MaterialIssueRequest/GetMrisApprovalHistory',
      queryParameters: {
        'id': id,
        'programId': programId,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;

      // 🔥 YAHI MAIN FIX HAI
      return data['table1'] ?? [];
    } else {
      throw Exception("Failed to load history");
    }
  }
}
