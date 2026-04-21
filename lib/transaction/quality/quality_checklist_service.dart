import 'dart:convert';
import 'package:himappnew/model/quality_checklist.dart';
import 'package:himappnew/network/api_client.dart';
import 'package:himappnew/shared_prefs_helper.dart';

class QualityChecklistService {
  Future<List<QualityChecklist>> fetchQualityChecklists({
    required int projectId,
    String sortColumn = 'ID desc',
    int pageIndex = 0,
    int pageSize = 100,
    bool isActive = true,
  }) async {
    try {
      // print(projectId);

      final response = await ApiClient.dio.get(
        '/api/CheckList/GetQualityCheckListByProjectID',
        queryParameters: {
          'ProjectID': projectId,
          'SortColumn': sortColumn,
          'PageIndex': pageIndex,
          'PageSize': pageSize,
          'IsActive': isActive,
        },
      );

      // print("Response status code: ${response.statusCode}");

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> table1 = data['Value']['Table1'];

      return table1.map((e) => QualityChecklist.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load quality checklists');
    }
  }

  Future<List<ChecklistMapping>> fetchChecklistMapping() async {
    try {
      int? projectId = await SharedPrefsHelper.getProjectID();

      final response = await ApiClient.dio.get(
        '/api/CheckListProjectMapping/GetCheckListProjectMappingByProjectID',
        queryParameters: {
          'ProjectID': projectId,
          'FilterColumn': '',
          'FilterValue': '',
          'SortColumn': 'ID ASC',
          'PageIndex': 0,
          'PageSize': 100,
          'IsActive': true,
        },
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List<dynamic> table1 = data['Value']['Table1'];

      /// 🔥 FILTER + EMPTY TEXT REMOVE
      return table1
          .map((e) => ChecklistMapping.fromJson(e))
          .where((item) =>
              item.isVisible == true &&
              item.checklistFor.isNotEmpty) // 👈 important
          .toList();
    } catch (e) {
      throw Exception('Failed to load checklist mapping');
    }
  }

  Future<dynamic> getChecklistMappingById(int id) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/CheckListProjectMapping/GetCheckListProjectMapping/$id',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      return data;
    } catch (e) {
      throw Exception('Failed to load checklist mapping by ID');
    }
  }

  Future<List<AreaModel>> fetchAreas() async {
    int? projectId = await SharedPrefsHelper.getProjectID();

    final response = await ApiClient.dio.get(
      '/api/ProjectSectionMapping/GetSectionsByProjectID/$projectId',
    );

    final data =
        response.data is String ? jsonDecode(response.data) : response.data;

    final List list = data['value'] ?? [];

    return list.map((e) => AreaModel.fromJson(e)).toList();
  }

  Future<List<ElementModel>> fetchElements() async {
    int? projectId = await SharedPrefsHelper.getProjectID();

    final response = await ApiClient.dio.get(
      '/api/ProjectElementMapping/GetElementsByProjectID/$projectId',
    );

    final data =
        response.data is String ? jsonDecode(response.data) : response.data;

    final List list = data['value'] ?? [];

    return list.map((e) => ElementModel.fromJson(e)).toList();
  }

  Future<List<FloorModel>> fetchFloors() async {
    try {
      int? projectId = await SharedPrefsHelper.getProjectID();

      final response = await ApiClient.dio.get(
        '/api/ProjectFloorMapping/GetFloorsByProjectID/$projectId',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List list = data['value'] ?? [];

      return list.map((e) => FloorModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load floors');
    }
  }

  Future<List<PartModel>> fetchParts() async {
    try {
      int? projectId = await SharedPrefsHelper.getProjectID();

      final response = await ApiClient.dio.get(
        '/api/ProjectPartMapping/GetPartsbyProjectID/$projectId',
      );

      final data =
          response.data is String ? jsonDecode(response.data) : response.data;

      final List list = data['value'] ?? [];

      return list.map((e) => PartModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load parts');
    }
  }

  Future<List<dynamic>> getSectionList(int mappingId) async {
    // final response = await ApiClient.dio.get(
    //   Uri.parse(
    //       "$baseUrl/api/CheckListProjectMapping/GetSectionListFromCheckListProjectMapping/$mappingId"),
    // );

    final response = await ApiClient.dio.get(
      '/api/CheckListProjectMapping/GetSectionListFromCheckListProjectMapping/$mappingId',
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception("Failed to load section list");
    }
  }
}
