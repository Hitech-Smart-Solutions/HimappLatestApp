import 'package:flutter/material.dart';
import 'package:himappnew/modal/observation_QC_detail_dialog.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/service/site_observation_service.dart';
// import 'modal/observation_detail_dialog.dart'; // 🔁 Dialog widget import

class ObservationSafetyNCRPage extends StatefulWidget {
  final SiteObservationService siteObservationService;
  final int siteObservationId;
  final int userId;
  // final int activityId;

  const ObservationSafetyNCRPage({
    super.key,
    required this.userId,
    required this.siteObservationService,
    required this.siteObservationId,
  });

  @override
  State<ObservationSafetyNCRPage> createState() =>
      _ObservationSafetyNCRPageState();
}

class _ObservationSafetyNCRPageState extends State<ObservationSafetyNCRPage> {
  late Future<List<NCRObservation>> futureObservations;

  @override
  void initState() {
    super.initState();
    futureObservations =
        widget.siteObservationService.fetchNCRSafetyObservations(widget.userId);
    // print("Future Observations: ${futureObservations.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Ye add karna hai
      appBar: AppBar(
        title: Text('Site Observation NCR Safety'),
      ),
      body: FutureBuilder<List<NCRObservation>>(
        future: futureObservations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No observations found."));
          }

          final observations = snapshot.data!;
          // print("Observations: ${snapshot.data!}");
          return ListView.builder(
            itemCount: observations.length,
            itemBuilder: (context, index) {
              final obs = observations[index];
              // print("Selected Status: ${obs.statusName}");

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showObservationModal(context, obs.id),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with date and status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${obs.trancationDate.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: obs.statusName.toLowerCase() == 'open'
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                obs.statusName,
                                style: TextStyle(
                                  color: obs.statusName.toLowerCase() == 'open'
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Site observation code
                        Text(
                          'Code: ${obs.siteObservationCode}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),

                        // Raised by and Observation type side by side
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                  'Raised By: ${obs.observationRaisedBy ?? "N/A"}'),
                            ),
                            Expanded(
                              child: Text('Type: ${obs.observationType}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Issue Type and Contractor Name side by side
                        Row(
                          children: [
                            Expanded(
                              child:
                                  Text('Issue Type: ${obs.issueType ?? "N/A"}'),
                            ),
                            Expanded(
                              child: Text(
                                  'Contractor: ${obs.contractorName ?? "N/A"}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Action to be taken
                        Text('Action: ${obs.actionToBeTaken ?? "N/A"}'),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showObservationModal(BuildContext context, int observationId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return FutureBuilder<List<GetSiteObservationMasterById>>(
          future: widget.siteObservationService
              .fetchGetSiteObservationMasterById(observationId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: const Text("Error"),
                content: Text('Failed to load data: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Close"),
                  ),
                ],
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return AlertDialog(
                title: const Text("No Data"),
                content: const Text("No detail found."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Close"),
                  ),
                ],
              );
            } else {
              final detail = snapshot.data!.first;
              // print("🔍 Raw Detail: $detail");

              return ObservationQCDetailDialog(
                detail: detail,
                siteObservationService: SiteObservationService(),
                siteObservationId: detail.id,
                createdBy: detail.createdBy?.toString() ?? '',
                activityId: detail.activityID,
                projectID: detail.projectID,
              );
            }
          },
        );
      },
    );
    if (result == true) {
      // 🔁 Reload list OR remove item manually from the local list
      setState(() {
        futureObservations = widget.siteObservationService
            .fetchNCRSafetyObservations(
                widget.userId); // 🔄 Refresh list from API
      });

      // ✅ ALTERNATIVELY: If you want to just remove the updated card locally:
      // setState(() {
      //   observations.removeWhere((obs) => obs.id == observationId);
      // });
    }
  }
}
