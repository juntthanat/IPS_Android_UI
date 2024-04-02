import 'dart:convert';
import 'dart:io';

import 'package:flutter_thesis_project/beacon_loc.dart';
import 'package:flutter_thesis_project/screensize_converter.dart';
import 'package:http/http.dart' as http;

class GeoBeacon {
  final int id;
  final String name;
  final double geoX;
  final double geoY;
  final String macAddress;

  GeoBeacon({required this.id, required this.name, required this.geoX, required this.geoY, required this.macAddress});
  
  factory GeoBeacon.empty() {
    return GeoBeacon(id: -1, name: "", geoX: 0, geoY: 0, macAddress: "");
  }
  
  factory GeoBeacon.fromJson(Map<String, dynamic> json) {
    return GeoBeacon(id: json["beaconId"], name: json["name"], geoX: json["geoX"], geoY: json["geoY"], macAddress: json["macAddress"]);
  }
  
  bool isEmpty() {
    if (id == -1 && name == "" && geoX == 0 && geoY == 0 && macAddress == "") {
      return true;
    }
    return false;
  }
}

class GeoBeaconList {
  final List<GeoBeacon> geoBeaconList;

  GeoBeaconList({required this.geoBeaconList});

  factory GeoBeaconList.fromJson(List<dynamic> jsonList) {
    List<GeoBeacon> tempGeoBeaconList = List.empty(growable: true);

    jsonList.forEach((element) {
      var tempGeoBeacon = GeoBeacon(id: element["beaconId"], name: element["name"], geoX: element["geoX"], geoY: element["geoY"], macAddress: element["macAddress"]);
      tempGeoBeaconList.add(tempGeoBeacon);
    });

    return GeoBeaconList(geoBeaconList: tempGeoBeaconList);
  }
  
  List<Beacon> getBeacons(int mapFloorIndex) {
    List<Beacon> result = List.empty(growable: true);

    geoBeaconList.forEach((element) {
      var tempBeacon = Beacon(
        id: element.id,
        x: GeoScaledUnifiedMapper.getWidthPixel(element.geoX, mapFloorIndex),
        y: GeoScaledUnifiedMapper.getHeightPixel(element.geoY, mapFloorIndex),
        name: element.name,
        macAddress: element.macAddress
      );
      
      result.add(tempBeacon);
    });

    return result;
  }
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

Future<FloorBeaconList> fetchAllFloorBeaconsByFloor(int mapFloorNumber) async {
  const base_uri = 'http://159.223.40.229:8080/api/v1';

  try {
    var uri = Uri.parse("$base_uri/floor-beacons/floorId/$mapFloorNumber");
    final response = await http.get(uri);
  
    if (response.statusCode == 200) {
      print(response.body);
       return FloorBeaconList.fromJson(jsonDecode(response.body));
    } else {
      print("Response Status NOT 200");
    }
  } on Exception catch(_) {
    print("Failed to make get request");
  }
  
  return FloorBeaconList.empty();
}

Future<List<Beacon>> fetchBeaconListFromIdList(List<int> idList, int mapFloorIndex) async {
  const base_uri = 'http://159.223.40.229:8080/api/v1/beacons/beacon-id-list';
  final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
  Map<String, List<int>> http_param = { "beaconIdList": idList };

  try {
    var uri = Uri.parse(base_uri);
    final response = await http.post(uri, headers: headers, body: json.encode(http_param));
  
    if (response.statusCode == 200) {
	    var geoBeaconList = GeoBeaconList.fromJson(jsonDecode(response.body));
      return geoBeaconList.getBeacons(mapFloorIndex);
    } else {
      //throw Exception("Failed to fetch Location of said beacon");
    }
  } on Exception catch(e) {
    print("Failed to make get request");
    print(e);
  }
  
  return List.empty();
}

Future<List<GeoBeacon>> fetchGeoBeaconsFromNameQuery(String name) async {
  const base_uri = '159.223.40.229:8080';
  final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
  Map<String, String> http_param = { "name": name };

  try {
    var uri = Uri.http(base_uri, "/api/v1/beacons/string-query", http_param);
    final response = await http.get(uri, headers: headers);
  
    if (response.statusCode == 200) {
	    var geoBeaconList = GeoBeaconList.fromJson(jsonDecode(response.body));
      return geoBeaconList.geoBeaconList;
    } else {
      //throw Exception("Failed to fetch Location of said beacon");
    }
  } on Exception catch(e) {
    print("Failed to make get request");
    print(e);
  }
  
  return List.empty();
}

Future<GeoBeacon> fetchGeoBeaconFromExactNameQuery(String name) async {
  const base_uri = '159.223.40.229:8080';
  final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
  Map<String, String> http_param = { "name": name };

  try {
    var uri = Uri.http(base_uri, "/api/v1/beacons/exact-string-query", http_param);
    final response = await http.get(uri, headers: headers);
  
    if (response.statusCode == 200) {
	    return GeoBeacon.fromJson(jsonDecode(response.body));
    } else {
      //throw Exception("Failed to fetch Location of said beacon");
    }
  } on Exception catch(e) {
    print("Failed to make get request");
    print(e);
  }
  
  return GeoBeacon.empty();
}

Future<FloorBeaconList> fetchFloorBeaconListFromIdList(List<int> idList) async {
  final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
  List<String> idListAsString = List.empty(growable: true);

  idList.forEach((element) => idListAsString.add(element.toString()));

  try {
    var uri = Uri.http("159.223.40.229:8080", "/api/v1/floor-beacons/beaconId", { "beaconIdList" : idListAsString });
    final response = await http.get(uri, headers: headers);
    print(response.body);

    if (response.statusCode == 200) {
      FloorBeaconList floorBeaconList = FloorBeaconList.fromJson(jsonDecode(response.body));
      return floorBeaconList;
    }

  } on Exception catch(e) {
    print("Failed to make get request");
    print(e);
  }

  return FloorBeaconList.empty();
}
