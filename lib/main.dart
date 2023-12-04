import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_thesis_project/beacon_loc.dart';
import 'package:flutter_thesis_project/bluetooth.dart';
import 'package:flutter_thesis_project/permissions.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_thesis_project/screensize_converter.dart';

const REFRESH_RATE = 1;
const LONGEST_TIME_BEFORE_DEVICE_REMOVAL_SEC = 5;

void main() {
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

class MainBody extends State<MainPage> with TickerProviderStateMixin {
  double? heading = 0;
  double coordinateXValue = 0;
  double coordinateYValue = 0;

  static var screenConverter = ScreenSizeConverter();

  final TransformationController mapTransformationController =
      TransformationController();
  Animation<Matrix4>? mapAnimationReset;
  late final AnimationController mapControllerReset;

  static List<Image> mapFloor = <Image>[
    Image.asset(
      "assets/map/map_1.png",
      scale: 1.0,
      height: screenConverter.getHeightPixel(0.75),
      width: screenConverter.getWidthPixel(0.75),
    ),
    Image.asset(
      "assets/map/map_1_white.png",
      scale: 1.0,
      height: screenConverter.getHeightPixel(0.75),
      width: screenConverter.getWidthPixel(0.75),
    ),
  ];

  int mapFloorIndex = 0;
  Timer? refreshTimer;

  Beacon currentBeaconInfo = Beacon.empty();
  HashMap<String, Beacon> beaconMap = HashMap();

  void onMapAnimationReset() {
    mapTransformationController.value = mapAnimationReset!.value;
    if (!mapControllerReset.isAnimating) {
      mapAnimationReset!.removeListener(onMapAnimationReset);
      mapAnimationReset = null;
      mapControllerReset.reset();
    }
  }

  void mapAnimationResetInitialize() {
    mapControllerReset.reset();
    mapAnimationReset = Matrix4Tween(
      begin: mapTransformationController.value,
      end: Matrix4.identity(),
    ).animate(mapControllerReset);
    mapAnimationReset!.addListener(onMapAnimationReset);
    mapControllerReset.forward();
  }

  // Stop the reset to inital position transform animation.
  void mapAnimateResetStop() {
    mapControllerReset.stop();
    mapAnimationReset?.removeListener(onMapAnimationReset);
    mapAnimationReset = null;
    mapControllerReset.reset();
  }

  // If user translate during the initial position transform animation, the animation cancel and follow the user.
  void _onInteractionStart(ScaleStartDetails details) {
    if (mapControllerReset.status == AnimationStatus.forward) {
      mapAnimateResetStop();
    }
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    mapControllerReset.dispose();
    super.dispose();
  }

  // To Scan Bluetooth: Uncomment this
  var bluetoothNotifier = BluetoothNotifier();

  @override
  void initState() {
    super.initState();
    initPermissionRequest();

    // Init Compass heading
    FlutterCompass.events!.listen((event) {
      setState(() {
        heading = event.heading;
      });
    });

    mapControllerReset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Does a simple bluetooth scan and prints the result to the console.
    // To actually get the data from this, please check out how to use flutter's ChangeNotifier
    bluetoothNotifier.init();
    bluetoothNotifier
        .setScannerStatusStreamCallback(onBluetoothStatusChangeHandler);
    bluetoothNotifier.scan();

    refreshTimer =
        Timer.periodic(const Duration(seconds: REFRESH_RATE), (timer) {
      bluetoothNotifier.clearOldDevices(LONGEST_TIME_BEFORE_DEVICE_REMOVAL_SEC);
      fetchPosition();
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
          bluetoothNotifier.nearestDevice.id);
    }

    if (beaconInfo.isEmpty()) {
      print("Beacon not found in database");
    } else  {
      beaconMap[bluetoothNotifier.nearestDevice.id] = beaconInfo;
    }

    setState(() {
      currentBeaconInfo = beaconInfo!;

      if (!beaconInfo.isEmpty()) {
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

  void setMapFloorByIndex(int floor) {
    setState(() {
      mapFloorIndex = floor % mapFloor.length;
    });
  }

  int getCurrentMapFloorIndex() {
    return mapFloorIndex % mapFloor.length;
  }

  @override
  Widget build(BuildContext context) {
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
            SizedBox(
              height: screenConverter.getHeightPixel(0.9),
              child: mainMap(
                  context,
                  mapTransformationController,
                  _onInteractionStart,
                  heading,
                  coordinateXValue,
                  coordinateYValue,
                  mapFloor,
                  mapFloorIndex,
                  screenConverter,
                  currentBeaconInfo),
            )
          ],
        ),
      ),
      floatingActionButton: constructFloorSelectorFloatingActionBar(context),
    );
  }

  Column constructFloorSelectorFloatingActionBar(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 40,
          child: FittedBox(
            child: FloatingActionButton(
              heroTag: "9F",
              backgroundColor: getCurrentMapFloorIndex() == 1
                  ? Colors.blue
                  : Theme.of(context).colorScheme.inversePrimary,
              foregroundColor:
                  getCurrentMapFloorIndex() == 1 ? Colors.white : Colors.black,
              onPressed: () => setMapFloorByIndex(1),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(100),
                  topRight: Radius.circular(100),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: const Text(
                "9F",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: FittedBox(
            child: FloatingActionButton(
              heroTag: "8F",
              backgroundColor: getCurrentMapFloorIndex() == 0
                  ? Colors.blue
                  : Theme.of(context).colorScheme.inversePrimary,
              foregroundColor:
                  getCurrentMapFloorIndex() == 0 ? Colors.white : Colors.black,
              onPressed: () => setMapFloorByIndex(0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                  bottomLeft: Radius.circular(100),
                  bottomRight: Radius.circular(100),
                ),
              ),
              child: const Text(
                "8F",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        )
      ],
    );
  }
}

Column cadrantAngle(BuildContext context, screenConverter, heading) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        height: screenConverter.getHeightPixel(0.01),
        width: screenConverter.getWidthPixel(0.6),
      ),
      Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            "assets/compass/cadrant.png",
            scale: 1.0,
            height: screenConverter.getHeightPixel(0.1),
            width: screenConverter.getWidthPixel(0.15),
          ),
          Transform.rotate(
            angle: ((heading ?? 0) * (pi / 180) * -1),
            child: Image.asset(
              "assets/compass/compass.png",
              scale: 6.0,
              height: screenConverter.getHeightPixel(0.05),
              width: screenConverter.getWidthPixel(0.05),
            ),
          ),
        ],
      ),
      Text(
        '${heading!.ceil()}',
        style: const TextStyle(
            color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

InteractiveViewer mainMap(
    BuildContext context,
    mapTransformationController,
    onInteractionStart,
    heading,
    coordinateXValue,
    coordinateYValue,
    mapFloor,
    mapFloorIndex,
    screenConverter,
    currentBeaconInfo) {
  return InteractiveViewer(
    transformationController: mapTransformationController,
    minScale: 0.1,
    maxScale: 2.0,
    onInteractionStart: onInteractionStart,
    boundaryMargin: const EdgeInsets.all(double.infinity),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Transform.rotate(
          angle: 0,
          child: Stack(
            children: [
              Center(
                child: Transform.translate(
                  offset: Offset(
                    screenConverter.getHeightPixel(coordinateXValue),
                    screenConverter.getWidthPixel(coordinateYValue),
                  ),
                  child: mapFloor[mapFloorIndex],
                ),
              ),
              Visibility(
                visible: mapFloorIndex == 0 && currentBeaconInfo.getFloor() == 8 || mapFloorIndex == 1 && currentBeaconInfo.getFloor() == 9,
                child: SizedBox(
                  height: screenConverter.getHeightPixel(0.75),
                  width: screenConverter.getWidthPixel(1.0),
                  child: Center(
                    child: Container(
                      height: 24,
                      width: 24,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
