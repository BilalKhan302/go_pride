import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RideRequest {
  final String origin;
  final String destination;

  RideRequest({required this.origin, required this.destination});
}

class Constants {
  static String ?userEmail;
  static String previouskey='AIzaSyBuyAx7S32Cpjr6P05KkJc8ji9UfaAtVao';
  void saveDriverUid(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('driverUid', uid);
  }
  Future<String?> getDriverUid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('driverUid');
  }
  void savePassengerUid(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('driverUid', uid);
  }
  Future<String?> getPassengerUid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('driverUid');
  }

}



final Color primaryColor=Colors.orange;
final Color secondaryColor=Colors.grey;
class ConstTextForm extends StatelessWidget {
  TextEditingController controller;
  ConstTextForm({Key? key,required this.type,required this.controller,required this.label,required this.icon,required this.obsTxt}) : super(key: key);
  String label;
  Icon icon;
  bool obsTxt;
  TextInputType ?type;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obsTxt,
      controller: controller,
      keyboardType: type ,
      decoration: InputDecoration(
          prefixIcon: icon,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15)
          ),
          label: Text(label)
      ),
    );
  }
}
