import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:himappnew/model/observation_summary_Model.dart';
import 'package:himappnew/model/observation_summary_Model.dart';
import 'package:himappnew/network/api_client.dart';

class ObservationSummaryService {
  Future<List<Project>> fetchProjects(
    int companyId,
    int userId,
  ) async {
    final response = await ApiClient.dio.get(
      '/api/ProjectMaster/GetProjectsByUserRoleMappingAndCompanyID/$companyId/$userId',
    );

    final data =
        response.data is String ? jsonDecode(response.data) : response.data;

    return (data as List).map((e) => Project.fromJson(e)).toList();
  }

  Future<List<ObservationSummary>> getObservationSummary(
    int functionId,
    List<int> projectIds,
  ) async {
    final response = await ApiClient.dio.get(
      '/api/DashboardObservation/GetSiteObservationSummaryForProject/$functionId',
      queryParameters: {
        "projectId": projectIds,
      },
    );

    // print("REQUEST URL: ${response.realUri}");
    // print("RAW API RESPONSE:");
    // print(response.data);

    final data =
        response.data is String ? jsonDecode(response.data) : response.data;

    final List list = data['value']['projectObservationSummary'] ?? [];

    return list.map((json) => ObservationSummary.fromJson(json)).toList();
  }

  Future<List<ObservationTrendMonth>> getLastSixMonthObservationSummary(
    int functionId,
    List<int> projectIds,
  ) async {
    try {
      // print("API CALL → functionId: $functionId");
      // print("API CALL → projectIds: $projectIds");

      final response = await ApiClient.dio.get(
        '/api/DashboardObservation/GetSiteObservationLastSixMonthSummaryForProject/$functionId',
        queryParameters: {"projectId": projectIds},
      );
      // print("REQUEST URL → ${response.requestOptions.uri}");
      // print("FULL RESPONSE → ${response.data}");

      final data = response.data['value']
              ['projectObservationLastSixMonthSummary'] as List<dynamic>? ??
          [];

      print("LIST LENGTH → ${data.length}");

      return data.map((e) => ObservationTrendMonth.fromJson(e)).toList();
    } catch (e) {
      print("API ERROR → $e");
      rethrow;
    }
  }

  Future<List<CategoryTrend>> getLastSixMonthCategorySummary(
    int functionId,
    List<int> projectIds,
  ) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/DashboardObservation/GetSiteObservationLastSixMonthCategorySummaryForProject/$functionId',
        queryParameters: {"projectId": projectIds},
      );

      // print("REQUEST URL → ${response.requestOptions.uri}");
      // print("FULL CATEGORY RESPONSE → ${response.data}");

      final List list = response.data['value']
          ['projectObservationLastSixMonthCategorySummary'];

      // print("CATEGORY LIST LENGTH → ${list.length}");

      // for (var e in list) {
      //   print("RAW ITEM → $e");
      // }

      return list.map((e) => CategoryTrend.fromJson(e)).toList();
    } catch (e) {
      print("❌ Category Chart API Error: $e");
      return [];
    }
  }
}
