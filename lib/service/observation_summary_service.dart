import 'dart:convert';
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
    final query = projectIds.map((e) => 'projectId=$e').join('&');

    final response = await ApiClient.dio.get(
      '/api/DashboardObservation/GetSiteObservationSummaryForProject/$functionId?$query',
    );

    final data =
        response.data is String ? jsonDecode(response.data) : response.data;

    final List list = data['value']['projectObservationSummary'] ?? [];

    return list.map((json) => ObservationSummary.fromJson(json)).toList();
  }
}
