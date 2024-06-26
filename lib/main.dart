import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_thesis_project/beacon_loc.dart';
import 'package:flutter_thesis_project/beacon_loc_request.dart';
import 'package:flutter_thesis_project/bluetooth.dart';
import 'package:flutter_thesis_project/floor_selector.dart';
import 'package:flutter_thesis_project/mqtt.dart';
import 'package:flutter_thesis_project/map.dart';
import 'package:flutter_thesis_project/navigation.dart';
import 'package:flutter_thesis_project/permissions.dart';
import 'package:flutter_thesis_project/search_bar.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_thesis_project/screensize_converter.dart';

const REFRESH_RATE = 1;
const LONGEST_TIME_BEFORE_DEVICE_REMOVAL_SEC = 5;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(const Duration(milliseconds: 300)); 
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return const MaterialApp(
      title: 'My app',
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  MainBody createState() => MainBody();
}

class MainBody extends State<MainPage> {
  double? heading = 0;
  double coordinateXValue = 0;
  double coordinateYValue = 0;

  static var screenConverter = ScreenSizeConverter();
  late GeoScaledUnifiedMapper geoScaledUnifiedMapper;
  late ImageRatioMapper imageRatioMapper;

  HashMap<int, Image> floorImages = HashMap();
  HashMap<int, MapDimension> floorDimensions = HashMap();
  List<BasicFloorInfo> basicFloorInfoList = List.empty(growable: true);

  SelectedFloor selectedFloor = SelectedFloor(id: 1);
  Timer? refreshTimer;

  Beacon currentBeaconInfo = Beacon.empty();
  HashMap<String, Beacon> beaconMap = HashMap();

  List<Beacon> beaconsToRender = List.empty(growable: true);
  Beacon selectedBeacon = Beacon.empty();

  final GlobalKey<InteractiveMapState> _key = GlobalKey();
  late InteractiveMap interactiveMap;
  
  EnableNavigate enableNavigate = EnableNavigate();
  Dio dio = Dio();

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  // To Scan Bluetooth: Uncomment this
  var bluetoothNotifier = BluetoothNotifier();
  var mqttHandler = MQTTConnectionHandler();

  @override
  void initState() {
    super.initState();
    initPermissionRequest();

    dio.interceptors.add(CacheInterceptor());
   
    () async {
      // Getting Floor Images and Dimensions
      List<FloorFileInfo> fileInfo = await fetchAllFileInfo(dio);
      HashMap<int, FloorInfo> floorInfo = await fetchAllFloors(dio);
      HashMap<int, FloorFileDimensionAndLink> fileImageLink = await fetchAllFloorFileDimensionAndLink(dio);
      
      for (var element in fileInfo) {
        FloorInfo? tempFloorFileInfo = floorInfo[element.floorId];
        FloorFileDimensionAndLink? tempFileLinkInfo = fileImageLink[element.fileId];
        
        if (tempFloorFileInfo == null || tempFileLinkInfo == null) {
          continue;
        }
        
        var floorMapDimension = MapDimension(
          tempFloorFileInfo.geoLength,
          tempFloorFileInfo.geoWidth,
          tempFileLinkInfo.pixelWidth.toDouble(),
          tempFileLinkInfo.pixelHeight.toDouble()
        );

        floorImages[element.floorId] = Image(
          image: CachedNetworkImageProvider(tempFileLinkInfo.downloadUrl, scale: 1.0),
          height: screenConverter.getHeightPixel(0.75),
          width: screenConverter.getWidthPixel(0.75),
        );
        floorDimensions[element.floorId] = floorMapDimension;

        // Populate Basic Floor Info List for Floating action button rendering
        var tempBasicFloorInfo = BasicFloorInfo(floorId: tempFloorFileInfo.floorId, floorLevel: tempFloorFileInfo.level, name: tempFloorFileInfo.name);
        basicFloorInfoList.add(tempBasicFloorInfo);
      }
      
      // Populate the beaconsToRender List
      FloorBeaconList floorBeaconList = await fetchAllFloorBeaconsByFloor(dio, selectedFloor.getId());
      List<Beacon> allBeaconsOfFloor = await fetchBeaconListFromIdList(
        dio,
        floorBeaconList.beaconList.map((e) => e.beaconId).toList(),
        geoScaledUnifiedMapper,
        selectedFloor.getId()
      );

      beaconsToRender.clear();
      beaconsToRender.addAll(allBeaconsOfFloor);
    }.call();
    
    // Initialize the Coordinate Mappers
    geoScaledUnifiedMapper = GeoScaledUnifiedMapper(floorDimensions);
    imageRatioMapper = ImageRatioMapper(floorDimensions, floorImages);

    interactiveMap = InteractiveMap(
      key: _key,
      coordinateXValue: coordinateXValue,
      coordinateYValue: coordinateYValue,
      floorImages: floorImages,
      currentFloorId: selectedFloor.getId(),
      currentBeaconInfo: currentBeaconInfo,
      beaconsToRender: beaconsToRender,
      selectedBeacon: selectedBeacon,
      enableNavigate: enableNavigate,
      imageRatioMapper: imageRatioMapper,
    );

    // Init Compass heading
    FlutterCompass.events!.listen((event) {
      setState(() {
        heading = event.heading;
      });
    });

    // Does a simple bluetooth scan and prints the result to the console.
    // To actually get the data from this, please check out how to use flutter's ChangeNotifier
    bluetoothNotifier.init();
    bluetoothNotifier
        .setScannerStatusStreamCallback(onBluetoothStatusChangeHandler);
    bluetoothNotifier.scan();

    mqttHandler.setOnConnected(
        () => mqttHandler.subscribe("LOLICON/BEACON/CALIBRATION"));
    mqttHandler.connect();
    mqttHandler.setCallback((c) {
      final message = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      try {
        final payload_json = json.decode(payload) as Map<String, dynamic>;
        bluetoothNotifier.setDeviceRssiDiff(
            payload_json['macAddress'], payload_json['diff']);
        print(
            'macAddress: ${payload_json['macAddress']}, RSSI: ${payload_json['rssi']}, diff: ${payload_json['diff']}');
      } catch (e) {
        return;
      }
    });

    refreshTimer =
        Timer.periodic(const Duration(seconds: REFRESH_RATE), (timer) {
      bluetoothNotifier.clearOldDevices(LONGEST_TIME_BEFORE_DEVICE_REMOVAL_SEC);
      fetchPosition();
      
      if (
        !selectedBeacon.isEmpty() &&
        enableNavigate.getState() &&
        selectedBeacon.x.toInt() == coordinateXValue.toInt() &&
        selectedBeacon.y.toInt() == coordinateYValue.toInt()
      ) {
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Reached Destination'),
            content: const Text('You\'ve Reached Your Destination!'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        enableNavigate.setState(false);
      }
    });
  }

  // Fetches the position of the nearest Bluetooth Beacon
  void fetchPosition() async {
    if (bluetoothNotifier.nearestDevice.isEmpty()) {
      return;
    }
    print(
        "id: ${bluetoothNotifier.nearestDevice.id}    rssi: ${bluetoothNotifier.nearestDevice.rssi}");

    Beacon? beaconInfo = beaconMap[bluetoothNotifier.nearestDevice.id];
    if (beaconInfo == null) {
      print("Fetching data...");
      beaconInfo = await fetchBeaconInfoFromMacAddress(
        bluetoothNotifier.nearestDevice.id,
        geoScaledUnifiedMapper,
      );
    }

    if (beaconInfo.isEmpty()) {
      print("Beacon not found in database");
    } else {
      beaconMap[bluetoothNotifier.nearestDevice.id] = beaconInfo;
    }

    setState(() {
      currentBeaconInfo = beaconInfo!;

      if (!beaconInfo.isEmpty()) {
        // TODO: Properly Implement getFloor
        coordinateXValue = currentBeaconInfo.x;
        coordinateYValue = currentBeaconInfo.y;
      }
    });
  }

  // Requests and Validates App Permissions
  // If Permission is not granted, app Settings will be opened recursively until permission is granted
  Future<Map<Permission, PermissionStatus>> initPermissionRequest() async {
    Map<Permission, PermissionStatus> permissionStatus = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (permissionStatus[Permission.locationWhenInUse] ==
        PermissionStatus.denied) {
      await initPermissionRequest();
    } else if (permissionStatus[Permission.locationWhenInUse] ==
        PermissionStatus.permanentlyDenied) {
      if (context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (cntx) => const RequestLocationPermissionPage()));
      }
    }

    return permissionStatus;
  }

  void onBluetoothStatusChangeHandler(BleStatus status) {
    switch (status) {
      case BleStatus.unknown:
        sleep(const Duration(microseconds: 500));
      case BleStatus.ready:
        return;
      case BleStatus.poweredOff:
        if (context.mounted) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (cntx) =>
                  TurnOnBluetoothPage(bluetoothNotifier: bluetoothNotifier)));
        }
        break;
      default:
        print("Unknown BleStatus: ${status.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    interactiveMap = InteractiveMap(
      key: _key,
      coordinateXValue: coordinateXValue,
      coordinateYValue: coordinateYValue,
      floorImages: floorImages,
      currentFloorId: selectedFloor.getId(),
      currentBeaconInfo: currentBeaconInfo,
      beaconsToRender: beaconsToRender,
      selectedBeacon: selectedBeacon,
      enableNavigate: enableNavigate,
      imageRatioMapper: imageRatioMapper,
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: screenConverter
            .getHeightPixel(0.05), // Header (Location Map) Height
        backgroundColor: Colors.grey.shade900,
        centerTitle: true,
        title: const Text("Location Map"),
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Visibility(
                visible: enableNavigate.getState(),
                child: Container(
                  height: screenConverter.getHeightPixel(0.15),
                  width: screenConverter.getWidthPixel(0.25),
                  color: Colors.grey[900],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      NavigationArrow(
                        x: coordinateXValue,
                        y: coordinateYValue,
                        selectedBeacon: selectedBeacon,
                        selectedFloorId: selectedFloor.getId(),
                        enableNavigate: enableNavigate,
                      ),
                      NavigationCancelButton(enableNavigate: enableNavigate),
                    ],
                  ),
                ),
              ),
              Container(
                // Header (Compass)
                height: screenConverter
                    .getHeightPixel(0.15), // Header (Compass) Height
                width: enableNavigate.getState() ? screenConverter.getWidthPixel(0.75) : screenConverter.getWidthPixel(1.0), // Header (Compass) Width
                color: Colors.grey[900],
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        alignment: Alignment.center,
                        height: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: AsyncAutocomplete(
                                  selectedBeacon: selectedBeacon,
                                  enableNavigate: enableNavigate,
                                  currentFloorId: selectedFloor.getId(),
                                  basicFloorInfoList: basicFloorInfoList,
                                  geoScaledUnifiedMapper: geoScaledUnifiedMapper,
                                  dio: dio
                              ),
                            )
                          ],
                          /* // Start (Input X, Input Y, and reset button)
                        // End (Input X, Input Y, and Reset Button) */
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            SizedBox(
              height: screenConverter.getHeightPixel(0.75),
              child: interactiveMap,
            )
          ],
        ),
      ),
      floatingActionButton:
          constructFloorSelectorFloatingActionBar(context, beaconsToRender),
    );
  }

  Column constructFloorSelectorFloatingActionBar(
      BuildContext context,
      List<Beacon> beaconsToRender
  ) {
    basicFloorInfoList.sort((a, b) => b.floorLevel.compareTo(a.floorLevel));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (var basicFloorInfo in basicFloorInfoList)
          FloorSelectorButton(
            floorLevel: basicFloorInfo.floorLevel,
            floorId: basicFloorInfo.floorId,
            currentlySelectedFloor: selectedFloor,
            beaconsToRender: beaconsToRender,
            geoScaledUnifiedMapper: geoScaledUnifiedMapper,
            dio: dio,
            floorState: basicFloorInfo == basicFloorInfoList[0] ? FloorState.top : basicFloorInfo == basicFloorInfoList[basicFloorInfoList.length - 1] ? FloorState.bottom : FloorState.normal,
          )
      ],
    );
  }
}

class CacheInterceptor extends Interceptor {
  CacheInterceptor();

  final _cache = <(Uri, dynamic), Response>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final response = _cache[(options.uri, options.data)];
    if (options.extra['refresh'] == true) {
      print('${options.uri}: force refresh, ignore cache! \n');
      return handler.next(options);
    } else if (response != null) {
      print('cache hit: ${options.uri} \n');
      return handler.resolve(response);
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 200) {
      _cache[(response.requestOptions.uri, response.requestOptions.data)] = response;
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('onError: $err');
    super.onError(err, handler);
  }
}