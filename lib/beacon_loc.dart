import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Beacon {
  int id;
  double x;
  double y;
  String floorName;
  String macAddress;

  Beacon({
    required this.id,
    required this.x,
    required this.y,
    required this.floorName,
    required this.macAddress
  });
  
  factory Beacon.fromJson(Map<String, dynamic> json) {
    return Beacon(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      floorName: json['floorName'],
      macAddress: json['macAddress'],
    );
  }
  
  factory Beacon.empty() {
    return Beacon(id: -1, x: 0, y: 0, floorName: "", macAddress: "");
  }
  
  bool isEmpty() {
    if (id == -1 && x == 0 && y == 0 && floorName.isEmpty && macAddress.isEmpty) {
      return true;
    }
    
    return false;
  }
}

Future<Beacon> fetchBeaconInfoFromMacAddress(String macAddress) async {
  final formattedMacAddress = "FF:00:CC:CC:EE:DD".replaceAll(":", "%3A");
  final formattedUri = Uri.parse('http://marco.cooldev.win:8080/api/v1/beacon/macAddress?macAddress=$formattedMacAddress');
  
  try {
    print("Requesting...");
    final response = await http.get(formattedUri);
  
    if (response.statusCode == 200) {
      print(response.body);
      return Beacon.fromJson(jsonDecode(response.body));
    } else {
      //throw Exception("Failed to fetch Location of said beacon");
    }
  } on Exception catch(_) {
    print("AHHHHHHHHHHHHHHHHHHHHHHHHHHHH");
  }
  
  return Beacon.empty();
}