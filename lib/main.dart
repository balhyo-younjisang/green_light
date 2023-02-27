// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Green Light', home: GetLocation());
  }
}

class GetLocation extends StatefulWidget {
  const GetLocation({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _GetLocationState createState() => _GetLocationState();
}

class _GetLocationState extends State<GetLocation> {
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  late GoogleMapController mapController;
  double? lat;
  double? lng;
  Location location = Location();

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _permission() async {
    // Check if location service is enable
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Check if permission is granted
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  void _callApi() async {
    String endpointUrl =
        'http://t-data.seoul.go.kr/apig/apiman-gateway/tapi/v2xSignalPhaseTimingInformation/1.0';
    Map<String, String> queryParams = {
      'apiKey': '64a651c1-a611-4716-97bb-ad20df53dd71',
      'type': 'json',
      'pageNo': '1',
      'numOfRows': '1',
    };

    Uri queryString =
        Uri.parse(endpointUrl).replace(queryParameters: queryParams);
    var res = await http.get(queryString);
    log(queryString.toString());
    var responseBody = res.body;
    log(responseBody);
  }

  void _getUserLocation() {
    //Get location when moving
    location.changeSettings(
        interval: 300000,
        distanceFilter:
            5); // If 10 sec are passed and if the phone is moved al least 5 meters
    location.onLocationChanged.listen((LocationData currentLocation) {
      log(currentLocation.toString());
      _callApi();
      setState(() {
        lat = currentLocation.latitude;
        lng = currentLocation.longitude;
      });
    });
  }

  @override
  void initState() {
    _permission();
    super.initState();
    _getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition:
            CameraPosition(target: LatLng(lat!, lng!), zoom: 18.0),
        myLocationButtonEnabled: true, // 구글맵의 gps 위치 확대 버튼 on/off
        myLocationEnabled: true,
      ),
    );
  }
}
