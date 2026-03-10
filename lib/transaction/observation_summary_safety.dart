import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:himappnew/model/observation_summary_Model.dart';
import 'package:himappnew/service/observation_summary_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';

/// 🔹 API CLIENT (Simple demo)
// class ApiClient {
//   static final Dio dio = Dio(
//     BaseOptions(
//       baseUrl: 'https://YOUR_BASE_URL_HERE', // 🔴 change this
//       connectTimeout: const Duration(seconds: 30),
//       receiveTimeout: const Duration(seconds: 30),
//     ),
//   );
// }

/// 🔹 MODEL: API se jo data aata hai
// class ObservationSummary {
//   final String stage;
//   final int overdueCount;
//   final int dueCount;
//   final int totalCount;

//   ObservationSummary({
//     required this.stage,
//     required this.overdueCount,
//     required this.dueCount,
//     required this.totalCount,
//   });

//   factory ObservationSummary.fromJson(Map<String, dynamic> json) {
//     return ObservationSummary(
//       stage: json['stage'] ?? '',
//       overdueCount: json['overdue_count'] ?? 0,
//       dueCount: json['due_count'] ?? 0,
//       totalCount: json['total_count'] ?? 0,
//     );
//   }
// }

/// 🔹 TABLE ke liye model
// class ObservationTableRow {
//   final String stage;
//   final int overdue;
//   final int due;
//   final int total;

//   ObservationTableRow({
//     required this.stage,
//     required this.overdue,
//     required this.due,
//     required this.total,
//   });
// }

/// 🔹 SERVICE
// class ObservationService {
//   Future<List<ObservationSummary>> getObservationSummary(
//     int functionId,
//     List<int> projectIds,
//   ) async {
//     final query = projectIds.map((e) => 'projectId=$e').join('&');

//     final response = await ApiClient.dio.get(
//       '/api/DashboardObservation/GetSiteObservationSummaryForProject/$functionId?$query',
//     );

//     final data =
//         response.data is String ? jsonDecode(response.data) : response.data;

//     final List list = data['value']['projectObservationSummary'] ?? [];

//     return list.map((e) => ObservationSummary.fromJson(e)).toList();
//   }
// }

/// 🔹 MAIN SCREEN
class ObservationSummarySafety extends StatefulWidget {
  const ObservationSummarySafety({super.key});

  @override
  State<ObservationSummarySafety> createState() =>
      _ObservationSummarySafetyState();
}

class _ObservationSummarySafetyState extends State<ObservationSummarySafety> {
  final ObservationSummaryService _service = ObservationSummaryService();

  bool isLoading = false;
  List<Project> projectData = [];
  bool dropdownOpen = false;

  /// 🔴 Demo IDs (API ke hisaab se change karo)
  int functionId = 1;
  List<int> selectedProjectIds = [1, 2];

  List<ObservationTableRow> tableData = [];

  void onCheckboxChange(int projectId, bool isChecked) {
    setState(() {
      if (isChecked) {
        selectedProjectIds.add(projectId);
      } else {
        selectedProjectIds.remove(projectId);
      }
    });

    // 🔥 PROJECT CHANGE → SUMMARY REFRESH
    fetchSummary();
  }

  @override
  void initState() {
    super.initState();

    fetchProjectData();
    fetchSummary();
  }

  Future<void> fetchProjectData() async {
    final userId =
        await SharedPrefsHelper.getUserId(); // tumhara existing method
    final companyId = await SharedPrefsHelper.getCompanyId();

    final projects = await _service.fetchProjects(companyId!, userId!);

    print('✅ Projects count: ${projects.length}');
    print('✅ Projects data: $projects');

    setState(() {
      projectData = projects;

      // ✅ SELECT ALL PROJECTS BY DEFAULT
      selectedProjectIds = projectData.map((p) => p.id).toList();
    });

    // ✅ Trigger summary load
    fetchSummary();
  }

  /// 🔹 API CALL
  Future<void> fetchSummary() async {
    setState(() => isLoading = true);

    try {
      final data = await _service.getObservationSummary(
        functionId,
        selectedProjectIds,
      );

      tableData = buildTable(data);
    } catch (e) {
      debugPrint('❌ Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔹 Angular ka buildTable yaha
  List<ObservationTableRow> buildTable(List<ObservationSummary> data) {
    final rows = data.map((d) {
      return ObservationTableRow(
        stage: d.stage,
        overdue: d.overdueCount,
        due: d.dueCount,
        total: d.totalCount,
      );
    }).toList();

    final totalRow = ObservationTableRow(
      stage: 'Total',
      overdue: rows.fold(0, (s, r) => s + r.overdue),
      due: rows.fold(0, (s, r) => s + r.due),
      total: rows.fold(0, (s, r) => s + r.total),
    );

    return [...rows, totalRow];
  }

  Widget projectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => dropdownOpen = !dropdownOpen);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedProjectIds.length == projectData.length
                      ? 'All Projects'
                      : '${selectedProjectIds.length} Selected',
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (dropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView(
              shrinkWrap: true,
              children: projectData.map((p) {
                return CheckboxListTile(
                  dense: true,
                  value: selectedProjectIds.contains(p.id),
                  onChanged: (val) {
                    onCheckboxChange(p.id, val ?? false);
                  },
                  title: Text(
                    p.projectName,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Observation Summary'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔽 PROJECT DROPDOWN (YAHI AAYEGA)
                  projectDropdown(),

                  const SizedBox(height: 12),

                  // 📊 OBSERVATION TABLE
                  tableData.isEmpty
                      ? const Center(child: Text('No Data Found'))
                      : Expanded(child: observationTable()),
                ],
              ),
            ),
    );
  }

  /// 🔹 TABLE UI
  Widget observationTable() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            children: [
              headerRow(),
              ...tableData.map((row) => dataRow(row)),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// 🔹 Header
  TableRow headerRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        _ObservationSummarySafetyState.tableCell(
          'Stage',
          bold: true,
        ),
        _ObservationSummarySafetyState.tableCell(
          'Overdue',
          bold: true,
        ),
        _ObservationSummarySafetyState.tableCell(
          'Due',
          bold: true,
        ),
        _ObservationSummarySafetyState.tableCell(
          'Total',
          bold: true,
        ),
      ],
    );
  }

  /// 🔹 Data row
  TableRow dataRow(ObservationTableRow row) {
    final isTotal = row.stage == 'Total';

    return TableRow(
      decoration: isTotal ? BoxDecoration(color: Colors.grey.shade100) : null,
      children: [
        tableCell(row.stage, bold: isTotal),
        tableCell(
          row.overdue.toString(),
          color: Colors.red,
          bold: isTotal,
        ),
        tableCell(
          row.due.toString(),
          color: Colors.orange,
          bold: isTotal,
        ),
        tableCell(
          row.total.toString(),
          bold: isTotal,
        ),
      ],
    );
  }

  /// 🔹 Common cell
  static Widget tableCell(
    String text, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: color ?? Colors.black,
        ),
      ),
    );
  }
}
