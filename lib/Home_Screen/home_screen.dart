import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_pride/Driver_Pannel/LogIn.dart';
import 'package:go_pride/Driver_Pannel/SignUp.dart';
import 'package:go_pride/Passenger_Pannel/SignUp.dart';

import '../Passenger_Pannel/LogIn.dart';
import '../constants/constants.dart';

enum Role{
  driver,
  passenger
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Role? _role;
  @override
  Widget build(BuildContext context) {
    double height=MediaQuery.of(context).size.height;
    double width=MediaQuery.of(context).size.width;
    return  Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: height*0.35,
              width: width,
              child: Image.asset("assets/appLogo.jpg",height: 170,fit: BoxFit.fill,),
            ),
            Text("Go Pride",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 32,
              ),),

            SizedBox(
              height: height*0.25,
            ),
            Text("Please Choose Your Role",style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),),
            SizedBox(
              height: height*0.03,
            ),
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RadioListTile(
                      activeColor: primaryColor,
                      value: Role.driver,
                      groupValue: _role,
                      title: Text("Driver"),
                      onChanged: (val){
                        setState(() {
                          _role=val;
                        });
                      }
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                      activeColor: primaryColor,
                      value: Role.passenger,
                      groupValue: _role,
                      title: Text("Passenger"),
                      onChanged: (val){
                        setState(() {
                          _role=val;
                        });
                      }
                  ),
                ),
              ],
            ),
            SizedBox(height: height*0.06,),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: primaryColor,
                    minimumSize: Size(width*0.8, 40)
                ),
                onPressed: (){
                  if(_role!.index==0){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreenDriver()));
                  }else{
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreenPassenger()));

                  }
                }, child: Text("Next",style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white
            ),))


          ],
        ),
      ),
    );
  }
}
