import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../Driver_Pannel/profile_screen.dart';
import '../constants/constants.dart';
import '../services/notification_services.dart';

class PassengerHomeScreen extends StatefulWidget {
  String? name;
  String? phone;
  String? email;
  PassengerHomeScreen({Key? key, this.email, this.name, this.phone})
      : super(key: key);

  @override
  _PassengerHomeScreenState createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  Stream<QuerySnapshot> driverStream =
      FirebaseFirestore.instance.collection('drivers').snapshots();

  String polylineKey =
      'AIzaSyBvgLiwLroLIcwfPEprKxl1LGzIouVW-y8'; // Replace with your Google Maps API key
//collection firestore
  final CollectionReference rideRequestsRef =
      FirebaseFirestore.instance.collection('rideRequests');
  GoogleMapController? _mapController;
  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();
  double _distance = 0.0;
  double _time = 0.0;
  final _auth = FirebaseAuth.instance;
  final TextEditingController textController = TextEditingController();
  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(30.3753, 69.3451),
    zoom: 15, // Increase the zoom level here
  );
  NotificationServices notificationServices = NotificationServices();
  Polyline? polyline;
  //token

  List<LatLng> points = [];
  final Set<Marker> _markers = {};
  final Set<Polyline> _polyline = {};
  late LatLng driverPosition;
  late LatLng destinationLatLng;
  late LatLng originLatLng;
  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    driverPositionSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    //requests
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser!.uid;
    DocumentReference rideRequestDoc = rideRequestsRef.doc(userId);
    rideRequestDoc.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        String? status = (snapshot.data() as Map<String, dynamic>)['status'];
        String? passengerPickup =
            (snapshot.data() as Map<String, dynamic>)['origin'];
        if (status == 'accepted') {
          showPopup('Your ride request has been accepted!', passengerPickup!);
        } else if (status == 'rejected') {
          showPopup('Your ride request has been rejected.', '');
        }
      }
    });

    requestLocationPermission();
    listenToDriverPositions();
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.forgroundMessage();
    notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);
    notificationServices.isTokenRefresh();

    notificationServices.getDeviceToken().then((value) {
      if (kDebugMode) {
        print('device token');
        print(value);
      }
    });
  }

  Future<void> makePolyline(String PickUp) async {
    List<Location> originResults = await locationFromAddress(PickUp);

    if (originResults.isNotEmpty) {
      LatLng originPassenger = LatLng(
        originResults.first.latitude,
        originResults.first.longitude,
      );

      _markers.clear();
      _polyline.clear();
      _addMarker(driverPosition, 'Originof driver',
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose));
      _addMarker(originPassenger, 'userLocation',
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));

      _polyline.add(Polyline(
        polylineId: PolylineId('driver to user'),
        color: Colors.red,
        points: [driverPosition, originPassenger],
      ));

      // Set the map bounds to include the polyline
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          min(driverPosition.latitude, originPassenger.latitude),
          min(driverPosition.longitude, originPassenger.longitude),
        ),
        northeast: LatLng(
          max(driverPosition.latitude, originPassenger.latitude),
          max(driverPosition.longitude, originPassenger.longitude),
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  void showPopup(String message, String PickUp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        elevation: 10,
        backgroundColor: Colors.grey.shade300,
        title: Center(child: Text('Ride Request')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              final FirebaseFirestore firestore =
                  await FirebaseFirestore.instance;
              firestore
                  .collection('rideRequests')
                  .doc(_auth.currentUser!.uid)
                  .update({'status': ''}).then((value) => makePolyline(PickUp));
              Navigator.pop(context);
              //update
            },

            // Close the dialog

            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  //ride request

  void requestRide(
      {String? origin, String? destination, String? driverId}) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userId = currentUser.uid;
      DocumentReference rideRequestDoc = rideRequestsRef.doc(userId);

      await rideRequestDoc.set({
        'driverId': driverId,
        'origin': origin,
        'destination': destination,
        'status': 'pending',
        'passengerId': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: primaryColor,
          content: Text("Ride Created Succesfully")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: primaryColor,
          content: Text("User is not authenticated")));
    }
  }

  void _bookRide(String driverId) async {
    String origin = _originController.text;
    String destination = _destinationController.text;

    try {
      List<Location> originResults = await locationFromAddress(origin);
      List<Location> destinationResults =
          await locationFromAddress(destination);
      requestRide(
        origin: origin,
        destination: destination,
        driverId: driverId,
      );

      if (originResults.isNotEmpty && destinationResults.isNotEmpty) {
        originLatLng = LatLng(
          originResults.first.latitude,
          originResults.first.longitude,
        );
        destinationLatLng = LatLng(
          destinationResults.first.latitude,
          destinationResults.first.longitude,
        );

        currentLatLng = await getCurrentLocation();

        setState(() {
          _markers.clear();
          _polyline.clear();
          _addMarker(originLatLng, 'Origin',
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose));
          _addMarker(destinationLatLng, 'Destination',
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
          _addMarker(
              currentLatLng,
              'CurrentLocation',
              BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange));
          _addMarker(driverPosition, 'Driver',
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed));
          _polyline.add(Polyline(
            polylineId: PolylineId('currentToOrigin'),
            color: Colors.red,
            points: [currentLatLng, originLatLng],
          ));
          _polyline.add(Polyline(
            polylineId: PolylineId('originToDestination'),
            color: Colors.blue,
            points: [originLatLng, destinationLatLng],
          ));

          // Set the map bounds to include the polyline
          LatLngBounds bounds = LatLngBounds(
            southwest: LatLng(
              min(originLatLng.latitude, destinationLatLng.latitude),
              min(originLatLng.longitude, destinationLatLng.longitude),
            ),
            northeast: LatLng(
              max(originLatLng.latitude, destinationLatLng.latitude),
              max(originLatLng.longitude, destinationLatLng.longitude),
            ),
          );
          _mapController!
              .animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        });
        // print(driverFCMToken);
        //ride requests
        //notification using fcm
        String? driverUid = await Constants().getDriverUid();
        print(driverUid);
        DocumentSnapshot snap = await FirebaseFirestore.instance
            .collection('driver')
            .doc(driverUid)
            .get();
        String token = snap['token'];
        sendNotificationToDriver(token);
        // await _calculateDistanceAndTime(currentLatLng, originLatLng);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: primaryColor,
            content: Text(
                "Unable to find coordinates for the origin or destination")));
      }
    } catch (e) {
      // Handle the error here, such as showing an error message to the user
    }

    // Clear the origin and destination fields
    _originController.clear();
    _destinationController.clear();
  }

  Future<double> _calculateDistanceAndTime(
      LatLng origin, LatLng destination) async {
    double distanceInMeters = await Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    double distanceInKilometers = distanceInMeters / 1000;
    double timeInMinutes =
        distanceInMeters / 80; // Assuming average speed of 80 meters per minute

    setState(() {
      _distance = distanceInKilometers;
      _time = timeInMinutes;
      _polyline.add(Polyline(
        polylineId: PolylineId('$_distance'),
        color: Colors.red,
        points: [origin, destination],
      ));
    });

    print('Distance: $_distance km');
    print('Time: $_time minutes');
    return _distance;
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      driverPositionSubscription;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String driverFCMToken = '';
  Future<String> getDeviceToken() async {
    driverFCMToken = (await messaging.getToken())!;
    return driverFCMToken;
  }
  double ?longitudeDriver;
  double ?latitudeDriver;

  Future<void> nearbyDrivers() async {
    if (trackedDrivers.isNotEmpty) {
      CollectionReference driversCollection =
          FirebaseFirestore.instance.collection('driver');
      QuerySnapshot driverSnapshot = await driversCollection.get();

      if (driverSnapshot.docs.isNotEmpty) {
        List<Widget> driverWidgets = [];

        for (QueryDocumentSnapshot docSnapshot in driverSnapshot.docs) {
          Map<String, dynamic> data =
          docSnapshot.data() as Map<String, dynamic>;
          DocumentReference<Map<String, dynamic>> driverRef =
          FirebaseFirestore.instance.collection('driver').doc(data['driverId']);

          // Access the subcollection 'position' of the driver
          CollectionReference<Map<String, dynamic>> positionCollection =
          driverRef.collection('position');
// Get all documents in the 'position' subcollection
          QuerySnapshot<
              Map<String, dynamic>> positionSnapshot = await positionCollection
              .get();
          for (QueryDocumentSnapshot<Map<String, dynamic>> positionDoc
          in positionSnapshot.docs) {
            // Access the data of each document
            Map<String, dynamic> positionData = positionDoc.data();
            latitudeDriver = positionData['latitude'];
            longitudeDriver = positionData['longitude'];

            // Do whatever you want with the position data
            print('Latitude: $latitudeDriver');
            print('Longitude: $latitudeDriver');
          }
          double distanceForDriver = Geolocator.distanceBetween(
            currentLatLng.latitude,
            currentLatLng.longitude,
            latitudeDriver!,
            longitudeDriver!,
          );
          String origin = _originController.text;
          String destination = _destinationController.text;

          List<Location> originResults = await locationFromAddress(origin);
          List<Location> destinationResults =
          await locationFromAddress(destination);

          if (originResults.isNotEmpty && destinationResults.isNotEmpty) {
            originLatLng = LatLng(
              originResults.first.latitude,
              originResults.first.longitude,
            );
            destinationLatLng = LatLng(
              destinationResults.first.latitude,
              destinationResults.first.longitude,
            );
          }
          //amount distance
          double distanceForAmount =
          await _calculateDistanceAndTime(originLatLng, destinationLatLng);
          //distance drivers
          //amount
          double amount = distanceForAmount * 15;
          String amountInString = amount.toStringAsFixed(0);

          String driverId = data['driverId'];
          String name = data['name'];
          String email = data['email'];
          String carModel = data['carModel'];
          String carColor = data['carColor'];
          String phone = data['phone'];
          String numberplateNo = data['numberplateNo'];
          final ratings = data['totalRatings'];
          print("distance:$distanceForDriver");
          String distanceForDrivers = distanceForDriver.toStringAsFixed(0);
          String reqId = _auth.currentUser!.uid;
          //list of drivers

          if (distanceForDriver < 1000) {
            driverWidgets.add(ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DriverProfileScreen(
                              reqId: reqId,
                              driverId: driverId,
                              name: name,
                              email: email,
                              carModel: carModel,
                              carColor: carColor,
                              phone: phone,
                              numberplateNo: numberplateNo,
                            )));
              },
              contentPadding: EdgeInsets.all(10),
              tileColor: Colors.white,
              title: Text('Name: $name'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Car Model: $carModel'),
                  Text('Car Color: $carColor'),
                  Text('Contact: $phone'),
                  Text('Amount: ${amountInString}Rs'),
                  Text('Ratings: ${ratings}'),
                  Text('Distance: ${distanceForDrivers}km'),

                  Divider(thickness: 2,)
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.navigation_outlined, color: primaryColor),
                onPressed: () => _bookRide(driverId),
              ),
            ));
            showDialog(
              context: context,
              builder: (context) =>
                  AlertDialog(
                    elevation: 10,
                    backgroundColor: Colors.grey.shade300,
                    title: Center(child: Text('Nearby Drivers')),
                    content: SingleChildScrollView(
                      child: Column(
                        children: driverWidgets,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child: Text('Cancel'),
                      ),
                    ],
                  ),
            );
          }
          else {
            // No driver documents found in the "driver" collection
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: primaryColor,
                content: Text(
                    "No near by Drivers")));
          }
        }
      }
    }else{
      print("empty");
    }
  }
  Set<String> trackedDrivers = {}; // Track drivers for whom markers have been added
  void listenToDriverPositions() {
    // Unsubscribe from the previous listener, if it exists
    driverPositionSubscription?.cancel();

    CollectionReference driversCollection =
        FirebaseFirestore.instance.collection('driver');
    driverPositionSubscription =
        driversCollection.snapshots().listen((snapshot) {
      Future.forEach(snapshot.docChanges, (driverChange) async {
        String driverId = driverChange.doc.id;
        CollectionReference positionCollection =
            driverChange.doc.reference.collection('position');

        positionCollection.snapshots().listen((positionSnapshot) {
          Future.forEach(positionSnapshot.docChanges, (positionChange) async {
            if (positionChange.type == DocumentChangeType.added) {
              driverPosition = LatLng(
                positionChange.doc['latitude'],
                positionChange.doc['longitude'],
              );
              LatLng currentLatLng = await getCurrentLocation();
              // Calculate distance between current location and driver position
              double distance = Geolocator.distanceBetween(
                currentLatLng.latitude,
                currentLatLng.longitude,
                driverPosition.latitude,
                driverPosition.longitude,
              );
              // Check if the driver is within a certain distance (e.g., 1 kilometer) and not already tracked
              if (distance <= 1000 && !trackedDrivers.contains(driverId)) {
                // Add the driver marker on the map
                _addMarker(
                  driverPosition,
                  'Driver',
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                );

                // Move the camera to the driver's position
                _moveCamera(driverPosition);
                // Mark the driver as tracked
                trackedDrivers.add(driverId);
              }
            }
          });
        });
      });
    }) as StreamSubscription<QuerySnapshot<Map<String, dynamic>>>;
  }

  Future<void> sendNotificationToDriver(String token) async {
    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization':
                'key=AAAA-6oH6vQ:APA91bHqn9yLw5ZPnj_YMOtSBfIROgV0hUaTaoe67UvSN9wVN36xz6ydme2i3E68EEj1cUlUTWwVGVUQZuo-t2eLPUNsWo46-N0eE8VshnmTEtlz_wSgd_iZruBGt29-iHwp5vs6HwUo',
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': 'Your passenger sent you a notification.',
              'title': 'Passenger Notification',
            },
            'notification': <String, dynamic>{
              'body': 'Your passenger sent you a notification.',
              'title': 'Passenger Notification',
            },
            'to': token
          }));
    } catch (e) {
      print(e.toString());
    }
  }

  late LatLng currentLatLng;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      drawer: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(40.0),
              bottomRight: Radius.circular(40.0),
            ),
            child: Drawer(
              width: width * 0.6,
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: primaryColor,
                    ),
                    child: Center(
                      child: Text(
                        'Go Pride',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text(widget.name.toString()),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: Text(widget.phone.toString()),
                  ),
                  ListTile(
                    leading: Icon(Icons.email),
                    title: Text(widget.email.toString()),
                  ),
                ],
              ),
            ),
          )),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: Icon(
          Icons.navigation_outlined,
          color: Colors.white,
        ),
        onPressed: () async {
          await launchUrl(Uri.parse(
              'google.navigation:q=${destinationLatLng.latitude}, ${destinationLatLng.longitude}&key=AIzaSyBvgLiwLroLIcwfPEprKxl1LGzIouVW-y8'));
        },
      ),
      appBar: AppBar(
        actions: [
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                onPressed: () async {
                  try {
                    await _auth.signOut();
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    print('Error occurred during sign-out: $e');
                  }
                },
                icon: Icon(Icons.logout_outlined),
              );
            },
          ),
        ],
        backgroundColor: primaryColor,
        title: const Text('Passenger Panel'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
                markers: _markers,
                myLocationEnabled: true,
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                },
                polylines: _polyline),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _originController,
                  decoration: const InputDecoration(
                    labelText: 'Origin',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor),
                      onPressed: () {
                        nearbyDrivers();
                      },
                      child: const Text('Book Ride'),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor),
                      onPressed: () async {
                        final FirebaseFirestore firestore =
                            await FirebaseFirestore.instance;
                        firestore
                            .collection('rideRequests')
                            .doc(_auth.currentUser!.uid)
                            .update({'status': 'cancel'});
                        _polyline.clear();
                        _markers.clear();
                      },
                      child: const Text('Cancel Ride'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      getCurrentLocation();
    } else {
      print("Location permission denied by user");
    }
  }

  void _addMarker(LatLng position, String markerId, BitmapDescriptor icon) {
    Marker marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: icon,
    );
    setState(() {
      _markers.removeWhere((marker) =>
          marker.markerId.value ==
          markerId); // Remove existing marker with the same ID
      _markers.add(marker);
    });
  }

  void _moveCamera(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    }
  }
  Timer? _timer;
  LatLng? previousLatLng;
//get passenger live location with stream of position changes
  Future<LatLng> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng latLng = LatLng(position.latitude, position.longitude);

    setState(() {
      currentLatLng = latLng;
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    _addMarker(
      latLng,
      'Current Location',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    _moveCamera(latLng);

    // Cancel the previous timer, if any
    StreamSubscription<Position> positionStream =
    Geolocator.getPositionStream().listen((Position newPosition) async {
      LatLng newLatLng = LatLng(newPosition.latitude, newPosition.longitude);

      setState(() {
        currentLatLng = newLatLng;
      });

      // Calculate the distance between the current position and the previous position
      double distance = previousLatLng != null
          ? Geolocator.distanceBetween(
        previousLatLng!.latitude,
        previousLatLng!.longitude,
        newLatLng.latitude,
        newLatLng.longitude,
      )
          : 0;

      if (distance >= 100) {
        // Save the driver's position to Firestore
        CollectionReference passengersCollection =
        FirebaseFirestore.instance.collection('passenger');
        DocumentReference passengerDocRef =
        passengersCollection.doc(_auth.currentUser!.uid);

        // Query the 'position' subcollection to get all documents
        QuerySnapshot<Map<String, dynamic>> positionSnapshot =
        await passengerDocRef.collection('position').get();

        // Delete old positions
        positionSnapshot.docs.forEach((positionDoc) {
          positionDoc.reference.delete();
        });

        // Add the new position
        passengerDocRef.collection('position').add({
          'latitude': newLatLng.latitude,
          'longitude': newLatLng.longitude,
        });

        // Update the previous position to the current position
        previousLatLng = newLatLng;
      }

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(newLatLng));
        setState(() {
          points.add(newLatLng);
          polyline = polyline!.copyWith(pointsParam: points);
        });
      }
      // Update the user's marker position
      _addMarker(newLatLng, 'Current Location',
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));

      // Move the camera to the user's position
      _moveCamera(newLatLng);
    });

    return LatLng(position.latitude, position.longitude);
  }


//get driver live location with stream of position
}
