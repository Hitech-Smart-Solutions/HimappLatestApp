import 'package:flutter/material.dart';
import 'package:himappnew/model/company.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'service/company_service.dart'; // Import your new service
import 'service/login_service.dart'; // Login service as before
import 'dashboard_page.dart';


class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyCustomFormState createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? _selectedBusiness;

  final LoginService _loginService =
      LoginService(); // Create an instance of the login service
  final CompanyService _companyService =
      CompanyService(); // Create an instance of the company service

  // Login function
  Future<void> _login() async {
    final username = userNameController.text;
    final password = passwordController.text;

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => Center(child: CircularProgressIndicator()),
    );

    final result = await _loginService.login(username, password);
    Navigator.pop(context); // Close the loading dialog

    if (result['success']) {
      final responseBody = result['data'];

      var userId = responseBody['userId'];
      var userName = responseBody['userName'];
      var token = responseBody['token'];

      if (userId != null && token != null) {
        // Show businesses modal after successful login
        _showBusinessesModal();
      } else {
        _showErrorDialog("Required data not found in the response.");
      }
    } else {
      _showErrorDialog(result['message']);
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text('Login Failed'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  // Show businesses modal with dynamic company list
  void _showBusinessesModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Company",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Company>>(
                  future: _companyService.fetchCompanies(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      List<Company> companies = snapshot.data!;
                      return Column(
                        children:
                            companies.map((company) {
                              return ListTile(
                                title: Text(company.name),
                                onTap: () async {
                                  setState(() {
                                    _selectedBusiness = company.name;
                                  });
                                  await SharedPrefsHelper.saveCompanyId(company.id);
                                  Navigator.of(
                                    context,
                                  ).pop(); // Close the popup
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => DashboardPage(
                                            companyName:
                                                _selectedBusiness ??
                                                'Default Company',
                                            projectService: ProjectService(),
                                          ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                      );
                    } else {
                      return Center(child: Text('No businesses available'));
                    }
                  },
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login", textAlign: TextAlign.center),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Your custom logo
                Image.asset(
                  'images/hitech_Logo.png', // Make sure to place your logo here
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 20),

                // The custom form you provided
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username Field
                      SizedBox(
                        width: 350,
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Enter your Username',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          keyboardType: TextInputType.name,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your username";
                            }
                            return null;
                          },
                          controller: userNameController,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      SizedBox(
                        width: 350,
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Enter your Password',
                            prefixIcon: const Icon(Icons.password),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your password";
                            }
                            return null;
                          },
                          controller: passwordController,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Login Button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          width: 350,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _login();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(55, 154, 230, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Color.fromRGBO(255, 255, 255, 1),
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
          ),
        ),
      ),
    );
  }
}
