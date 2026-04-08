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

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      /// ✅ DIRECT ACCESS (correct)
      final table1 = data['Table1'];

      if (table1 is List) {
        if (table1.isEmpty) {
          print("⚠️ No data found");
          return [];
        }

        return table1.map((e) => MaterialIssue.fromJson(e)).toList();
      }

      print("❌ Table1 not found or invalid");
      return [];
    } catch (e, s) {
      print("❌ MATERIAL ISSUE API ERROR => $e");
      print("📍 STACK TRACE => $s");
      return [];
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
      debugPrint(const JsonEncoder.withIndent('  ').convert(payload));

      final response = await ApiClient.dio.post(
        '/api/MaterialIssueRequest/CreateMaterialIssue',
        data: payload,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint("❌ STATUS: ${e.response?.statusCode}");
      debugPrint("❌ DATA: ${e.response?.data}");

      // 🔥 THROW ONLY RESPONSE DATA
      throw e.response?.data;
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      throw {"error": "Something went wrong"};
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
      final data =
          response.data is String ? jsonDecode(response.data) : response.data;
      final table1 = data['table1'];

      if (table1 == null || table1 is! List) {
        print("❌ table1 missing or not a List");
        return [];
      }

      return List.from(table1);
    } catch (e, stack) {
      print("❌ API ERROR");
      print(e);
      print(stack);
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
      final data =
          response.data is String ? jsonDecode(response.data) : response.data;
      if (data == null) return null;
      return data; // raw return (safe)
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
