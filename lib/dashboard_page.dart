import 'package:flutter/material.dart';
import 'package:himappnew/model/SiteObservation.dart';
import 'package:himappnew/model/company.dart';
import 'package:himappnew/model/project.dart';
import 'package:himappnew/service/company_service.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';

class DashboardPage extends StatefulWidget {
  final String companyName;
  final ProjectService _projectService;
  final SiteObservationService _siteObservationService;

  const DashboardPage({
    super.key,
    required this.companyName,
    required ProjectService projectService,
    required SiteObservationService siteObservationService,
  })  : _projectService = projectService,
        _siteObservationService = siteObservationService;

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<String> items = []; // Project names list
  List<Company> companies = []; // Company names list
  List<SiteObservation> observations = []; // Dummy data
  String? selectedItem;
  String? selectedCompany;
  bool isLoading = true; // Loading indicator
  bool showObservations = true; // Toggle observations

  final CompanyService _companyService = CompanyService(); // Company service

  @override
  void initState() {
    super.initState();
    fetchProjects();
    fetchCompanies();
    fetchSiteObservation();
  }

  // Fetch company list
  Future<void> fetchCompanies() async {
    int? userId = await SharedPrefsHelper.getUserId();
    try {
      final companyList = await _companyService.fetchCompanies(userId!);
      setState(() {
        companies = companyList;
        selectedCompany = companies.isNotEmpty ? companies[0].name : null;
      });

      if (selectedCompany != null) {
        fetchProjects();
      }
    } catch (e) {
      print("Error fetching companies: $e");
    }
  }

  // Fetch projects
  Future<void> fetchProjects() async {
    try {
      int? userId = await SharedPrefsHelper.getUserId();
      int? companyId = await SharedPrefsHelper.getCompanyId();
      if (userId == null || companyId == null) {
        print("User ID or Company ID not found in SharedPreferences");
        setState(() {
          isLoading = false;
        });
        return;
      }

      List<Project> projects = await widget._projectService.fetchProject(
        userId,
        companyId,
      );

      setState(() {
        items = projects.map((project) => project.name).toList();
        selectedItem = items.isNotEmpty ? items[0] : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching projects: $e");
    }
  }

// Fetch Observations
  Future<void> fetchSiteObservation() async {
    try {
      List<SiteObservation> siteObservations =
          await widget._siteObservationService.fetchSiteObservation();

      setState(() {
        observations =
            siteObservations; // ✅ Ye ab `List<SiteObservation>` assign karega
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching observations: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Company Dropdown
            DropdownButton<String>(
              value: selectedCompany,
              icon: Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              style: TextStyle(color: Colors.black),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCompany = newValue;
                });
                fetchProjects();
              },
              items: companies.map<DropdownMenuItem<String>>((Company company) {
                return DropdownMenuItem<String>(
                  value: company.name,
                  child: Text(
                    company.name,
                    style: TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              dropdownColor: Colors.white,
            ),

            // Project Dropdown
            DropdownButton<String>(
              value: selectedItem,
              icon: Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              style: TextStyle(color: Colors.black),
              onChanged: (String? newValue) {
                setState(() {
                  selectedItem = newValue;
                });
              },
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              dropdownColor: Colors.white,
            ),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Center(
            child: isLoading
                ? CircularProgressIndicator() // ✅ Loader jab data load ho raha ho
                : showObservations && observations.isNotEmpty
                    ? ListView.builder(
                        itemCount: observations.length,
                        itemBuilder: (context, index) {
                          SiteObservation observation = observations[index];

                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 4,
                            child: ListTile(
                              title: Text(
                                observation.observationDescription,
                                style: TextStyle(fontSize: 18),
                              ),
                              subtitle: Text(
                                "Code: ${observation.siteObservationCode}\n"
                                "Action: ${observation.actionToBeTaken}",
                                style: TextStyle(color: Colors.grey),
                              ),
                              leading: Icon(Icons.article, color: Colors.blue),
                            ),
                          );
                        },
                      )
                    : Center(
                        // ✅ Jab `showObservations` false ho ya `observations` empty ho
                        child: Text(
                          "No Observations Available",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  showObservations =
                      !showObservations; // ✅ Toggle `showObservations`
                });
              },
              child: Icon(
                  showObservations ? Icons.list : Icons.add), // ✅ Toggle icon
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
