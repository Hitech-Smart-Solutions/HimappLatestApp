import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:himappnew/model/observation_summary_Model.dart';
import 'package:himappnew/service/observation_summary_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
  int functionId = 13;
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
      trendDataMonth = await _service.getLastSixMonthObservationSummary(
        functionId,
        selectedProjectIds,
      );

      // 🔥 PRINT START
      print("===== TREND DATA =====");

      for (var d in trendDataMonth) {
        print(
          "📅 ${d.stage} | 🔵 Obs: ${d.issueCount} | 🟢 NCR: ${d.ncrCount} | 🟠 GP: ${d.goodPracticeCount}",
        );
      }

      print("===== END =====");

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
                      ? 'All Projects Selected'
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
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView(
              shrinkWrap: true,
              children: [
                // ⭐ SELECT ALL OPTION
                CheckboxListTile(
                  dense: true,
                  title: const Text("Select All Projects"),
                  value: selectedProjectIds.length == projectData.length,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedProjectIds =
                            projectData.map((p) => p.id).toList();
                      } else {
                        selectedProjectIds.clear();
                      }
                    });
                  },
                ),

                const Divider(height: 1),

                // INDIVIDUAL ITEMS
                ...projectData.map((p) {
                  return CheckboxListTile(
                    dense: true,
                    value: selectedProjectIds.contains(p.id),
                    onChanged: (val) {
                      onCheckboxChange(p.id, val ?? false);

                      setState(() {}); // refresh UI
                    },
                    title: Text(
                      p.projectName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  Widget last6MonthChart() {
    if (trendDataMonth.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return SizedBox(
          height: 350,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width:
                  isMobile ? trendDataMonth.length * 120 : constraints.maxWidth,
              child: SfCartesianChart(
                title: ChartTitle(
                  text: 'Last 6 Months trend (by Observation count)',
                ),
                legend: Legend(
                  isVisible: true,
                  position:
                      isMobile ? LegendPosition.bottom : LegendPosition.right,
                ),
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: "Last 6 Months"),
                  labelRotation: isMobile ? -45 : 0,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: "Observation Count"),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: [
                  /// 🔵 Observation
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

                  /// 🟢 NCR (🔥 TOTAL YAHI DIKHAYENGE)
                  StackedColumnSeries<ObservationTrendMonth, String>(
                    dataSource: trendDataMonth,
                    xValueMapper: (d, _) => d.stage,
                    yValueMapper: (d, _) => d.ncrCount,
                    name: 'NCR',
                    color: Colors.green,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.middle,
                      builder: (data, point, series, pointIndex, seriesIndex) {
                        final d = data as ObservationTrendMonth;

                        // final total =
                        //     d.issueCount + d.ncrCount + d.goodPracticeCount;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// 🔥 TOP → TOTAL
                            // Text(
                            //   total.toString(),
                            //   style: TextStyle(
                            //     fontWeight: FontWeight.bold,
                            //     fontSize: 11,
                            //     color: Colors.black,
                            //   ),
                            // ),

                            /// 🔽 MIDDLE → NCR VALUE
                            Text(
                              d.ncrCount.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  /// 🟠 Good Practice
                  StackedColumnSeries<ObservationTrendMonth, String>(
                    dataSource: trendDataMonth,
                    xValueMapper: (d, _) => d.stage,
                    yValueMapper: (d, _) => d.goodPracticeCount,
                    name: 'Good Practice',
                    color: Colors.orange,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.middle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget categoryChart() {
    if (categoryTrendData.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        // Step 1: collect categories
        final Set<String> categorySet = {};
        for (var item in categoryTrendData) {
          categorySet.addAll(item.categoryData.keys);
        }

        final List<String> categories = categorySet.toList();

        // Step 2: build series
        List<StackedColumnSeries<CategoryTrend, String>> series =
            categories.map((category) {
          return StackedColumnSeries<CategoryTrend, String>(
            name: category,
            dataSource: categoryTrendData,
            xValueMapper: (d, _) => d.stage,
            yValueMapper: (d, _) => d.categoryData.containsKey(category)
                ? d.categoryData[category]!
                : 0,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.middle,
              overflowMode: OverflowMode.shift,
            ),
          );
        }).toList();

        return SizedBox(
          height: 380,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // 🔥 KEY FIX
            child: SizedBox(
              width: isMobile
                  ? categoryTrendData.length * 120 // 🔥 space for each month
                  : constraints.maxWidth,
              child: SfCartesianChart(
                title: ChartTitle(
                  text: "Last 6 Months trend (by Category)",
                ),

                /// ✅ SAME legend (no change)
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.right,
                ),

                primaryXAxis: CategoryAxis(
                  labelRotation: isMobile ? -45 : 0, // 🔥 mobile fix
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
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Dashboard'),
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
//////////////////////////////////////////////////////////////////////////
