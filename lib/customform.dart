import 'package:flutter/material.dart';
import 'package:himappnew/showbusinesses.dart';

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

class MyCustomFormState extends State<MyCustomForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? _selectedBusiness;
  @override
  Widget build(BuildContext context) {
    return Form(
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
          SizedBox(height: 16),
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
                    )),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              width: 350,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (userNameController.text == 'admin' &&
                        passwordController.text == 'admin') {
                      _showBusinessesModal();
                    }
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
    );
  }

  void _showBusinessesModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor:
          Colors.black.withValues(alpha: 0.5), // Background color with opacity
      transitionDuration:
          const Duration(milliseconds: 300), // Animation duration
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Dialog(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text("Hitech Projects"),
                      onTap: () {
                        setState(() {
                          _selectedBusiness = 'Hitech Projects';
                        });
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShowBusinesses(
                                selectedBusiness: _selectedBusiness ??
                                    'Select business first'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text("HRMS"),
                      onTap: () {
                        setState(() {
                          _selectedBusiness = 'HRMS';
                        });
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShowBusinesses(
                                selectedBusiness: _selectedBusiness ??
                                    'Select business first'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text("Alphabet"),
                      onTap: () {
                        setState(() {
                          _selectedBusiness = 'Alphabet';
                        });
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShowBusinesses(
                                selectedBusiness: _selectedBusiness ??
                                    'Select business first'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
