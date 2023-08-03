import 'package:flutter/material.dart';
import 'package:go_pride/Driver_Pannel/profile_screen.dart';
import 'package:go_pride/constants/constants.dart';

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({Key? key,}) : super(key: key);

  @override
  _CustomNavBarState createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  int _selectedIndex = 0;
  bool isSelected=false;
  void _handleIconPressed(int index) {
    setState(() {
      _selectedIndex = index;
      isSelected=isSelected;
    });
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double height = 56;
    const primaryColor = Colors.orange;
    const secondaryColor = Colors.black54;
    const backgroundColor = Colors.white;

    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size.width, height + 6),
            painter: BottomNavCurvePainter(backgroundColor: Colors.white),
          ),
          Center(
            heightFactor: 0.6,
            child: FloatingActionButton(
                backgroundColor: primaryColor,
                elevation: 0.1,
                onPressed: () {
                  // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>QuizScreen()));
                },
                child: const Icon(Icons.question_answer_outlined)),
          ),
          SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavBarIcon(
                  text: "Home",
                  icon: Icons.home_outlined,
                  selected: _selectedIndex==0,
                  onPressed:() {
                    _handleIconPressed(0);
                    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
                  },
                  defaultColor: secondaryColor,
                  selectedColor: primaryColor,
                ),
                NavBarIcon(
                  text: "Profile",
                  icon: Icons.person,
                  selected: _selectedIndex==1,
                  onPressed:() {
                    _handleIconPressed(1);
                    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>DriverProfileScreen()));
                  },
                  selectedColor: primaryColor,
                  defaultColor: secondaryColor,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavCurvePainter extends CustomPainter {
  BottomNavCurvePainter({this.backgroundColor = Colors.white, this.insetRadius = 38});

  Color backgroundColor;
  double insetRadius;
  @override
  void paint(Canvas canvas, Size size) {

    Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    Path path = Path()..moveTo(0, 12);

    double insetCurveBeginnningX = size.width / 2 - insetRadius;
    double insetCurveEndX = size.width / 2 + insetRadius;
    double transitionToInsetCurveWidth = size.width * .05;
    path.quadraticBezierTo(size.width * 0.20, 0,
        insetCurveBeginnningX - transitionToInsetCurveWidth, 0);
    path.quadraticBezierTo(
        insetCurveBeginnningX, 0, insetCurveBeginnningX, insetRadius / 2);

    path.arcToPoint(Offset(insetCurveEndX, insetRadius / 2),
        radius: const Radius.circular(10.0), clockwise: false);

    path.quadraticBezierTo(
        insetCurveEndX, 0, insetCurveEndX + transitionToInsetCurveWidth, 0);
    path.quadraticBezierTo(size.width * 0.80, 0, size.width, 12);
    path.lineTo(size.width, size.height + 56);
    path.lineTo(
        0,
        size.height +
            56); //+56 here extends the navbar below app bar to include extra space on some screens (iphone 11)
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class NavBarIcon extends StatelessWidget {
  const NavBarIcon(
      {Key? key,
        required this.text,
        required this.icon,
        required this.selected,
        this.selectedColor = const Color(0xffFF8527),
        this.defaultColor = Colors.black54,
        required this.onPressed,
      })
      : super(key: key);
  final String text;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final Color defaultColor;
  final Color selectedColor;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: onPressed,
          child: Icon(
              icon,
              size: 25,
              color: selected?secondaryColor:primaryColor

          ),
        ),
        Text(text,style: TextStyle(
            color: selected?secondaryColor:primaryColor
        ),)
      ],
    );
  }
}

