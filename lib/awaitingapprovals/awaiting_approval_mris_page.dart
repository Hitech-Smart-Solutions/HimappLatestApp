import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:himappnew/service/material_requisition_slip_Service.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'package:himappnew/transaction/material_requisition_slip.dart';

class AwaitingApprovalMrisPage extends StatefulWidget {
  const AwaitingApprovalMrisPage({super.key});

  @override
  State<AwaitingApprovalMrisPage> createState() =>
      _AwaitingApprovalMrisPageState();
}

class _AwaitingApprovalMrisPageState extends State<AwaitingApprovalMrisPage> {
  bool isLoading = true;
  List<dynamic> awaitingMRISData = [];

  final MaterialRequisitionSlipService _materialRequisitionSlipService =
      MaterialRequisitionSlipService();

  final programId = AppPages.materialIssueSlipProgramId;

  String _formatDate(String? date) {
    if (date == null) return '-';
    final d = DateTime.parse(date);
    return "${d.day}-${d.month}-${d.year}";
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool isApproval = true; // New variable to track approval status

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";
    final d = DateTime.parse(date);
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  String formatDateTime(String? date) {
    if (date == null || date.isEmpty) return "-";
    final d = DateTime.parse(date);
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year} "
        "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _loadAwaitingMRISData();
  }

  Future<void> _loadAwaitingMRISData() async {
    try {
      final int? userId = await SharedPrefsHelper.getUserId();
      final data = await _materialRequisitionSlipService
          .getMaterialIssuesAwaitingApproval(
        userId!,
        programId,
      );
      setState(() {
        awaitingMRISData = data;
        isLoading = false;
      });
      debugPrint('API Response: $awaitingMRISData');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> onSlipClick(BuildContext context, int id) async {
    final data = await _materialRequisitionSlipService.getMaterialIssueById(
        id, programId);

    if (data == null) return;

    await SharedPrefsHelper.saveProjectID(data['projectID']);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialRequisitionSlip(
          projectService: ProjectService(),
          slipId: id,
          isApproval: true,
        ),
      ),
    );

    if (result == true) {
      print("🔄 Approval Done → Refresh Awaiting List");

      await _loadAwaitingMRISData(); // list refresh
    }
  }

  Future<void> _openActionPopup(int id) async {
    try {
      final data = await _materialRequisitionSlipService.getMrisApprovalHistory(
        id: id,
        programId: AppPages.materialIssueSlipProgramId,
      );

      if (!mounted) return;

      // 🔥 API ke baad dialog open
      _showHistoryPopup(data);
    } catch (e) {
      debugPrint("❌ History error: $e");
      showSnack("Failed to load history");
    }
  }

  Widget _materialIssueCard(BuildContext context, Map<String, dynamic> item) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onSlipClick(context, item['id']), // ✅ CARD CLICK
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Slip + Status + Action
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Text(
                      item['slipNumber'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.center,
                      child: _statusChip(context, item['status']),
                    ),
                  ),

                  /// 🔹 Actions button (popup only)
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text("Actions"),
                        onPressed: () {
                          // ❗️button tap par card click trigger na ho
                          _openActionPopup(item['id']);
                        },
                      ),
                    ),
                  ),
                ],
              ),

              _twoColumnRow(
                _infoRow(context, "Date", _formatDate(item['slipDate'])),
                _infoRow(context, "Floor", item['floorName']),
              ),

              _twoColumnRow(
                _infoRow(context, "Section", item['sectionName']),
                _infoRow(context, "Created By", item['createdBy']),
              ),

              _fullWidthRow(
                _infoRow(context, "Employee", item['employeeName']),
              ),

              _fullWidthRow(
                _infoRow(context, "Contractor", item['contractorName']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String? value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90, // label column fixed
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : "-",
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoColumnRow(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 8),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _fullWidthRow(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, String? status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color textColor = isDark ? Colors.white : Colors.black;

    switch (status) {
      case "Approved":
        bgColor = isDark ? Colors.green.shade700 : Colors.green.shade100;
        break;
      case "Rejected":
        bgColor = isDark ? Colors.red.shade700 : Colors.red.shade100;
        break;
      default:
        bgColor = isDark ? Colors.orange.shade700 : Colors.orange.shade100;
    }

    return Chip(
      label: Text(
        status ?? '',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: bgColor,
    );
  }

  void _showHistoryPopup(List<dynamic> historyData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final header = historyData.isNotEmpty ? historyData[0] : null;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🔹 TITLE
                const Text(
                  "MRIS Approval History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔹 HEADER CARD (ONE LINE LOOK)
                if (header != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // 🔹 COL 1 – Slip No
                        Expanded(
                          flex: 4, // col-md-4
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  header['transactionCode'] ?? "-",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 🔹 COL 2 – Date
                        Expanded(
                          flex: 4, // col-md-4
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                formatDate(header['transactionDate']),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        // 🔹 COL 3 – Created By
                        Expanded(
                          flex: 4, // col-md-4
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.person, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  header['createdBy'] ?? "-",
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),

                /// 🔹 HISTORY LIST
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: historyData.length,
                    itemBuilder: (_, index) {
                      final item = historyData[index];

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(
                                context,
                                "Actioned By",
                                item['actionedBy'],
                              ),
                              _infoRow(
                                context,
                                "Received On",
                                formatDateTime(item['receivedOn']),
                              ),
                              _infoRow(
                                context,
                                "Actioned On",
                                formatDateTime(item['actionedOn']),
                              ),
                              _infoRow(
                                context,
                                "Action",
                                item['action'],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Remarks",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['remarks'] ?? "—",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Reference: ${item['isReference'] ?? 'No'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                /// 🔹 OK BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    onWillPop:
    () async {
      Navigator.pop(context, true);
      return false;
    };
    return Scaffold(
      appBar: AppBar(title: const Text("Material Issue – Awaiting Approval")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: awaitingMRISData.length,
              itemBuilder: (context, index) {
                final item = awaitingMRISData[index];
                return _materialIssueCard(context, item);
              },
            ),
    );
  }
}
