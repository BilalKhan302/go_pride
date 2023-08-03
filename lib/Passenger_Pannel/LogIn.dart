import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_pride/Passenger_Pannel/SignUp.dart';
import 'package:go_pride/Passenger_Pannel/passenger_homeScreen.dart';
import 'package:lottie/lottie.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/constants.dart';

final _auth = FirebaseAuth.instance;
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class LoginScreenPassenger extends StatefulWidget {
  const LoginScreenPassenger({Key? key}) : super(key: key);

  @override
  State<LoginScreenPassenger> createState() => _LoginScreenPassengerState();
}

class _LoginScreenPassengerState extends State<LoginScreenPassenger> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  UserCredential? user;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    // String regex =
    //     r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      body:  Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Column(
                children: [

                  Container(
                      height: height * 0.4,
                      width: width,
                      child:
                      Lottie.asset("assets/137170-moto-riding.json")
                  ),
                  Text("Login Screen",
                    style: TextStyle(
                        fontSize: 30,
                        color: primaryColor
                    ),),
                  const SizedBox(height: 10,),

                  SizedBox(
                    height: height * 0.02,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: ListView(
                        children: [
                          ConstTextForm(
                            controller: _email,
                            label: "Please Enter the Email",
                            icon: const Icon(Icons.email_outlined),
                            obsTxt: false,
                            type: TextInputType.emailAddress,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ConstTextForm(
                            controller: _pass,
                            label: "Please Enter the Password",
                            icon: const Icon(Icons.password_outlined),
                            obsTxt: true,
                            type: TextInputType.text,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text("Don't have an account",
                                    style: TextStyle(fontSize: 15, color: Colors.black)),
                                GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpScreenPassenger()));
                                  },
                                  child: Text("Click Here",
                                      style: TextStyle(fontSize: 16, color: primaryColor)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20,),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  primary: primaryColor,
                                  minimumSize: Size(width * 0.8, 40)),
                              onPressed:  isLoading
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
                                }
                                // login
                                _auth.fetchSignInMethodsForEmail(_email.text)
                                    .then((signInMethods) async {
                                  if (signInMethods.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      elevation: 1.0,
                                      content: const Text("Email not found"),
                                      backgroundColor: primaryColor,
                                    ));
                                  } else {
                                    // email exists
                                    UserCredential? user = await _auth.signInWithEmailAndPassword(email: _email.text, password: _pass.text);

                                    if (user != null) {

                                      final DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection("passenger").doc(user.user?.uid).get();
                                      if (snapshot.data() is Map) {
                                        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
                                        if(data["role"] == "passenger") {
                                          // Allow the user to log in
                                          String currentUser=data["name"];
                                          String email=data["email"];
                                          String? currentId=_auth.currentUser?.uid;
                                          String? patientPhone=data["phone"];
                                          Navigator.of(context).push(MaterialPageRoute(
                                            builder: (context) =>  PassengerHomeScreen(
                                              email: email,
                                              name: currentUser,
                                              phone: patientPhone,
                                            ),
                                          ));

                                        }
                                      } else {
                                        // Show an error message
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          elevation: 1.0,
                                          content: const Text("You are not authorized to access this page"),
                                          backgroundColor: primaryColor,
                                        ));
                                      }
                                    }

                                  }
                                })
                                    .catchError((error) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    elevation: 1.0,
                                    content: Text("Error: $error"),
                                    backgroundColor: primaryColor,
                                  ));
                                });

                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
    );

  }

}

