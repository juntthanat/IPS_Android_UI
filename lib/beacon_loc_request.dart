import 'dart:collection';
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
  int? floorId;

  GeoBeacon({required this.id, required this.name, required this.geoX, required this.geoY, required this.macAddress, this.floorId});
  
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
  
  void setFloorId(int floorId) {
    this.floorId = floorId;
  }

  int getFloorId() {
    return floorId ?? -1;
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
  
  List<Beacon> getBeacons(GeoScaledUnifiedMapper geoScaledUnifiedMapper, int floorId) {
    List<Beacon> result = List.empty(growable: true);

    geoBeaconList.forEach((element) {
      var tempBeacon = Beacon(
        id: element.id,
        x: geoScaledUnifiedMapper.getWidthPixel(element.geoX, floorId),
        y: geoScaledUnifiedMapper.getHeightPixel(element.geoY, floorId),
        name: element.name,
        macAddress: element.macAddress,
        floorId: floorId
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

class FloorInfo {
  final int floorId;
  final String name;
  final double geoLength;
  final double geoWidth;
  final double azimuth;
  final int level;

  const FloorInfo({
    required this.floorId,
    required this.name,
    required this.geoLength,
    required this.geoWidth,
    required this.azimuth,
    required this.level
  });
}

class FloorFileInfo {
  final int floorFileId;
  final int floorId;
  final int fileId;

  const FloorFileInfo({
    required this.floorFileId,
    required this.floorId,
    required this.fileId,
  });
}

class FloorFileInfoList {
  final List<FloorFileInfo> floorFileInfoList;

  FloorFileInfoList({required this.floorFileInfoList});  
  
  factory FloorFileInfoList.fromJson(List<dynamic> jsonList) {
    List<FloorFileInfo> floorFileInfoTempList = List.empty(growable: true);
    jsonList.forEach((element) {
      var tempFloorFileInfo = FloorFileInfo(floorFileId: element["floorFileId"], floorId: element["floorId"], fileId: element["fileId"]);
      floorFileInfoTempList.add(tempFloorFileInfo);
    }); 
    
    return FloorFileInfoList(floorFileInfoList: floorFileInfoTempList);
  }
}

class FloorFileDimensionAndLink {
  int fileId;
  String name;
  String downloadUrl;
  int pixelWidth;
  int pixelHeight;

  FloorFileDimensionAndLink({
    required this.fileId,
    required this.name,
    required this.downloadUrl,
    required this.pixelWidth,
    required this.pixelHeight
  });
}

class FloorFileDimensionAndLinkList {
  List<FloorFileDimensionAndLink> floorFileDimensionAndLinkList;
  
  FloorFileDimensionAndLinkList({
    required this.floorFileDimensionAndLinkList
  });

  factory FloorFileDimensionAndLinkList.fromJson(List<dynamic> jsonList) {
    List<FloorFileDimensionAndLink> floorFileDimensionAndLinkTempList = List.empty(growable: true);
    jsonList.forEach((element) {
      var temp = FloorFileDimensionAndLink(
        fileId: element["fileId"],
        name: element["name"],
        downloadUrl: element["downloadUrl"],
        pixelWidth: element["pixelWidth"],
        pixelHeight: element["pixelHeight"]
      );
      floorFileDimensionAndLinkTempList.add(temp);
    }); 

    return FloorFileDimensionAndLinkList(floorFileDimensionAndLinkList: floorFileDimensionAndLinkTempList);
  }
}

class BasicFloorInfo {
  int floorId;
  int floorLevel;
  String name;

  BasicFloorInfo({
    required this.floorId,
    required this.floorLevel,
    required this.name,
  });
}

Future<HashMap<int, FloorInfo>> fetchAllFloors() async {
  const base_uri = 'http://159.223.40.229:8080/api/v1';
  
  // Floor Id and Info Map
  HashMap<int, FloorInfo> floorInfoList = HashMap();

  try {
    var uri = Uri.parse("$base_uri/floors");
    final response = await http.get(uri);
  
    if (response.statusCode == 200) {
      print(response.body);
      List<dynamic> jsonList = jsonDecode(response.body);
      jsonList.forEach((element) {
        var floorInfo = FloorInfo(
          floorId: element["floorId"],
          name: element["name"],
          geoLength: element["geoLength"],
          geoWidth: element["geoWidth"],
          azimuth: element["azimuth"],
          level: element["level"]
        );
        floorInfoList[floorInfo.floorId] = floorInfo;
      });
    } else {
      print("Response Status NOT 200");
    }
  } on Exception catch(_) {
    print("Failed to make get request");
  }
  
  return floorInfoList;
}

Future<HashMap<int, FloorFileDimensionAndLink>> fetchAllFloorFileDimensionAndLink() async {
  const base_uri = 'http://159.223.40.229:8080/api/v1';
  
  // File ID and Info Map
  HashMap<int, FloorFileDimensionAndLink> floorFileDimensionAndLinkMap = HashMap();

  try {
    var uri = Uri.parse("$base_uri/files");
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      FloorFileDimensionAndLinkList tempResultList = FloorFileDimensionAndLinkList.fromJson(jsonDecode(response.body));
      tempResultList.floorFileDimensionAndLinkList.forEach((element) {
        floorFileDimensionAndLinkMap[element.fileId] = element;
      });
    }
  } on Exception catch(e) {
    print("Failed to get Floor File Links");
    print(e);
  }
  
  return floorFileDimensionAndLinkMap;
}

Future<List<FloorFileInfo>> fetchAllFileInfo() async {
  const base_uri = 'http://159.223.40.229:8080/api/v1/floor-files';
  List<FloorFileInfo> result = List.empty();

  try {
    var uri = Uri.parse(base_uri);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      var floorFileInfoList = FloorFileInfoList.fromJson(jsonDecode(response.body));
      result = floorFileInfoList.floorFileInfoList;
    }
  } on Exception catch(_) {
    print("Failed to make File Info Fetch request");
  }
  
  return result;
}

Future<FloorBeaconList> fetchAllFloorBeaconsByFloor(int floorId) async {
  const base_uri = 'http://159.223.40.229:8080/api/v1';

  try {
    var uri = Uri.parse("$base_uri/floor-beacons/floorId/$floorId");
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

Future<List<Beacon>> fetchBeaconListFromIdList(List<int> idList, GeoScaledUnifiedMapper geoScaledUnifiedMapper, int floorId) async {
  const base_uri = 'http://159.223.40.229:8080/api/v1/beacons/beacon-id-list';
  final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
  Map<String, List<int>> http_param = { "beaconIdList": idList };

  try {
    var uri = Uri.parse(base_uri);
    final response = await http.post(uri, headers: headers, body: json.encode(http_param));
  
    if (response.statusCode == 200) {
	    var geoBeaconList = GeoBeaconList.fromJson(jsonDecode(response.body));
      return geoBeaconList.getBeacons(geoScaledUnifiedMapper, floorId);
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
  var geoBeacon = GeoBeacon.empty();

  try {
    var uri = Uri.http(base_uri, "/api/v1/beacons/exact-string-query", http_param);
    final response = await http.get(uri, headers: headers);
  
    if (response.statusCode == 200) {
	    geoBeacon = GeoBeacon.fromJson(jsonDecode(response.body));
    } else {
      //throw Exception("Failed to fetch Location of said beacon");
    }
  } on Exception catch(e) {
    print("Failed to make get request");
    print(e);
  }
  
  try {
    if (geoBeacon.isEmpty()) {
      return geoBeacon;
    }

    var uri = Uri.http(base_uri, "/api/v1/floor-beacons/beaconId/${geoBeacon.id}");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      geoBeacon.setFloorId(jsonDecode(response.body)["floorId"]);
    }
  } on Exception catch(e) {
    print("Failed to fetch Beacon's Floor Info");
    print(e);
  }
  
  return geoBeacon;
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
