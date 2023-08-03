import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_pride/constants/constants.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
class DriverProfileScreen extends StatefulWidget {
  final String reqId;
  final String driverId;
  final String name;
  final String email;
  final String carModel;
  final String carColor;
  final String phone;
  final String numberplateNo;

  DriverProfileScreen({
    required this.reqId,
    required this.driverId,
    required this.name,
    required this.email,
    required this.carModel,
    required this.carColor,
    required this.phone,
    required this.numberplateNo,
  });

  @override
  _DriverProfileScreenState createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  double successfulTrips = 0; // Initialize successfulTrips to 0

  @override
  void initState() {
    super.initState();
    getSuccessfulTrips(widget.reqId);
    // Update the driver's data in Firestore with the new rating details
// Fetch successful trips when the screen is initialized
  }

// ...

  Future<void> addRatingToDriver(String driverId, int rating) async {
    try {
      // Get a reference to the driver document in Firestore
      CollectionReference driversCollection =
      FirebaseFirestore.instance.collection('driver');
      DocumentReference driverDocRef = driversCollection.doc(driverId);
      // Update the driver's data in Firestore with the new rating details
      await driverDocRef.update({
        'ratings': 0, // Initial rating count (0)
        'totalRatings': 0, // Initial total ratings count (0)
        'averageRating': 0.0, // Initial average rating (0.0)
      });


      // Get the current driver's data from Firestore
      DocumentSnapshot driverSnapshot = await driverDocRef.get();
      Map<String, dynamic> driverData = driverSnapshot.data() as Map<String, dynamic>;

      // Calculate the new average rating and update the total ratings count
      int currentRatings = driverData['ratings'] ?? 0;
      int currentTotalRatings = driverData['totalRatings'] ?? 0;
      double currentAverageRating = driverData['averageRating'] ?? 0.0;

      int newTotalRatings = currentTotalRatings + 1;
      int newRatings = currentRatings + rating;
      double newAverageRating = newRatings / newTotalRatings;

      // Update the driver's data in Firestore with the new rating details
      await driverDocRef.update({
        'ratings': newRatings,
        'totalRatings': newTotalRatings,
        'averageRating': newAverageRating,
      });

      // Show a success message or perform any other actions if needed
      print('Rating added successfully!');
    } catch (e) {
      // Handle any errors that may occur during the process
      print('Error adding rating: $e');
    }
  }


  Future<double> getSuccessfulTrips(String requestId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('rideRequests')
        .doc(requestId)
        .get();
    setState(() {
      successfulTrips = snapshot['successfulTrips'] ?? 0;
    });
    return successfulTrips;
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: Text(widget.name),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: height * 0.3,
                  width: width,
                  child: Lottie.asset("assets/63142-bike.json")),
              Text(
                'Driver Name:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                widget.name,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Email:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                widget.email,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Car Model:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                widget.carModel,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Car Color:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                widget.carColor,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Phone:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                widget.phone,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Number Plate No:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                widget.numberplateNo,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Successful Trips:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  successfulTrips.toString(),
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Center(
                child: RatingBar.builder(
                  initialRating: 0,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 20.0,
                  itemBuilder: (context, _) => Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    // Call a function to save the rating to Firestore
                    // For example, you can use the addRatingToDriver function mentioned earlier
                    addRatingToDriver(widget.driverId, rating.toInt());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
