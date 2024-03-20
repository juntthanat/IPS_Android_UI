import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoBeacon {
  final int id;
  final String name;
  final double geoX;
  final double geoY;
  final String macAddress;

  GeoBeacon({required this.id, required this.name, required this.geoX, required this.geoY, required this.macAddress});
}

class FloorBeacon {
  final int floorBeaconId;
  final int floorId;
  final int beaconId;
  
  FloorBeacon({required this.floorBeaconId, required this.floorId, required this.beaconId});
}

class FloorBeaconList {
  final List<FloorBeacon> beaconList;

  FloorBeaconList({required this.beaconList});

  factory FloorBeaconList.fromJson(List<dynamic> jsonList) {
    List<FloorBeacon> tempFloorBeaconList = List.empty(growable: true);
    jsonList.forEach((element) {
	var tempFloorBeacon = FloorBeacon(
	    floorBeaconId: element["floorBeaconId"],
	    floorId: element["floorId"],
	    beaconId: element["beaconId"],
	);
	tempFloorBeaconList.add(tempFloorBeacon);
    });
    return FloorBeaconList(beaconList: tempFloorBeaconList);
  }

  factory FloorBeaconList.empty() {
    return FloorBeaconList(beaconList: List.empty());
  }
}

Future<FloorBeaconList> fetchAllBeaconsByFloor(int mapFloorNumber) async {
  const base_uri = 'http://159.223.40.229:8080/api/v1';

  try {
    var uri = Uri.parse("$base_uri/floor-beacons/floorId/$mapFloorNumber");
    final response = await http.get(uri);
  
    if (response.statusCode == 200) {
      print(response.body);
       return FloorBeaconList.fromJson(jsonDecode(response.body));
    } else {
      //throw Exception("Failed to fetch Location of said beacon");
    }
  } on Exception catch(_) {
    print("Failed to make get request");
  }
  
  return FloorBeaconList.empty();
}