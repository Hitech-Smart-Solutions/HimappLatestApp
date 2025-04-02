import 'package:flutter/material.dart';
import 'package:himappnew/model/project.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';

class DashboardPage extends StatefulWidget {
  final String companyName;
  final ProjectService _projectService;
  // const userId = prefs.getInt('user_id');
  const DashboardPage({
    super.key,
    required this.companyName,
    required ProjectService projectService,
  }) : _projectService = projectService;

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<String> items = []; // List to hold project names
  String? selectedItem;
  bool isLoading = true; // Loading indicator

  @override
  void initState() {
    super.initState();
    fetchProjects(); // Fetch data when the page loads
  }

  Future<void> fetchProjects() async {
    try {
      int? userId = await SharedPrefsHelper
          .getUserId();
      int? companyId = await SharedPrefsHelper
          .getCompanyId();
      if (userId == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      if (companyId == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      List<Project> projects = await widget._projectService.fetchProject(
        userId,
        companyId,
      ); // Pass userId dynamically

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.companyName} - Dashboard")),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator() // Show loading indicator while fetching
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Welcome to the ${widget.companyName} Dashboard!",
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  // DropdownButton for selecting items
                  DropdownButton<String>(
                    value: selectedItem,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedItem = newValue;
                      });
                    },
                    items: items.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  // Display selected item
                  Text(
                    selectedItem != null
                        ? "Selected item: $selectedItem"
                        : "No item selected",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
      ),
    );
  }
}
