import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thesis_project/bluetooth.dart';
import 'package:flutter_thesis_project/permissions.dart';
import 'package:permission_handler/permission_handler.dart';

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

  final TransformationController mapTransformationController =
      TransformationController();
  Animation<Matrix4>? mapAnimationReset;
  late final AnimationController mapControllerReset;

  static List<Image> mapFloor = <Image>[
    Image.asset(
      "assets/map/map_1.png",
      scale: 1.1,
    ),
    Image.asset(
      "assets/map/map_2.png",
      scale: 1.1,
    ),
  ];

  int mapFloorIndex = 0;

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
    mapControllerReset.dispose();
    super.dispose();
  }

    // To Scan Bluetooth: Uncomment this
  //var bluetoothNotifer = BluetoothNotifier();

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
    //bluetoothNotifer.scan();
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
              color: Colors.grey[900],
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 5.0,
                        width: double.infinity,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 5.0,
                            width: 30,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(9.0),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  "assets/compass/cadrant.png",
                                  scale: 5.0,
                                ),
                                Transform.rotate(
                                  angle: ((heading ?? 0) * (pi / 180) * -1),
                                  child: Image.asset(
                                      "assets/compass/compass.png",
                                      scale: 5.0),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(9.0),
                            child: Text(
                              '${heading!.ceil()}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  //----------------------Testing for transition Input-----------------//
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
                  //----------------------Testing for transition Input-----------------//
                ],
              ),
            ),
            InteractiveViewer(
              transformationController: mapTransformationController,
              minScale: 0.1,
              maxScale: 1.0,
              onInteractionStart: _onInteractionStart,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Stack(
                    children: [
                      Transform.translate(
                        offset: Offset(
                          coordinateXValue,
                          coordinateYValue,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(80.0),
                          child: Transform.rotate(
                            angle: ((heading ?? 0) * (pi / 180) * -1),
                            child: mapFloor[mapFloorIndex],
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.all(100.0),
                        decoration: const BoxDecoration(
                            color: Colors.orange, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ],
              ),
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
