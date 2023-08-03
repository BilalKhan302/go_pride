import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_pride/Passenger_Pannel/passenger_homeScreen.dart';
import 'package:lottie/lottie.dart';
import '../constants/constants.dart';
import 'LogIn.dart';
import 'package:fluttertoast/fluttertoast.dart';

final _auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class SignUpScreenPassenger extends StatefulWidget {
  const SignUpScreenPassenger({Key? key}) : super(key: key);
  @override
  State<SignUpScreenPassenger> createState() => _SignUpScreenPassengerState();
}

class _SignUpScreenPassengerState extends State<SignUpScreenPassenger> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  UserCredential? user;
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    Future uploadData(
      String email,
      String password,
      String name,
      String phone,
    ) async {
      UserCredential? user;
      setState(() {
        isLoading = true;
      });
      try {
        user = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        print(e);
      }
      if (user != null) {
        var user = _auth.currentUser;
        CollectionReference ref =
            FirebaseFirestore.instance.collection('passenger');
        ref.doc(user!.uid).set({
          'email': email,
          'name': name,
          'phone': phone,
          'role': "passenger",
        });
      }
      setState(() {
        isLoading = false;
      });
    }

    // String regex =
    //     r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    return Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        // appBar: AppBar(
        //   title: const Text(
        //     "Passenger Panel",
        //     style: TextStyle(fontSize: 25),
        //   ),
        //   centerTitle: true,
        //   backgroundColor: primaryColor,
        // ),
        body: Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 5),
          child: Column(
            children: [
              Container(
                  height: height * 0.3,
                  width: width,
                  child: Lottie.asset("assets/137170-moto-riding.json")),
              SizedBox(
                height: height * 0.02,
              ),
              Text(
                "Passenger Registration",
                style: TextStyle(fontSize: 30, color: primaryColor),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  children: [
                    ConstTextForm(
                      controller: _email,
                      label: "Please Enter the Email",
                      icon: const Icon(Icons.email_outlined),
                      obsTxt: false,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ConstTextForm(
                      controller: _pass,
                      label: "Please Enter the Password",
                      icon: const Icon(Icons.password_outlined),
                      obsTxt: true,
                      type: TextInputType.text,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ConstTextForm(
                        controller: _name,
                        label: "Enter Your Full Name",
                        icon: const Icon(Icons.person),
                        obsTxt: false,
                        type: TextInputType.text),
                    const SizedBox(
                      height: 10,
                    ),
                    ConstTextForm(
                      controller: _phone,
                      label: "Enter your phone number",
                      icon: const Icon(Icons.phone),
                      obsTxt: false,
                      type: TextInputType.phone,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          LoginScreenPassenger()));
                            },
                            child: Text("Already have an account click here",
                                style: TextStyle(
                                    fontSize: 16, color: primaryColor)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: primaryColor,
                      minimumSize: Size(width * 0.8, 40)),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_email.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              elevation: 1.0,
                              content: const Text("Email Can't be empty"),
                              backgroundColor: primaryColor,
                            ));
                          } else if (_pass.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              elevation: 1.0,
                              content: const Text("Password Can't be empty"),
                              backgroundColor: primaryColor,
                            ));
                          } else if (_pass.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                elevation: 1.0,
                                backgroundColor: primaryColor,
                                content: const Text(
                                    "Password length must be six or greater")));
                          }else if (_phone.text.length>11) {
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
                          }
                         else{
                            await uploadData(
                              _email.text,
                              _pass.text,
                              _name.text,
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
                  child: const Text(
                    "Register",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ))
            ],
          ),
        ));
  }
}
