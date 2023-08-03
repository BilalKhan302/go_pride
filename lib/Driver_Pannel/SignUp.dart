import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_pride/Driver_Pannel/LogIn.dart';
import 'package:lottie/lottie.dart';
import '../constants/constants.dart';
import 'package:fluttertoast/fluttertoast.dart';

final _auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class SignUpScreenDriver extends StatefulWidget {
  const SignUpScreenDriver({Key? key}) : super(key: key);

  @override
  State<SignUpScreenDriver> createState() => _SignUpScreenDriverState();
}

class _SignUpScreenDriverState extends State<SignUpScreenDriver> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _carModel = TextEditingController();
  final TextEditingController _carColor = TextEditingController();
  final TextEditingController _numberplateNo = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  UserCredential? user;
  bool isLoading = false;

  Future<void> uploadData(
      String email,
      String password,
      String name,
      String carModel,
      String carColor,
      String numberplateNo,
      String phone,
      ) async {
    setState(() {
      isLoading = true;
    });

    try {
      user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (user != null) {
        var user = _auth.currentUser;
        var userId = _auth.currentUser!.uid;
        //save userid in shared pref
        Constants().saveDriverUid(userId);
        CollectionReference ref = FirebaseFirestore.instance.collection('driver');
        await ref.doc(user!.uid).set({
          'driverId':userId,
          'email': email,
          'name': name,
          'carModel': carModel,
          'phone': phone,
          'numberplateNo': numberplateNo,
          'carColor': carColor,
          'role': "driver",
        });
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              height: height * 0.3,
              width: width,
              child: Lottie.asset("assets/48570-bike-on-the-go.json"),
            ),
            SizedBox(height: 20),
            Text(
              "Driver Registration",
              style: TextStyle(fontSize: 30, color: primaryColor),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: ListView(
                  children: [
                    ConstTextForm(
                      controller: _email,
                      label: "Please Enter the Email",
                      icon: Icon(Icons.email_outlined),
                      obsTxt: false,
                      type: TextInputType.emailAddress,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ConstTextForm(
                      controller: _pass,
                      label: "Please Enter the Password",
                      icon: Icon(Icons.password_outlined),
                      obsTxt: true,
                      type: TextInputType.text,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ConstTextForm(
                      controller: _name,
                      label: "Enter Your Full Name",
                      icon: Icon(Icons.person),
                      obsTxt: false,
                      type: TextInputType.text,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ConstTextForm(
                      controller: _phone,
                      label: "Enter your phone number",
                      icon: Icon(Icons.phone),
                      obsTxt: false,
                      type: TextInputType.phone,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ConstTextForm(
                      controller: _carModel,
                      label: "Your Bike Model",
                      icon: Icon(Icons.bike_scooter_outlined),
                      obsTxt: false,
                      type: TextInputType.text,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ConstTextForm(
                      controller: _carColor,
                      label: "Bike Color",
                      icon: Icon(Icons.pedal_bike_outlined),
                      obsTxt: false,
                      type: TextInputType.text,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ConstTextForm(
                      controller: _numberplateNo,
                      label: "Numberplate Number",
                      icon: Icon(Icons.confirmation_number),
                      obsTxt: false,
                      type: TextInputType.text,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreenDriver()));
                    },
                    child: Text(
                      "Already have an account click here",
                      style: TextStyle(fontSize: 16, color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: primaryColor,
                minimumSize: Size(width * 0.8, 40),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                if (_email.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      elevation: 1.0,
                      content: Text("Email Can't be empty"),
                      backgroundColor: primaryColor,
                    ),
                  );
                } else if (_pass.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      elevation: 1.0,
                      content: Text("Password Can't be empty"),
                      backgroundColor: primaryColor,
                    ),
                  );
                }
                else if (!_email.text.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      elevation: 1.0,
                      content: Text("Invalid Email"),
                      backgroundColor: primaryColor,
                    ),
                  );
                } else if (_pass.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      elevation: 1.0,
                      backgroundColor: primaryColor,
                      content: Text("Password length must be six or greater"),
                    ),
                  );
                } else if (_phone.text.length>11) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      elevation: 1.0,
                      backgroundColor: primaryColor,
                      content: Text("Number can't exceed"),
                    ),
                  );
                }
                else if (_phone.text.length<11) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      elevation: 1.0,
                      backgroundColor: primaryColor,
                      content: Text("Number can't less"),
                    ),
                  );
                }     else if (int.tryParse(_carModel.text)! >2023) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      elevation: 1.0,
                      backgroundColor: primaryColor,
                      content: Text("invalid model"),
                    ),
                  );
                } else {
                  await uploadData(
                    _email.text,
                    _pass.text,
                    _name.text,
                    _carModel.text,
                    _carColor.text,
                    _numberplateNo.text,
                    _phone.text,

                  ).then(
                        (value) {
                      Fluttertoast.showToast(
                        msg: 'Account created successfully',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                      Navigator.pop(context);
                    },
                  );
                }
              },
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text(
                "Register",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

