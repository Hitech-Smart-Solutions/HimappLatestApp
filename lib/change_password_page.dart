import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:himappnew/deshboard.dart';
import 'package:himappnew/service/project_service.dart';
import 'package:himappnew/service/site_observation_service.dart';
import 'dart:convert';

import '../network/api_client.dart'; // your ApiClient

class ChangePasswordPage extends StatefulWidget {
  final int userId;
  final String companyName;
  final String userName;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const ChangePasswordPage({
    super.key,
    required this.userId,
    required this.companyName,
    required this.userName,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.dio.put(
        '/api/UserMaster/ChangePassword/${widget.userId}',
        data: {
          "userId": widget.userId,
          "oldPassword": _oldPasswordController.text.trim(),
          "newPassword": _newPasswordController.text.trim(),
        },
      );

      final data = response.data;
      final Map<String, dynamic> json =
          data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(json['Message'] ?? 'Password updated successfully.')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            companyName: widget.companyName,
            userName: widget.userName,
            projectService: ProjectService(),
            siteObservationService: SiteObservationService(),
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      String msg = 'Invalid current password';

      if (e is DioException) {
        msg = e.response?.data?['Message'] ?? msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// 🔐 Current Password
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _hideOld,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _hideOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hideOld = !_hideOld),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Current password required' : null,
              ),

              const SizedBox(height: 16),

              /// 🔐 New Password
              TextFormField(
                controller: _newPasswordController,
                obscureText: _hideNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _hideNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hideNew = !_hideNew),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'New password required' : null,
              ),

              const SizedBox(height: 16),

              /// 🔐 Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _hideConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _hideConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _hideConfirm = !_hideConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Confirm password required';
                  }
                  if (v != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              /// 🔘 Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
