// import 'package:flutter/foundation.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert' as convert;
//
// class LocationService {
//   final String key = 'AIzaSyBuyAx7S32Cpjr6P05KkJc8ji9UfaAtVao';
//
//   Future<String> getPlaceId(String input) async {
//     final String url =
//         'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key';
//
//     var response = await http.get(Uri.parse(url));
//     var json = convert.jsonDecode(response.body);
//     var placeId = json['candidates'][0]['place_id'] as String;
//
//     return placeId;
//   }
//
//   Future<Map<String, dynamic>> getPlace(String input) async {
//     final placeId = await getPlaceId(input);
//
//     final String url =
//         'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key';
//
//     var response = await http.get(Uri.parse(url));
//     var json = convert.jsonDecode(response.body);
//     var results = json['result'] as Map<String, dynamic>;
//
//     print(results);
//     return results;
//   }
//
//   Future<Map<String, dynamic>> getDirections(
//       String origin, String destination) async {
//     final String url =
//         'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$key';
//
//     var response = await http.get(Uri.parse(url));
//     var json = convert.jsonDecode(response.body);
//
//     var results = {
//       'bounds_ne': json['routes'][0]['bounds']['northeast'],
//       'bounds_sw': json['routes'][0]['bounds']['southwest'],
//       'start_location': json['routes'][0]['legs'][0]['start_location'],
//       'end_location': json['routes'][0]['legs'][0]['end_location'],
//       'polyline': json['routes'][0]['overview_polyline']['points'],
//       'polyline_decoded': PolylinePoints()
//           .decodePolyline(json['routes'][0]['overview_polyline']['points']),
//     };
//
//     print(results);
//
//     return results;
//   }
// }
// class Directions {
//   final LatLngBounds bounds;
//   final List<PointLatLng> polylinePoints;
//   final String totalDistance;
//   final String totalDuration;
//
//   const Directions({
//     required this.bounds,
//     required this.polylinePoints,
//     required this.totalDistance,
//     required this.totalDuration,
//   });
//
//   factory Directions.fromMap(Map<String, dynamic> map) {
//     // Check if route is not available
//     if ((map['routes'] as List).isEmpty);
//
//     // Get route information
//     final data = Map<String, dynamic>.from(map['routes'][0]);
//
//     // Bounds
//     final northeast = data['bounds']['northeast'];
//     final southwest = data['bounds']['southwest'];
//     final bounds = LatLngBounds(
//       northeast: LatLng(northeast['lat'], northeast['lng']),
//       southwest: LatLng(southwest['lat'], southwest['lng']),
//     );
//
//     // Distance & Duration
//     String distance = '';
//     String duration = '';
//     if ((data['legs'] as List).isNotEmpty) {
//       final leg = data['legs'][0];
//       distance = leg['distance']['text'];
//       duration = leg['duration']['text'];
//     }
//
//     return Directions(
//       bounds: bounds,
//       polylinePoints:
//       PolylinePoints().decodePolyline(data['overview_polyline']['points']),
//       totalDistance: distance,
//       totalDuration: duration,
//     );
//   }
// }