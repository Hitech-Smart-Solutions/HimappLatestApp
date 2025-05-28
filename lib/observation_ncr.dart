// lib/pages/observation_ncr_page.dart

import 'package:flutter/material.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:image_picker/image_picker.dart';

class ObservationNCRPage extends StatefulWidget {
  final SiteObservationService siteObservationService;
  final int userId;

  const ObservationNCRPage({
    super.key,
    required this.userId,
    required this.siteObservationService,
  });

  @override
  State<ObservationNCRPage> createState() => _ObservationNCRPageState();
}

class _ObservationNCRPageState extends State<ObservationNCRPage> {
  late Future<List<NCRObservation>> futureObservations;
  bool isEditing = false;
  XFile? uploadedFile;

  @override
  void initState() {
    super.initState();
    futureObservations =
        widget.siteObservationService.fetchNCRObservations(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Observations')),
      body: FutureBuilder<List<NCRObservation>>(
        future: futureObservations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final observations = snapshot.data!;
            if (observations.isEmpty) {
              return const Center(child: Text('No observations found.'));
            }
            return ListView.builder(
              itemCount: observations.length,
              itemBuilder: (context, index) {
                final obs = observations[index];
                return GestureDetector(
                  onTap: () => _showObservationModal(context, obs),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                obs.siteObservationCode,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(obs.statusName),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.circle,
                                        size: 10, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      obs.statusName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("Description: ${obs.observationDescription}"),
                          Text("Type: ${obs.observationType}"),
                          Text("Raised By: ${obs.observationRaisedBy}"),
                          Text("Contractor: ${obs.contractorName}"),
                          Text(
                              "Due Date: ${obs.dueDate.toLocal().toString().split('T')[0]}"),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('No data available.'));
        },
      ),
    );
  }

  void _showObservationModal(BuildContext context, NCRObservation obs) {
    String selectedOption = obs.statusName;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding:
              EdgeInsets.zero, // Remove default padding for full width header
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: DefaultTabController(
              length: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with background color
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            obs.siteObservationCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade900,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            dropdownColor: Colors.blue.shade900,
                            value: selectedOption,
                            underline: const SizedBox(),
                            iconEnabledColor: Colors.white,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            items: ['Open', 'In Progress', 'Closed']
                                .map((String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedOption = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Material(
                    color: Colors.grey.shade100,
                    child: const TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(text: "Details"),
                        Tab(text: "Attachments"),
                        Tab(text: "Activity"),
                      ],
                    ),
                  ),

                  // Tab Views
                  SizedBox(
                    height: 300, // Adjust height as needed
                    child: TabBarView(
                      children: [
                        // Details Tab
                        // Inside TabBarView > Details Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Static observation details
                              Text("Status: $selectedOption"),
                              const SizedBox(height: 8),
                              Text(
                                  "Description: ${obs.observationDescription}"),
                              const SizedBox(height: 8),
                              Text("Type: ${obs.observationType}"),
                              const SizedBox(height: 8),
                              Text("Raised By: ${obs.observationRaisedBy}"),
                              const SizedBox(height: 8),
                              Text("Contractor: ${obs.contractorName}"),
                              const SizedBox(height: 8),
                              Text(
                                  "Due Date: ${obs.dueDate.toLocal().toString().split('T')[0]}"),

                              const SizedBox(height: 20),

                              // Root Cause Details Card
                              // <-- Move this outside the builder

                              StatefulBuilder(
                                builder: (context, setState) {
                                  final TextEditingController
                                      rootCauseController =
                                      TextEditingController();
                                  final TextEditingController
                                      reworkCostController =
                                      TextEditingController();
                                  final TextEditingController
                                      preventiveActionController =
                                      TextEditingController();
                                  final TextEditingController
                                      correctiveActionController =
                                      TextEditingController();

                                  return Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Title Row
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "Root Cause Details",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  isEditing
                                                      ? Icons.close
                                                      : Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    isEditing = !isEditing;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Editable form
                                          if (isEditing)
                                            Column(
                                              children: [
                                                TextField(
                                                  controller:
                                                      rootCauseController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: "Root Cause",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),

                                                TextField(
                                                  controller:
                                                      reworkCostController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: "Rework Cost",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),

                                                TextField(
                                                  controller:
                                                      preventiveActionController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        "Preventive Action To Be Taken",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),

                                                TextField(
                                                  controller:
                                                      correctiveActionController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        "Corrective Action To Be Taken",
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),

                                                // File upload button
                                                Row(
                                                  children: [
                                                    ElevatedButton.icon(
                                                      icon: const Icon(
                                                          Icons.attach_file),
                                                      label: const Text(
                                                          "Upload File"),
                                                      onPressed: () async {
                                                        final ImagePicker
                                                            picker =
                                                            ImagePicker();
                                                        final XFile? file =
                                                            await picker.pickImage(
                                                                source:
                                                                    ImageSource
                                                                        .gallery);
                                                        if (file != null) {
                                                          setState(() {
                                                            uploadedFile = file;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                    const SizedBox(width: 12),
                                                    if (uploadedFile != null)
                                                      Expanded(
                                                          child: Text(
                                                              uploadedFile!
                                                                  .name,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis)),
                                                  ],
                                                ),

                                                const SizedBox(height: 20),
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      // Save logic here
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blue,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                    ),
                                                    child: const Text("Update"),
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            const Text(
                                                "📝 Static content of root cause details."),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: 300, // Adjust height as needed
                          child: TabBarView(
                            children: [
                              // Details Tab with toggle
                              StatefulBuilder(
                                builder: (context, setState) {
                                  bool isEditing = false;
                                  TextEditingController descriptionController =
                                      TextEditingController(
                                          text: obs.observationDescription);
                                  TextEditingController typeController =
                                      TextEditingController(
                                          text: obs.observationType);
                                  TextEditingController raisedByController =
                                      TextEditingController(
                                          text: obs.observationRaisedBy);
                                  TextEditingController contractorController =
                                      TextEditingController(
                                          text: obs.contractorName);
                                  String status = selectedOption;

                                  return Card(
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Title Row
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "Root Cause Details",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  isEditing
                                                      ? Icons.check
                                                      : Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    if (isEditing) {
                                                      // Save logic here (API call or state update)
                                                      selectedOption = status;
                                                      String
                                                          updatedDescription =
                                                          descriptionController
                                                              .text;
                                                      // obs.observationType =
                                                      //     typeController.text;
                                                      // obs.observationRaisedBy =
                                                      //     raisedByController
                                                      //         .text;
                                                      // obs.contractorName =
                                                      //     contractorController
                                                      //         .text;
                                                    }
                                                    isEditing = !isEditing;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),

                                          // Editable or Read-only Mode
                                          isEditing
                                              ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    DropdownButton<String>(
                                                      value: status,
                                                      onChanged: (val) {
                                                        if (val != null) {
                                                          setState(() =>
                                                              status = val);
                                                        }
                                                      },
                                                      items: [
                                                        'Open',
                                                        'In Progress',
                                                        'Closed'
                                                      ]
                                                          .map((e) =>
                                                              DropdownMenuItem(
                                                                value: e,
                                                                child: Text(e),
                                                              ))
                                                          .toList(),
                                                    ),
                                                    TextField(
                                                      controller:
                                                          descriptionController,
                                                      decoration:
                                                          const InputDecoration(
                                                              labelText:
                                                                  "Description"),
                                                    ),
                                                    TextField(
                                                      controller:
                                                          typeController,
                                                      decoration:
                                                          const InputDecoration(
                                                              labelText:
                                                                  "Type"),
                                                    ),
                                                    TextField(
                                                      controller:
                                                          raisedByController,
                                                      decoration:
                                                          const InputDecoration(
                                                              labelText:
                                                                  "Raised By"),
                                                    ),
                                                    TextField(
                                                      controller:
                                                          contractorController,
                                                      decoration:
                                                          const InputDecoration(
                                                              labelText:
                                                                  "Contractor"),
                                                    ),
                                                  ],
                                                )
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text("Status: $status"),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        "Description: ${obs.observationDescription}"),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        "Type: ${obs.observationType}"),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        "Raised By: ${obs.observationRaisedBy}"),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        "Contractor: ${obs.contractorName}"),
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Attachments Tab placeholder
                              const Center(
                                  child: Text("No attachments available.")),

                              // Activity Tab placeholder
                              const Center(
                                  child: Text("No activity recorded.")),
                            ],
                          ),
                        ),

                        // Attachments Tab placeholder
                        const Center(child: Text("No attachments available.")),

                        // Activity Tab placeholder
                        const Center(child: Text("No activity recorded.")),
                      ],
                    ),
                  ),

                  // Close Button aligned right
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 12),
                      child: TextButton(
                        child: const Text("Close"),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('open')) return Colors.green;
    if (normalized.contains('close')) return Colors.red;
    if (normalized.contains('progress')) return Colors.orange;
    return Colors.grey;
  }
}
