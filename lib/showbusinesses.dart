import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Declare the Company class
class Company {
  final int id;
  final String companyName;
  final String shortName;
  final String phoneNumber1;
  final String phoneNumber2;
  final String emailId;
  final String webSite;
  final String pannumber;
  final String logoName;
  final String logoPath;
  final String logoContentType;
  final String address;
  final int stateId;
  final int countryId;
  final int pinCode;
  final String tanno;
  final String employerEsicNo;
  final String employerPfno;
  final int statusId;
  final bool isActive;
  final int createdBy;
  final String createdDate;
  final int lastmodifiedBy;
  final String lastModifiedDate;
  final String uniqueId;
  final int cityId;

  Company({
    required this.id,
    required this.companyName,
    required this.shortName,
    required this.phoneNumber1,
    required this.phoneNumber2,
    required this.emailId,
    required this.webSite,
    required this.pannumber,
    required this.logoName,
    required this.logoPath,
    required this.logoContentType,
    required this.address,
    required this.stateId,
    required this.countryId,
    required this.pinCode,
    required this.tanno,
    required this.employerEsicNo,
    required this.employerPfno,
    required this.statusId,
    required this.isActive,
    required this.createdBy,
    required this.createdDate,
    required this.lastmodifiedBy,
    required this.lastModifiedDate,
    required this.uniqueId,
    required this.cityId,
  });

  // Factory constructor to create a Company instance from JSON
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      companyName: json['companyName'],
      shortName: json['shortName'],
      phoneNumber1: json['phoneNumber1'],
      phoneNumber2: json['phoneNumber2'],
      emailId: json['emailId'],
      webSite: json['webSite'],
      pannumber: json['pannumber'],
      logoName: json['logoName'],
      logoPath: json['logoPath'],
      logoContentType: json['logoContentType'],
      address: json['address'],
      stateId: json['stateId'],
      countryId: json['countryId'],
      pinCode: json['pinCode'],
      tanno: json['tanno'],
      employerEsicNo: json['employerEsicNo'],
      employerPfno: json['employerPfno'],
      statusId: json['statusId'],
      isActive: json['isActive'],
      createdBy: json['createdBy'],
      createdDate: json['createdDate'],
      lastmodifiedBy: json['lastmodifiedBy'],
      lastModifiedDate: json['lastModifiedDate'],
      uniqueId: json['uniqueId'],
      cityId: json['cityId'],
    );
  }
}

class ShowBusinesses extends StatelessWidget {
  final String? selectedBusiness;
  const ShowBusinesses({super.key, required this.selectedBusiness});

  // Fetch data from the API
  Future<List<Company>> fetchData() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.130:8000/api/CompanyMaster/GetCompanies'),
    );

    if (response.statusCode == 200) {
      // Decode the response body and map it to a list of companies
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Company.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedBusiness ?? 'Business List'),
      ),
      body: FutureBuilder<List<Company>>(
        future: fetchData(), // Fetching company data
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator()); // Show loading spinner
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}')); // Show error message
          } else if (snapshot.hasData) {
            List<Company> companies = snapshot.data!;
            return ListView.builder(
              itemCount: companies.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(companies[index].companyName),
                  subtitle: Text(companies[index].shortName),
                );
              },
            );
          } else {
            return Center(
                child: Text('No data available')); // Show no data message
          }
        },
      ),
    );
  }
}
