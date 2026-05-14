import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:himappnew/deshboard.dart';
import 'package:himappnew/model/company_model.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'package:himappnew/shared_prefs_helper.dart';
import 'service/company_service.dart';
import 'service/login_service.dart';
// import 'site_observation_safety.dart';

class MyCustomForm extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MyCustomForm({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  // _MyCustomFormState createState() => _MyCustomFormState();
  State<MyCustomForm> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? _selectedBusiness;

  final LoginService _loginService = LoginService();
  final CompanyService _companyService = CompanyService();

  bool showResult = false;

  Map<String, dynamic>? userData;
  bool isLoading = false;
  // Map<String, String> dummyData = {
  //   "username": "rajesh.kumar",
  //   "email": "raj***@hitech.com",
  //   "phone": "+91 98****456",
  //   "department": "Structural Engineering",
  //   "empCode": "000983",
  //   "project": "Metro Rail Phase-3"
  // };

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

    if (!mounted) return; // ✅ ADD THIS

    Navigator.pop(context);

    if (result['success']) {
      final responseBody = result['data'];
      var userId = responseBody['userId'];
      var userName = responseBody['userName'];
      var token = responseBody['token'];

      if (userId != null && token != null) {
        await SharedPrefsHelper.clear();
        await SharedPrefsHelper.saveUserId(userId);
        await SharedPrefsHelper.saveToken(token);
        await SharedPrefsHelper.saveUserName(userName);

        final fcmToken = await FirebaseMessaging.instance.getToken();

        if (!mounted) return; // ✅ AGAIN (after await)

        if (fcmToken != null) {
          await _loginService.updateUserMobileAppToken(userId, fcmToken);
        }

        if (!mounted) return; // ✅ AGAIN

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
    if (!mounted) return;
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
                            return Center(
                                child: Text('Error: \${snapshot.error}'));
                          } else if (snapshot.hasData) {
                            List<Company> companies = snapshot.data!;
                            return Column(
                              children: companies.map((company) {
                                return ListTile(
                                    title: Text(company.name),
                                    onTap: () async {
                                      final selectedName = company.name;

                                      await SharedPrefsHelper.saveCompanyId(
                                          company.id);
                                      await SharedPrefsHelper.saveCompanyName(
                                          company.name);
                                      await SharedPrefsHelper.saveUserName(
                                          userNameController.text);

                                      if (!mounted) return;

                                      setState(() {
                                        _selectedBusiness = selectedName;
                                      });

                                      Navigator.of(this.context)
                                          .pop(); // ✅ force State context

                                      Navigator.pushReplacement(
                                        this.context, // ✅ SAFE
                                        MaterialPageRoute(
                                          builder: (_) => DashboardPage(
                                            isDarkMode: true,
                                            onToggleTheme: widget.onToggleTheme,
                                            userName: userNameController.text,
                                            companyName: selectedName,
                                            projectService: ProjectService(),
                                            siteObservationService:
                                                SiteObservationService(),
                                          ),
                                        ),
                                      );
                                    });
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

  String? validateUserInput(String value) {
    value = value.trim();

    if (value.isEmpty) {
      return "Please enter Email / Mobile / Employee Code";
    }

    // 📧 Email
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (emailRegex.hasMatch(value)) {
      return null;
    }

    // 📱 Mobile (exactly 10 digits)
    if (RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return null;
    }

    // ❌ If only digits but NOT 10 digit
    if (RegExp(r'^[0-9]+$').hasMatch(value)) {
      if (value.length < 10) {
        return null; // ✅ Employee Code
      }
      return "Mobile number must be exactly 10 digits";
    }

    // 🆔 Employee Code (must contain at least 1 letter OR mixed)
    if (RegExp(r'^(?=.*[A-Za-z])[A-Za-z0-9]+$').hasMatch(value)) {
      return null;
    }

    return "Enter valid Email / Mobile / Employee Code";
  }

  String _maskEmail(String email) {
    return email; // 👈 no masking
  }

  String _maskMobile(String mobile) {
    return mobile; // 👈 no masking
  }

  Future<void> _onForgotPassword() async {
    // TextEditingController inputController = TextEditingController();
    // final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        TextEditingController inputController = TextEditingController();

        bool showResult = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔵 ICON + TITLE same rahega
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.person_search,
                              color: Colors.blue),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          showResult ? "Forgot Password" : "Forgot Username",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          showResult
                              ? "Click below to reset your password"
                              : "Enter Email / Mobile / Employee Code",
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        // 🔥 STEP 1 → INPUT UI
                        if (!showResult) ...[
                          TextFormField(
                            controller: inputController,
                            decoration: InputDecoration(
                              labelText: "Email / Mobile / Employee Code",
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) =>
                                validateUserInput(value!.trim()),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (!(formKey.currentState?.validate() ??
                                        false)) return;

                                    final value = inputController.text.trim();

                                    setState(() {
                                      isLoading = true;
                                    });

                                    final data = await _loginService
                                        .forgotUsername(value, channel: 2);

                                    setState(() {
                                      isLoading = false;
                                      userData = data;
                                      showResult = data != null;
                                    });

                                    if (data == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text("User not found")),
                                      );
                                    }
                                  },
                                  child: const Text("Retrieve"),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // 🔥 STEP 2 → RESULT UI
                        if (showResult && userData != null) ...[
                          const SizedBox(height: 10),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Username: ${userData!["userName"]}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    "Email: ${_maskEmail(userData!["email"])}"),
                                Text(
                                    "Mobile: ${_maskMobile(userData!["mobileNumber"])}"),
                                Text(
                                    "Department: ${userData!["departmentName"]}"),
                                Text("Emp Code: ${userData!["employeeCode"]}"),
                                Text("Project: ${userData!["projectName"]}"),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 🔴 Reset Password Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (userData == null) return;

                                final email =
                                    userData!["email"]; // 👈 API se aaya email

                                final message =
                                    await _loginService.forgotPassword(email);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(message ?? "Reset link sent")),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text("Send Reset Link"),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 🔙 Back button (optional)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showResult = false; // 🔁 back to input
                              });
                            },
                            child: const Text("Search Again"),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
                      SizedBox(
                        width: 350,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _onForgotPassword();
                              },
                              child: const Text(
                                  "Forgot Username/Forgot Password?"),
                            ),
                          ],
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
