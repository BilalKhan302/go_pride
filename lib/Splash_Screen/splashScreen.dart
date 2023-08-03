import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../Home_Screen/home_screen.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigate();
  }
  navigate() async{await Future.delayed(const Duration(seconds: 4));
  if(!mounted)return;
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const HomeScreen()));
  }
  @override
  Widget build(BuildContext context) {
    return   Scaffold(
        backgroundColor: Colors.white,
        body: Center(child:
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/appLogo.jpg"),
                Text("Go Pride",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold
                ),),
            Lottie.asset("assets/10864-radar-gougo.json"),

          ],
        )
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Image.asset("assets/appLogo.jpg"),
            //     Text("Go Pride",
            //     style: TextStyle(
            //       fontSize: 30,
            //       fontWeight: FontWeight.bold
            //     ),)
            //   ],
            // )
        // Lottie.asset('assets/34273-mercedes.json')
        )
    );
  }
}