import 'package:flutter/material.dart';

class ShowBusinesses extends StatefulWidget {
  const ShowBusinesses({super.key});

  @override
  ShowBusinessesState createState() {
    return ShowBusinessesState();
  }
}

class ShowBusinessesState extends State<ShowBusinesses> {
  String? _selectedBusiness;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      _showBusinessesModal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_selectedBusiness ?? 'Business Selection'),
        ),
        body: Center(
          child: Text(
            _selectedBusiness ?? 'Select your business',
            style: const TextStyle(fontSize: 18),
          ),
        ));
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
                    "Select a Business",
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
                    },
                  ),
                  ListTile(
                    title: const Text("HRMC"),
                    onTap: () {
                      setState(() {
                        _selectedBusiness = 'HRMC';
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    title: const Text("Alphabet"),
                    onTap: () {
                      setState(() {
                        _selectedBusiness = 'Alphabet';
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }
}
