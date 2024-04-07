import 'dart:convert';

import 'package:flutter_thesis_project/beacon_loc_request.dart';
import 'package:flutter_thesis_project/screensize_converter.dart';
import 'package:http/http.dart' as http;

class Beacon {
  int id;
  double x;
  double y;
  String name;
  String macAddress;
  int? floorId;

  Beacon({
    required this.id,
    required this.x,
    required this.y,
    required this.name,
    required this.macAddress,
    this.floorId
  });
  
  factory Beacon.empty() {
    return Beacon(id: -1, x: 0, y: 0, name: "", macAddress: "");
  }
  
  void setFloorId(int floorId) {
    this.floorId = floorId;
  }
  
  bool isEmpty() {
    if (id == -1 && x == 0 && y == 0 && name.isEmpty && macAddress.isEmpty) {
      return true;
    }
    
    return false;
  }
  
  int getFloorId() {
    return floorId ?? -1;
  }
}

Future<Beacon> fetchBeaconInfoFromMacAddress(String macAddress, GeoScaledUnifiedMapper geoScaledUnifiedMapper) async {
  final formattedMacAddress = macAddress.replaceAll(":", "%3A");
  final formattedUri = Uri.parse('http://159.223.40.229:8080/api/v1/beacons/macAddress/$formattedMacAddress');
  
  try {
    print("Requesting...");
    final response = await http.get(formattedUri);
  
    if (response.statusCode == 200) {
      print(response.body);
      var geoBeacon = GeoBeacon.fromJson(jsonDecode(response.body));
      var beacon = Beacon(
        id: geoBeacon.id,
        x: geoScaledUnifiedMapper.getWidthPixel(geoBeacon.geoX, geoBeacon.getFloorId()),
        y: geoScaledUnifiedMapper.getHeightPixel(geoBeacon.geoY, geoBeacon.getFloorId()),
        name: geoBeacon.name,
        macAddress: geoBeacon.macAddress
      );
      return beacon;
    } else {
      //throw Exception("Failed to fetch Location of said beacon");
    }
  } on Exception catch(_) {
    print("Failed to make get request");
  }
  
  return Beacon.empty();
}