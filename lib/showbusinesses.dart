import 'package:flutter/material.dart';

class ShowBusinesses extends StatelessWidget {
  final String? selectedBusiness;
  // ignore: use_super_parameters
  const ShowBusinesses({super.key, required this.selectedBusiness});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("$selectedBusiness"),
        ),
        body: Center(
          child: Text(
            selectedBusiness ?? 'Select your business',
            style: const TextStyle(fontSize: 18),
          ),
        ));
  }
}
