import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:himappnew/deshboard.dart';
import 'package:himappnew/model/company_model.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'service/company_service.dart';
import 'service/login_service.dart';
import 'site_observation_safety.dart';

class MyCustomForm extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MyCustomForm({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  _MyCustomFormState createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? _selectedBusiness;

  final LoginService _loginService = LoginService();
  final CompanyService _companyService = CompanyService();

  Future<void> _login() async {
    final username = userNameController.text;
    final password = passwordController.text;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          const Center(child: CircularProgressIndicator()),
    );

    final result = await _loginService.login(username, password);
    Navigator.pop(context);

    if (result['success']) {
      final responseBody = result['data'];
      var userId = responseBody['userId'];
      var userName = responseBody['userName'];
      var token = responseBody['token'];
      print("responseBody: $responseBody");

      if (userId != null && token != null) {
        await SharedPrefsHelper.clear();
        await SharedPrefsHelper.saveUserId(userId);
        await SharedPrefsHelper.saveToken(token);
        await SharedPrefsHelper.saveUserName(userName);
        print("✅ Saved UserName: $userName");

        // ✅ STEP: Get Firebase token
        final fcmToken = await FirebaseMessaging.instance.getToken();
        print("✅ FCM Token: $fcmToken");
        if (fcmToken != null) {
          // ✅ STEP: Call API to save mobileAppToken
          await _loginService.updateUserMobileAppToken(userId, fcmToken);
        }

        _showBusinessesModal();
      } else {
        _showErrorDialog("Required data not found in the response.");
      }
    } else {
      _showErrorDialog(result['message']);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
                FutureBuilder<int?>(
                  future: SharedPrefsHelper.getUserId(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (userSnapshot.hasError ||
                        !userSnapshot.hasData ||
                        userSnapshot.data == null) {
                      return const Center(
                          child: Text('Error fetching user ID'));
                    } else {
                      int userId = userSnapshot.data!;
                      return FutureBuilder<List<Company>>(
                        future: _companyService.fetchCompanies(userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            print('snapshot,$snapshot');
                            return Center(
                                child: Text('Error: \${snapshot.error}'));
                          } else if (snapshot.hasData) {
                            List<Company> companies = snapshot.data!;
                            return Column(
                              children: companies.map((company) {
                                return ListTile(
                                  title: Text(company.name),
                                  onTap: () async {
                                    setState(() {
                                      _selectedBusiness = company.name;
                                    });
                                    await SharedPrefsHelper.saveCompanyId(
                                        company.id);
                                    // Save company name too
                                    await SharedPrefsHelper.saveCompanyName(
                                        company.name);

                                    // Save username as well (so it persists after app restart)
                                    await SharedPrefsHelper.saveUserName(
                                        userNameController.text);
                                    Navigator.of(context).pop();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DashboardPage(
                                          isDarkMode: true,
                                          onToggleTheme: widget.onToggleTheme,
                                          userName: userNameController.text,
                                          companyName: _selectedBusiness ??
                                              'Default Company',
                                          projectService: ProjectService(),
                                          siteObservationService:
                                              SiteObservationService(),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          } else {
                            return const Center(
                                child: Text('No businesses available'));
                          }
                        },
                      );
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
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/hitech_Logo.png',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              backgroundColor:
                                  const Color.fromRGBO(55, 154, 230, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text(
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
