import 'dart:convert';

import 'package:http/http.dart' as http;

class Beacon {
  int id;
  double x;
  double y;
  String name;
  String macAddress;

  Beacon({
    required this.id,
    required this.x,
    required this.y,
    required this.name,
    required this.macAddress
  });
  
  factory Beacon.fromJson(Map<String, dynamic> json) {
    return Beacon(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      name: json['name'],
      macAddress: json['macAddress'],
    );
  }
  
  factory Beacon.empty() {
    return Beacon(id: -1, x: 0, y: 0, name: "", macAddress: "");
  }
  
  bool isEmpty() {
    if (id == -1 && x == 0 && y == 0 && name.isEmpty && macAddress.isEmpty) {
      return true;
    }
    
    return false;
  }
  
  int getFloor() {
    if (name.contains("ECC7") || name == "7") {
      return 7;
    } else if (name.contains("ECC8") || name == "8") {
      return 8;
    } else if (name.contains("ECC9") || name == "9") {
      return 9;
    }
    
    return -1;
  }
  
  int getFloorIndex() {
    if (name.contains("ECC7")) {
      return 0;
    } else if (name.contains("ECC8")) {
      return 1;
    }
    
    return -1;
  }
}

Future<Beacon> fetchBeaconInfoFromMacAddress(String macAddress) async {
  final formattedMacAddress = macAddress.replaceAll(":", "%3A");
  final formattedUri = Uri.parse('http://159.223.40.229:8080/api/v1/beacon/macAddress?macAddress=$formattedMacAddress');
  
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
    print("Failed to make get request");
  }
  
  return Beacon.empty();
}