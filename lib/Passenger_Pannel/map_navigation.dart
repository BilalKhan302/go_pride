// import 'dart:async';
// import 'dart:math' show cos, sqrt, asin;
//
// import 'package:flutter/material.dart';
// import 'package:go_pride/Passenger_Pannel/passenger_homeScreen.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class NavigationScreen extends StatefulWidget {
//   final double lat;
//   final double lng;
//
//   NavigationScreen(this.lat, this.lng);
//
//   @override
//   State<NavigationScreen> createState() => _NavigationScreenState();
// }
//
// class _NavigationScreenState extends State<NavigationScreen> {
//   final Completer<GoogleMapController> _controller = Completer();
//   Map<PolylineId, Polyline> polylines = {};
//   PolylinePoints polylinePoints = PolylinePoints();
//   GeolocatorPlatform geolocator = GeolocatorPlatform.instance;
//   Marker? sourcePosition, destinationPosition;
//   LatLng curLocation = LatLng(23.0525, 72.5667);
//   StreamSubscription<Position>? locationSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     getNavigation();
//     addMarker();
//   }
//
//   @override
//   void dispose() {
//     locationSubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: sourcePosition == null
//           ? Center(child: CircularProgressIndicator())
//           : Stack(
//         children: [
//           GoogleMap(
//             zoomControlsEnabled: false,
//             polylines: Set<Polyline>.of(polylines.values),
//             initialCameraPosition: CameraPosition(
//               target: curLocation,
//               zoom: 16,
//             ),
//             markers: {sourcePosition!, destinationPosition!},
//             onTap: (latLng) {
//               print(latLng);
//             },
//             onMapCreated: (GoogleMapController controller) {
//               _controller.complete(controller);
//             },
//           ),
//           Positioned(
//             top: 30,
//             left: 15,
//             child: GestureDetector(
//               onTap: () {
//                 Navigator.of(context).pushAndRemoveUntil(
//                   MaterialPageRoute(
//                     builder: (context) => PassengerHomeScreen(),
//                   ),
//                       (route) => false,
//                 );
//               },
//               child: Icon(Icons.arrow_back),
//             ),
//           ),
//           Positioned(
//             bottom: 10,
//             right: 10,
//             child: Container(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.blue,
//               ),
//               child: Center(
//                 child: IconButton(
//                   icon: Icon(
//                     Icons.navigation_outlined,
//                     color: Colors.white,
//                   ),
//                   onPressed: () async {
//                     await launchUrl(Uri.parse(
//                         'google.navigation:q=${widget.lat}, ${widget.lng}&key=AIzaSyBvgLiwLroLIcwfPEprKxl1LGzIouVW-y8'));
//                   },
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void getNavigation() async {
//     LocationPermission permission;
//     bool serviceEnabled = await geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: const Text('Location Service Disabled'),
//             content: const Text('Please enable location services.'),
//             actions: <Widget>[
//               TextButton(
//                 child: const Text('OK'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//             ],
//           );
//         },
//       );
//       return;
//     }
//
//     permission = await geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await geolocator.requestPermission();
//       if (permission != LocationPermission.whileInUse &&
//           permission != LocationPermission.always) {
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: const Text('Location Permission Denied'),
//               content: const Text(
//                   'Please grant location permission to use this feature.'),
//               actions: <Widget>[
//                 TextButton(
//                   child: const Text('OK'),
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                 ),
//               ],
//             );
//           },
//         );
//         return;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: const Text('Location Permission Denied'),
//             content: const Text(
//                 'Location permissions are permanently denied. We cannot request permissions.'),
//             actions: <Widget>[
//               TextButton(
//                 child: const Text('OK'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               ),
//             ],
//           );
//         },
//       );
//       return;
//     }
//
//     Position currentPosition = await geolocator.getCurrentPosition();
//     curLocation = LatLng(currentPosition.latitude, currentPosition.longitude);
//
//     locationSubscription = geolocator.getPositionStream().listen((Position position) {
//       CameraUpdate cameraUpdate = CameraUpdate.newCameraPosition(
//         CameraPosition(
//           target: LatLng(position.latitude, position.longitude),
//           zoom: 16,
//         ),
//       );
//
//       if (_controller.isCompleted) {
//         _controller.future.then((GoogleMapController controller) {
//           controller.animateCamera(cameraUpdate);
//           controller.showMarkerInfoWindow(sourcePosition!.markerId);
//         });
//       }
//
//       setState(() {
//         curLocation = LatLng(position.latitude, position.longitude);
//         sourcePosition = Marker(
//           markerId: MarkerId('source'),
//           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
//           position: curLocation,
//           infoWindow: InfoWindow(
//             title: '${double.parse(getDistance(LatLng(widget.lat, widget.lng)).toStringAsFixed(2))} km',
//           ),
//           onTap: () {
//             print('marker tapped');
//           },
//         );
//       });
//
//       getDirections(LatLng(widget.lat, widget.lng));
//     });
//   }
//
//   void getDirections(LatLng dst) async {
//     List<LatLng> polylineCoordinates = [];
//     List<PointLatLng> points = [];
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       'AIzaSyBvgLiwLroLIcwfPEprKxl1LGzIouVW-y8',
//       PointLatLng(curLocation.latitude, curLocation.longitude),
//       PointLatLng(dst.latitude, dst.longitude),
//       travelMode: TravelMode.driving,
//     );
//
//     if (result.points.isNotEmpty) {
//       result.points.forEach((PointLatLng point) {
//         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//         points.add(PointLatLng(point.latitude, point.longitude));
//       });
//     } else {
//       print(result.errorMessage);
//     }
//
//     addPolyline(polylineCoordinates);
//   }
//
//   void addPolyline(List<LatLng> polylineCoordinates) {
//     PolylineId id = PolylineId('poly');
//     Polyline polyline = Polyline(
//       polylineId: id,
//       color: Colors.blue,
//       points: polylineCoordinates,
//       width: 5,
//     );
//     polylines[id] = polyline;
//     setState(() {});
//   }
//
//   double calculateDistance(lat1, lon1, lat2, lon2) {
//     var p = 0.017453292519943295;
//     var c = cos;
//     var a = 0.5 -
//         c((lat2 - lat1) * p) / 2 +
//         c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
//     return 12742 * asin(sqrt(a));
//   }
//
//   double getDistance(LatLng destPosition) {
//     return calculateDistance(
//       curLocation.latitude,
//       curLocation.longitude,
//       destPosition.latitude,
//       destPosition.longitude,
//     );
//   }
//
//   void addMarker() {
//     setState(() {
//       sourcePosition = Marker(
//         markerId: MarkerId('source'),
//         position: curLocation,
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//       );
//       destinationPosition = Marker(
//         markerId: MarkerId('destination'),
//         position: LatLng(widget.lat, widget.lng),
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
//       );
//     });
//   }
// }
