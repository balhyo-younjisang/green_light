// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert';
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

class Info {
  String? ntPdsgStatNm; // 북쪽 보행 신호
  String? etPdsgStatNm; // 동쪽 보행 신호
  String? stPdsgStatNm; // 남쪽 보행 신호
  String? wtPdsgStatNm; // 서쪽 보행 신호
  String? nePdsgStatNm; // 북동 보행 신호
  String? sePdsgStatNm; // 남동 보행 신호
  String? swPdsgStatNm; // 남서 보행 신호
  String? nwPdsgStatNm; // 북서 보행 신호

  Info(
      {this.ntPdsgStatNm,
      this.etPdsgStatNm,
      this.stPdsgStatNm,
      this.wtPdsgStatNm,
      this.nePdsgStatNm,
      this.sePdsgStatNm,
      this.swPdsgStatNm,
      this.nwPdsgStatNm});

  // Json Decode
  Info.fromJson(Map<dynamic, dynamic> json)
      : ntPdsgStatNm = json['ntPdsgStatNm'],
        etPdsgStatNm = json['etPdsgStatNm'],
        stPdsgStatNm = json['stPdsgStatNm'],
        wtPdsgStatNm = json['wtPdsgStatNm'],
        nePdsgStatNm = json['nePdsgStatNm'],
        sePdsgStatNm = json['sePdsgStatNm'],
        swPdsgStatNm = json['swPdsgStatNm'],
        nwPdsgStatNm = json['nwPdsgStatNm'];

  // Json encode
  Map<String, dynamic> toJson() => {
        'ntPdsgStatNm': ntPdsgStatNm,
        'etPdsgStatNm': etPdsgStatNm,
        'stPdsgStatNm': stPdsgStatNm,
        'wtPdsgStatNm': wtPdsgStatNm,
        'nePdsgStatNm': nePdsgStatNm,
        'sePdsgStatNm': sePdsgStatNm,
        'swPdsgStatNm': swPdsgStatNm,
        'nwPdsgStatNm': nwPdsgStatNm
      };
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

  //called API
  void _callApi() async {
    String remainTimeApiEndpointUrl =
        'http://t-data.seoul.go.kr/apig/apiman-gateway/tapi/v2xSignalPhaseTimingInformation/1.0'; // <-- 잔여 시간 정보
    String signalInfoEndpointUrl =
        'http://t-data.seoul.go.kr/apig/apiman-gateway/tapi/v2xSignalPhaseInformation/1.0'; //<-- 신호 정보

    Map<String, String> queryParams = {
      'apiKey': '64a651c1-a611-4716-97bb-ad20df53dd71',
      'type': 'json',
      'pageNo': '1',
      'numOfRows': '1',
    };

    Uri remainTimeQueryString = Uri.parse(remainTimeApiEndpointUrl)
        .replace(queryParameters: queryParams);
    var remainTimeRes = await http.get(remainTimeQueryString);

    Uri signalInfoQueryString =
        Uri.parse(signalInfoEndpointUrl).replace(queryParameters: queryParams);
    var signalInfoRes = await http.get(signalInfoQueryString);

    log(remainTimeRes.body.toString());
    log(signalInfoRes.body.toString());
    String infoMap = jsonDecode(signalInfoRes.body
        .toString()); // <-- Unhandled Exception: type 'List<dynamic>' is not a subtype of type 'Map<dynamic, String>'
    var info = Info.fromJson(infoMap as Map);
    log(info.etPdsgStatNm.toString());
  }

  void _getUserLocation() {
    //Get location when moving
    location.changeSettings(
        interval: 30000,
        distanceFilter:
            5); // If 30000 ms are passed and if the phone is moved al least 5 meters
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
