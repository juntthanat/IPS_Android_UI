import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thesis_project/beacon_loc.dart';
import 'package:flutter_thesis_project/bluetooth.dart';
import 'package:flutter_thesis_project/permissions.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_thesis_project/screensize_converter.dart';
const REFRESH_RATE = 2;
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
      "assets/map/map_2.png",
      scale: 1.0,
    ),
  ];

  int mapFloorIndex = 0;
  Timer? refreshTimer;

  Beacon currentBeaconInfo = Beacon.empty();

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
    bluetoothNotifier.scan();

    refreshTimer = Timer.periodic(const Duration(seconds: REFRESH_RATE), (timer) {
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
    Beacon beaconInfo =
        await fetchBeaconInfoFromMacAddress(bluetoothNotifier.nearestDevice.id);

    if (beaconInfo.isEmpty()) {
      print("Beacon not found in database");
    }

    setState(() {
      currentBeaconInfo = beaconInfo;
      
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
            Container(
              height: screenConverter
                  .getHeightPixel(0.15), // Header (Compass) Height
              width: screenConverter.getWidthPixel(1), // Header (Compass) Width
              color: Colors.grey[900],
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const SizedBox(
                      //   width: double.infinity,
                      // ),
                      cadrantAngle(context, screenConverter, heading),
                    ],
                  ),
                  Positioned.fill(
                    child: Container(
                      alignment: Alignment.center,
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              onChanged: (inputX) {
                                setState(() {
                                  if (inputX == "" || inputX == "-") {
                                    coordinateXValue = 0;
                                  } else if (inputX[0] == "-") {
                                    String nonNegativeString =
                                        inputX.substring(1);
                                    coordinateXValue =
                                        -(double.parse(nonNegativeString));
                                  } else {
                                    coordinateXValue = double.parse(inputX);
                                  }
                                });
                              },
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                                labelText: 'offsetX',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              onChanged: (inputY) {
                                setState(() {
                                  if (inputY == "" || inputY == "-") {
                                    coordinateXValue = 0;
                                  } else if (inputY[0] == "-") {
                                    String nonNegativeString =
                                        inputY.substring(1);
                                    coordinateYValue =
                                        -(double.parse(nonNegativeString));
                                  } else {
                                    coordinateYValue = double.parse(inputY);
                                  }
                                });
                              },
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                                labelText: 'offsetY',
                              ),
                            ),
                          ),
                          FloatingActionButton.extended(
                            onPressed: () {
                              mapAnimationResetInitialize();
                            },
                            label: const Text("Reset"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: screenConverter.getHeightPixel(0.75),
              child: mainMap(
                  context,
                  mapTransformationController,
                  _onInteractionStart,
                  heading,
                  coordinateXValue,
                  coordinateYValue,
                  mapFloor,
                  mapFloorIndex,
                  screenConverter),
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
              heroTag: "2F",
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
                "2F",
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: FittedBox(
            child: FloatingActionButton(
              heroTag: "1F",
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
                "1F",
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
        width: screenConverter.getWidthPixel(0.3),
      ),
      Padding(
        padding: const EdgeInsets.all(9.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              "assets/compass/cadrant.png",
              scale: 6.0,
            ),
            Transform.rotate(
              angle: ((heading ?? 0) * (pi / 180) * -1),
              child: Image.asset("assets/compass/compass.png", scale: 6.0),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(9.0),
        child: Text(
          '${heading!.ceil()}',
          style: const TextStyle(
              color: Colors.white, fontSize: 13.0, fontWeight: FontWeight.bold),
        ),
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
    screenConverter) {
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
          //angle: ((heading ?? 0) * (pi / 180) * -1),
          angle: 0,
          child: Stack(
            children: [
              Center(
                child: Transform.translate(
                  offset: Offset(
                    // coordinateXValue,
                    // coordinateYValue,
                    screenConverter.getHeightPixel(coordinateXValue),
                    screenConverter.getWidthPixel(coordinateYValue),
                  ),
                  child: mapFloor[mapFloorIndex],
                ),
              ),
              SizedBox(
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
            ],
          ),
        ),
      ],
    ),
  );
}
