import 'package:flutter/material.dart';
import 'package:himappnew/constants.dart';
import 'package:himappnew/model/siteobservation_model.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ObservationDetailDialog extends StatefulWidget {
  final GetSiteObservationMasterById detail;

  const ObservationDetailDialog({super.key, required this.detail});

  @override
  State<ObservationDetailDialog> createState() =>
      _ObservationDetailDialogState();
}

class _ObservationDetailDialogState extends State<ObservationDetailDialog> {
  // String selectedStatus = 'Open';
  bool isEditingRootCause = false;

  List<Map<String, String>> observationStatus = [];
  String? selectedStatus;
  bool isStatusEnabled = false;
  String url = AppSettings.url;

  final _formKey = GlobalKey<FormState>();
  // Static controllers for form fields
  final TextEditingController rootCauseController = TextEditingController();
  final TextEditingController reworkCostController = TextEditingController();
  final TextEditingController preventiveActionController =
      TextEditingController();
  final TextEditingController correctiveActionController =
      TextEditingController();
  final TextEditingController _activityCommentController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    bool assigned = true; // your assigned logic here

    // Debug print to find the available fields in your detail object
    print(widget.detail.toString());

    // Replace 'statusField' below with the actual property name from your model
    String statusValue = ''; // default fallback

    // For example, if your model has a 'status' property
    // statusValue = widget.detail.status;

    // If you don't know the exact property, try to find it here
    // For now, let's assign it manually or via a constructor parameter

    // Example (replace with actual property):
    // statusValue = widget.detail.observationCode; // maybe this?

    setObservationStatusDropdown(
      {
        "ObservationStatus": statusValue,
      },
      assigned,
    );

    setState(() {});
  }

  @override
  void dispose() {
    rootCauseController.dispose();
    reworkCostController.dispose();
    preventiveActionController.dispose();
    correctiveActionController.dispose();
    super.dispose();
  }

  void _sendActivityComment() {
    final comment = _activityCommentController.text.trim();
    if (comment.isEmpty) return;

    // Yahan pe apna send logic ya backend call kar sakte hain
    print("Send comment: $comment");

    // Clear textfield
    _activityCommentController.clear();

    // Optionally, update UI or refresh activity list
  }

  void setObservationStatusDropdown(Map<String, dynamic> ele, bool assigned) {
    if (ele["ObservationStatus"] == "Completed") {
      observationStatus = [
        {"id": "Completed", "name": "Completed"}
      ];
      selectedStatus = "Completed";
      isStatusEnabled = false;
    } else if (assigned && ele["ObservationStatus"] == "Ready To Inspect") {
      observationStatus = [
        {"id": "Completed", "name": "Completed"},
        {"id": "Reopen", "name": "Reopen"}
      ];
      selectedStatus = null;
      isStatusEnabled = true;
    } else if (!assigned && ele["ObservationStatus"] == "Ready To Inspect") {
      observationStatus = [
        {"id": "Ready To Inspect", "name": "Ready To Inspect"}
      ];
      selectedStatus = "Ready To Inspect";
      isStatusEnabled = false;
    } else {
      observationStatus = [
        {"id": "In Progress", "name": "In Progress"},
        {"id": "Ready To Inspect", "name": "Ready To Inspect"}
      ];
      selectedStatus = null;
      isStatusEnabled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: media.size.width * 0.9,
        height: media.size.height * 0.8, // 80% of screen height for more space
        child: DefaultTabController(
          length: 3,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.detail.observationCode,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          hint: const Text("-- Status --"),
                          isExpanded: true,
                          items: observationStatus.map((status) {
                            return DropdownMenuItem<String>(
                              value: status['id'],
                              child: Text(status['name'] ?? ''),
                            );
                          }).toList(),
                          onChanged: isStatusEnabled
                              ? (newValue) {
                                  setState(() {
                                    selectedStatus = newValue!;
                                  });
                                }
                              : null,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a status';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: "Details"),
                    Tab(text: "Attachments"),
                    Tab(text: "Activity"),
                  ],
                ),

                // Use Expanded + SingleChildScrollView with Column instead of ListView for smooth scrolling
                Expanded(
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Status: $selectedStatus"),
                              const SizedBox(height: 8),
                              Text("Description: ${widget.detail.description}"),
                              const SizedBox(height: 8),
                              Text("Type: ${widget.detail.observationCode}"),
                              const SizedBox(height: 8),
                              Text(
                                  "Raised By: ${widget.detail.observationRaisedBy}"),
                              const SizedBox(height: 16),
                              if (selectedStatus == "Ready To Inspect")
                                Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Root Cause Details",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () {
                                                setState(() {
                                                  isEditingRootCause = true;
                                                });
                                              },
                                            )
                                          ],
                                        ),
                                        if (!isEditingRootCause) ...[
                                          // Static view or placeholder here
                                          const Text("Root Cause info here..."),
                                        ] else
                                          _buildRootCauseForm(),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Attachments Tab
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? pickedFile = await picker
                                    .pickImage(source: ImageSource.gallery);
                                if (pickedFile != null) {
                                  print(
                                      "Selected image path: ${pickedFile.path}");
                                  // Yahan add karna hai image ko list me aur update karna UI ko
                                }
                              },
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Upload Image"),
                            ),
                            const SizedBox(height: 16),
                            widget.detail.activityDTO.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: widget.detail.activityDTO
                                        .map((activity) {
                                      if (activity.documentName.isEmpty)
                                        return const SizedBox();

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: GestureDetector(
                                          onTap: () {
                                            openImageModal(
                                                activity.documentName);
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                isImage(activity.documentName)
                                                    ? "$url/${activity.documentName}"
                                                    : "assets/default-image.png",
                                                fit: BoxFit.fitWidth,
                                                width: double.infinity,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                        Icons.broken_image),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : const Center(
                                    child: Text("No attachments available.")),
                          ],
                        ),
                      ),

                      // Activity Tab
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Expanded(
                                child: widget.detail.activityDTO.isEmpty
                                    ? const Center(
                                        child: Text("No activity recorded."))
                                    : ListView.builder(
                                        itemCount:
                                            widget.detail.activityDTO.length,
                                        itemBuilder: (context, index) {
                                          final activity =
                                              widget.detail.activityDTO[index];
                                          return Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                            child: Column(
                                              children: [
                                                const Divider(height: 1),
                                                ListTile(
                                                  leading: CircleAvatar(
                                                    child: Text(
                                                      (activity.assignedUserName
                                                                  ?.isNotEmpty ??
                                                              false)
                                                          ? activity
                                                              .assignedUserName![
                                                                  0]
                                                              .toUpperCase()
                                                          : '?',
                                                    ),
                                                  ),
                                                  title: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                            activity.assignedUserName ??
                                                                '',
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: Text(
                                                          activity.createdDate
                                                              .toLocal()
                                                              .toString()
                                                              .split('.')[0],
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: activity
                                                                      .actionName ==
                                                                  'Commented'
                                                              ? Colors
                                                                  .pink.shade100
                                                              : Colors.orange
                                                                  .shade100,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          activity.actionName,
                                                          style: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      if (activity
                                                          .comments.isNotEmpty)
                                                        Text(activity.comments),
                                                      if (activity.assignedUserName !=
                                                              null &&
                                                          activity
                                                              .assignedUserName!
                                                              .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 4),
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                  Icons.person,
                                                                  size: 16),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(activity
                                                                  .assignedUserName!),
                                                            ],
                                                          ),
                                                        ),
                                                      if (activity.documentName
                                                          .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 14),
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              openImageModal(
                                                                  activity
                                                                      .documentName); // You can define this method
                                                            },
                                                            child: Container(
                                                              width: 100,
                                                              height: 100,
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border.all(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade300,
                                                                    width: 2),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                child: Image
                                                                    .network(
                                                                  isImage(activity
                                                                          .documentName)
                                                                      ? "$url/${activity.documentName}"
                                                                      : "assets/default-image.png",
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder: (context,
                                                                          error,
                                                                          stackTrace) =>
                                                                      const Icon(
                                                                          Icons
                                                                              .broken_image),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _activityCommentController,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        hintText:
                                            "Add comment and assign user...",
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _sendActivityComment,
                                    child: const Text("Send"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 12),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Close"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Utility method to check image file type
  bool isImage(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.webp');
  }

  void openImageModal(String documentName) {
    final imageUrl = "$url/$documentName";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 100),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRootCauseForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedStatus == "Ready To Inspect") ...[
            TextFormField(
              controller: rootCauseController,
              decoration: const InputDecoration(
                labelText: 'Root Cause',
                hintText: 'Select Root Cause',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Root Cause is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reworkCostController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Rework Cost',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: preventiveActionController,
              decoration: const InputDecoration(
                labelText: 'Preventive Action To Be Taken',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Preventive Action To Be Taken is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: correctiveActionController,
              decoration: const InputDecoration(
                labelText: 'Corrective Action To Be Taken',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Corrective Action To Be Taken is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    // All validations passed
                    print("Saving Root Cause Data...");
                    setState(() {
                      isEditingRootCause = false;
                    });
                  } else {
                    print("Validation failed.");
                  }
                },
                child: const Text('Update'),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Root Cause Details are hidden for the current status.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
