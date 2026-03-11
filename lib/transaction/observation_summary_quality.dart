import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:himappnew/model/observation_summary_Model.dart';
import 'package:himappnew/service/observation_summary_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// 🔹 MAIN SCREEN
class ObservationSummaryQuality extends StatefulWidget {
  const ObservationSummaryQuality({super.key});

  @override
  State<ObservationSummaryQuality> createState() =>
      _ObservationSummaryQualityState();
}

class _ObservationSummaryQualityState extends State<ObservationSummaryQuality> {
  final ObservationSummaryService _service = ObservationSummaryService();

  bool isLoading = false;
  List<Project> projectData = [];
  bool dropdownOpen = false;

  /// 🔴 Demo IDs (API ke hisaab se change karo)
  int functionId = 12;
  List<int> selectedProjectIds = [];
  // 32822,
  //   32798,
  //   32823,
  //   32815,
  //   32797,
  //   32796,
  //   32818

  List<ObservationTrend> trendData = [];

  List<ObservationTableRow> tableData = [];
  List<ObservationTrendMonth> trendDataMonth = [];
  List<CategoryTrend> categoryTrendData = [];

  void onCheckboxChange(int projectId, bool isChecked) {
    setState(() {
      if (isChecked) {
        selectedProjectIds.add(projectId);
      } else {
        selectedProjectIds.remove(projectId);
      }
    });

    // Refresh summary & charts on project selection change
    fetchSummary();
    fetchTrendChart();
    fetchCategoryChart();
  }

  @override
  void initState() {
    super.initState();

    fetchProjectData();
    // fetchSummary();
    // fetchTrendChart();
    // fetchCategoryChart();
  }

  Future<void> fetchProjectData() async {
    final userId =
        await SharedPrefsHelper.getUserId(); // tumhara existing method
    final companyId = await SharedPrefsHelper.getCompanyId();
    print("USER ID → $userId");
    print("COMPANY ID → $companyId");
    final projects = await _service.fetchProjects(companyId!, userId!);
    setState(() {
      projectData = projects;
      // ✅ SELECT ALL PROJECTS BY DEFAULT
      selectedProjectIds = projectData.map((p) => p.id).toList();
    });
    // ✅ Trigger summary load
    await fetchSummary();
    await fetchTrendChart();
    await fetchCategoryChart();
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

  Future<void> fetchTrendChart() async {
    try {
      // debugPrint("FETCH TREND CHART START");

      trendDataMonth = await _service.getLastSixMonthObservationSummary(
        functionId,
        selectedProjectIds,
      );

      // debugPrint("TREND DATA LENGTH → ${trendDataMonth.length}");

      // for (var e in trendDataMonth) {
      //   print(
      //       "Stage: ${e.stage} NCR: ${e.ncrCount} GoodPractice: ${e.goodPracticeCount}");
      // }

      setState(() {});
    } catch (e) {
      debugPrint("Trend chart error: $e");
    }
  }

  Future<void> fetchCategoryChart() async {
    final data = await _service.getLastSixMonthCategorySummary(
      functionId,
      selectedProjectIds,
    );

    setState(() {
      categoryTrendData = data;
    });
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

  Widget last6MonthChart() {
    if (trendDataMonth.isEmpty) return const SizedBox();

    return SizedBox(
      height: 350,
      child: SfCartesianChart(
        title: ChartTitle(text: 'Last 6 Months trend (by Observation count)'),
        legend: const Legend(isVisible: true),
        primaryXAxis: CategoryAxis(title: AxisTitle(text: "Last 6 Months")),
        primaryYAxis: NumericAxis(title: AxisTitle(text: "Observation Count")),
        series: <StackedColumnSeries<ObservationTrendMonth, String>>[
          StackedColumnSeries<ObservationTrendMonth, String>(
            dataSource: trendDataMonth,
            xValueMapper: (d, _) => d.stage,
            yValueMapper: (d, _) => d.issueCount,
            name: 'Observation',
            color: Colors.blue,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.middle,
            ),
          ),
          StackedColumnSeries<ObservationTrendMonth, String>(
            dataSource: trendDataMonth,
            xValueMapper: (d, _) => d.stage,
            yValueMapper: (d, _) => d.ncrCount,
            name: 'NCR',
            color: Colors.green,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.middle,
            ),
          ),
          StackedColumnSeries<ObservationTrendMonth, String>(
            dataSource: trendDataMonth,
            xValueMapper: (d, _) => d.stage,
            yValueMapper: (d, _) => d.goodPracticeCount,
            name: 'Good Practice',
            color: Colors.orange,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.middle,
              builder: (data, point, series, pointIndex, seriesIndex) {
                final d = data as ObservationTrendMonth;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      d.totalCount.toString(), // 🔴 top total (69)
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    // const SizedBox(height: 4),
                    Text(
                      d.goodPracticeCount.toString(), // 🟠 orange value (4)
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryChart() {
    if (categoryTrendData.isEmpty) return const SizedBox();

    // Step 1: collect all categories
    final Set<String> categorySet = {};
    for (var item in categoryTrendData) {
      categorySet.addAll(item.categoryData.keys);
    }

    final List<String> categories = categorySet.toList();

    // Step 2: build chart series
    List<StackedColumnSeries<CategoryTrend, String>> series =
        categories.map((category) {
      return StackedColumnSeries<CategoryTrend, String>(
        name: category,
        dataSource: categoryTrendData,
        xValueMapper: (d, _) => d.stage,
        yValueMapper: (d, _) {
          return d.categoryData.containsKey(category)
              ? d.categoryData[category]!
              : 0; // ⭐ missing category = 0
        },
        dataLabelSettings: const DataLabelSettings(
          isVisible: true,
          labelAlignment: ChartDataLabelAlignment.middle,
          overflowMode: OverflowMode.shift,
        ),
      );
    }).toList();

    return SizedBox(
      height: 380,
      child: SfCartesianChart(
        title: ChartTitle(text: "Last 6 Months trend (by Category)"),
        legend: const Legend(isVisible: true, position: LegendPosition.right),
        primaryXAxis: CategoryAxis(
          labelRotation: -45,
          title: AxisTitle(text: "Last 6 Months"),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: "Observation Count"),
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          header: '',
          format: 'point.x : point.y',
        ),
        series: series,
      ),
    );
  }

  // Widget categoryChart() {
  //   if (categoryTrendData.isEmpty) return const SizedBox();

  //   /// STEP 1: collect categories dynamically
  //   final Set<String> categorySet = {};
  //   for (var item in categoryTrendData) {
  //     categorySet.addAll(item.categoryData.keys);
  //   }

  //   final List<String> categories = categorySet.toList();

  //   /// STEP 2: create stacked series
  //   List<StackedColumnSeries<CategoryTrend, String>> series =
  //       categories.map((category) {
  //     return StackedColumnSeries<CategoryTrend, String>(
  //       name: category,
  //       width: 0.9,
  //       spacing: 0.15,
  //       dataSource: categoryTrendData,
  //       xValueMapper: (d, _) => d.stage,
  //       yValueMapper: (d, _) => d.categoryData[category] ?? 0,

  //       /// ⭐ Jugad for small labels
  //       dataLabelSettings: DataLabelSettings(
  //         isVisible: true,
  //         labelPosition: ChartDataLabelPosition.outside,
  //         overflowMode: OverflowMode.shift,
  //         labelAlignment: ChartDataLabelAlignment.outer,
  //       ),
  //     );
  //   }).toList();

  //   return SizedBox(
  //     height: 500, // ⭐ height increase jugad
  //     child: SfCartesianChart(
  //       margin: const EdgeInsets.all(16),

  //       title: ChartTitle(
  //         text: "Last 6 Months Trend (Category)",
  //       ),

  //       /// LEGEND
  //       legend: const Legend(
  //         isVisible: true,
  //         position: LegendPosition.right,
  //         overflowMode: LegendItemOverflowMode.wrap,
  //       ),

  //       /// X AXIS
  //       primaryXAxis: CategoryAxis(
  //         labelRotation: -45,
  //         title: AxisTitle(text: "Last 6 Months"),
  //         majorGridLines: const MajorGridLines(width: 0),
  //       ),

  //       /// ⭐ Y AXIS jugad
  //       primaryYAxis: NumericAxis(
  //         minimum: 0,
  //         interval: 5,
  //         title: AxisTitle(text: "Observation Count"),
  //         majorGridLines: const MajorGridLines(width: 0.5),
  //       ),

  //       /// TOOLTIP
  //       tooltipBehavior: TooltipBehavior(
  //         enable: true,
  //         header: '',
  //         format: 'point.x : point.y',
  //       ),

  //       /// SERIES
  //       series: series,
  //     ),
  //   );
  // }

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
                      : Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// TABLE (FULL WIDTH)
                                observationTable(),

                                const SizedBox(height: 20),

                                /// STAGE CHART
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: last6MonthChart(),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                /// CATEGORY CHART
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: categoryChart(),
                                  ),
                                ),
                                // Card(
                                //   child: Padding(
                                //     padding: const EdgeInsets.all(12),
                                //     child: categoryChart(),
                                //   ),
                                // ),
                                const SizedBox(
                                  height: 10,
                                )
                              ],
                            ),
                          ),
                        )
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
        _ObservationSummaryQualityState.tableCell(
          'Stage',
          bold: true,
        ),
        _ObservationSummaryQualityState.tableCell(
          'Overdue',
          bold: true,
        ),
        _ObservationSummaryQualityState.tableCell(
          'Due',
          bold: true,
        ),
        _ObservationSummaryQualityState.tableCell(
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
//////////////////////////////////////////////////////////////////////////
