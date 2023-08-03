import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_pride/constants/bottomNavBar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/constants.dart';
import '../services/notification_services.dart';
import 'package:url_launcher/url_launcher.dart';
class DriverHomeScreen extends StatefulWidget {
  final String id ;
  const DriverHomeScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => DriverHomeScreenState();
}

class DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isDisposed = false;
  int currentIndex = 0;
  String ?fcmToken='';
  final _auth = FirebaseAuth.instance;
  double successfulTrips=0;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin=FlutterLocalNotificationsPlugin();
  GoogleMapController? _mapController;
  final TextEditingController textController = TextEditingController();
  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(30.3753, 69.3451),
    zoom: 15, // Increase the zoom level here
  );


  Polyline? polyline;
  //token

  List<LatLng> points = [];
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polyline = {};
  NotificationServices notificationServices = NotificationServices();

  //ride requests stream
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Stream<QuerySnapshot<Map<String, dynamic>>>? rideRequestsStream;
  @override
  void initState() {
    super.initState();
    notificationServices.requestNotificationPermission();
    notificationServices.forgroundMessage();
    notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);
    notificationServices.isTokenRefresh();
    //requests
    rideRequestsStream = firestore
        .collection('rideRequests')
        .where('status', isEqualTo: 'pending')
        .where('driverId',isEqualTo: _auth.currentUser!.uid)
        .snapshots();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestLocationPermission();
    getDeviceToken();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Cancel any ongoing asynchronous operations here
    super.dispose();
  }

  void getDeviceToken() async {
    String? token = await messaging.getToken();
    if(mounted){
      setState(() {
        fcmToken = token;
        print("my token is: $fcmToken");
      });
    }
    saveToken(token!);
  }


  void _addMarker(LatLng position, String markerId, BitmapDescriptor icon) {
    Marker marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: icon,
    );
    if(mounted){
      setState(() {
        _markers.removeWhere((marker) =>
        marker.markerId.value ==
            markerId); // Remove existing marker with the same ID
        _markers.add(marker);
      });
    }

  }
  late LatLng originLatLng;
  late LatLng destinationLatLng;

  void _drawRoute() {
    if (originLatLng == null || destinationLatLng == null) {
      print('Origin or destination coordinates are null.');
      return;
    }
    if(mounted){
      setState(() {
        _markers.clear();
        _polyline.clear();
        _addMarker(
          originLatLng!,
          'Origin',
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        );
        _addMarker(
          destinationLatLng!,
          'Destination',
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        );

        _polyline.add(Polyline(
          polylineId: PolylineId('originToDestination'),
          color: Colors.blue,
          points: [originLatLng, destinationLatLng],
        ));

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
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      });

    }
  }


  String? origin;
  String ?destination;

  void acceptRequest(String requestId) async {
    DocumentSnapshot<Map<String, dynamic>> requestSnapshot =
    await firestore.collection('rideRequests').doc(requestId).get();
    updateRequestStatus(requestId, 'accepted');
    setState(() {
      successfulTrips+=1;

    });
    firestore
        .collection('rideRequests')
        .doc(requestId)
        .update({
      'successfulTrips':successfulTrips
    });
    if (requestSnapshot.exists) {
      var request = requestSnapshot.data();
      if (request != null) {
        String? origin = request['origin'];
        String? destination = request['destination'];
        if (origin == null || destination == null) {
          print('Origin or destination is null.');
          return;
        }

        try {
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
            if(mounted){
              setState(() {
                _markers.clear();
                _polyline.clear();
                _addMarker(
                  originLatLng,
                  'Origin',
                  BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
                );
                _addMarker(
                  destinationLatLng,
                  'Destination',
                  BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                );
                _polyline.add(Polyline(
                  polylineId: PolylineId('originToDestination'),
                  color: Colors.blue,
                  points: [originLatLng, destinationLatLng],
                ));

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
                _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
              });

            }

            RideRequest rideRequest =
            RideRequest(origin: origin, destination: destination);
          } else {
            print('Unable to find coordinates for the origin or destination');
          }
        } catch (e) {
          print('Error occurred during geocoding: $e');
          // Handle the error here, such as showing an error message to the user
        }
      }
    }
  }


  void rejectRequest(String requestId) {
    updateRequestStatus(requestId, 'rejected');
  }

  void updateRequestStatus(String requestId, String status) {
    firestore
        .collection('rideRequests')
        .doc(requestId)
        .update({'status': status});


  }


  void saveToken(String token)async{
    String driverId=_auth.currentUser!.uid;
    CollectionReference driversCollection =
    FirebaseFirestore.instance.collection('driver');
    DocumentReference driverDocRef = driversCollection.doc(driverId);
    DocumentSnapshot driverSnapshot = await driverDocRef.get();
    if (driverSnapshot.exists) {
      // Update the driver's FCM token
      await driverDocRef.update({
        'token': token,

      });
      print('Driver FCM token saved successfully.');
    } else {
      print('Driver document does not exist.');
    }
  }
  bool _showRequestDialog = false; // Add a state variable to control the visibility of the dialog

  _showRideRequestDialog({required String requestId, required String origin, required String destination}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Ride Request'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Origin: $origin'),
              Text('Destination: $destination'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Accept the request
                acceptRequest(requestId);
                Navigator.of(context).pop();
                if(mounted){
                  setState(() {
                    _showRequestDialog = false; // Update the state variable to hide the dialog
                  });
                }// Dismiss the dialog

              },
              child: Text('Accept'),
            ),
            ElevatedButton(
              onPressed: () {
                // Reject the request
                rejectRequest(requestId);
                Navigator.of(context).pop(); // Dismiss the dialog
                setState(() {
                  _showRequestDialog = false; // Update the state variable to hide the dialog
                });
              },
              child: Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Driver Pannel"),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 2,
        leading: IconButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut().then((value) => Navigator.pop(context));
          },
          icon: Icon(Icons.logout_outlined),
        ),
      ),
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: IndexedStack(
        index: currentIndex,
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: rideRequestsStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final requests = snapshot.data!.docs;

                // Check if there are pending requests
                if (requests.isNotEmpty && !_showRequestDialog) {
                  // Get the details of the first pending request
                  var request = requests[0].data();
                  String origin = request['origin'];
                  String destination = request['destination'];

                  // Show the dialog only when there are pending requests and _showRequestDialog is false
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    if (!_isDisposed) {
                      setState(() {
                        _showRequestDialog = true; // Update the state variable to show the dialog
                      });
                    }
                    _showRideRequestDialog(
                      requestId: requests[0].id,
                      origin: origin,
                      destination: destination,
                    );
                  });
                }
              }

              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height*0.7,
                      child: GoogleMap(
                        markers: _markers,
                        myLocationEnabled: true,
                        mapType: MapType.normal,
                        initialCameraPosition: _kGooglePlex,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          _controller.complete(controller);
                        },
                        polylines: _polyline,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor
                              ),
                              onPressed: () async {
                                await launchUrl(Uri.parse(
                                    'google.navigation:q=${originLatLng.latitude}, ${originLatLng.longitude}&key=AIzaSyBvgLiwLroLIcwfPEprKxl1LGzIouVW-y8'));
                              }, child: Text("Passenger Pickup")),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor
                              ),
                              onPressed: () async {
                                await launchUrl(Uri.parse(
                                    'google.navigation:q=${destinationLatLng.latitude}, ${destinationLatLng.longitude}&key=AIzaSyBvgLiwLroLIcwfPEprKxl1LGzIouVW-y8'));
                              }, child: Text("Passenger Drop"))
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
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
  Timer? _timer;
  Future<void> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng latLng = LatLng(position.latitude, position.longitude);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    if(mounted){
      setState(() {
        points.add(latLng);
        polyline = Polyline(
          polylineId: PolylineId('path'),
          color: Colors.blue,
          points: points,
        );
      });

    }

    StreamSubscription<Position> positionStream =
    Geolocator.getPositionStream(
    ).listen((Position newPosition) async {
      LatLng newLatLng = LatLng(newPosition.latitude, newPosition.longitude);
      controller.animateCamera(CameraUpdate.newLatLng(newLatLng));
      if(mounted){
        setState(() {
          points.add(newLatLng);
          polyline = polyline!.copyWith(pointsParam: points);
        });
      }

      _timer?.cancel();

      _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
        // Save the driver's position to Firestore
        CollectionReference driversCollection =
        FirebaseFirestore.instance.collection('driver');

        DocumentReference driverDocRef = driversCollection.doc(_auth.currentUser!.uid);
        QuerySnapshot<Map<String, dynamic>> positionSnapshot = await driverDocRef.collection('position').get();
        // Delete old positions
        positionSnapshot.docs.forEach((positionDoc) {
          positionDoc.reference.delete();
        });
        driverDocRef.collection('position').add({
          'latitude': newLatLng.latitude,
          'longitude': newLatLng.longitude,
        });
      });
      // Save the driver's position to Firestore

    });
  }


  Future<void> search() async {
    List<Location> locations = await locationFromAddress(textController.text);

    Location location = locations.first;
    CameraPosition _search = CameraPosition(
      bearing: 192.8334901395799,
      tilt: 59.440717697143555,
      target: LatLng(
        location.latitude.toDouble(),
        location.longitude.toDouble(),
      ),
      zoom: 15,
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_search));
  }
}
