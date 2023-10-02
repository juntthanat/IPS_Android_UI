// import 'dart:html';

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';

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

class MainBody extends State<MainPage> {
  double? heading = 0;
  double coordinateXValue = 0;
  double coordinateYValue = 0;

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

  @override
  void initState() {
    super.initState();
    FlutterCompass.events!.listen((event) {
      setState(() {
        heading = event.heading;
      });
    });
    // Implement Event Location Here
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              onChanged: (inputX) {
                                setState(() {
                                  if (inputX == "") {
                                    coordinateXValue = 0;
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
                                  if (inputY == "") {
                                    coordinateXValue = 0;
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
                        ],
                      ),

                      // FloatingActionButton.extended(
                      //   onPressed: () {
                      //     setState(() {
                      //       mapFloorIndex =
                      //           (mapFloorIndex + 1) % mapFloor.length;
                      //     });
                      //   },
                      //   label: const Text("Change Map"),
                      // ),
                    ),
                  ),
                  //----------------------Testing for transition Input-----------------//
                ],
              ),
            ),
            InteractiveViewer(
              minScale: 0.1,
              maxScale: 1.1,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 220,
                  ),
                  Transform.translate(
                    offset: Offset(
                      coordinateXValue,
                      coordinateYValue,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: Transform.rotate(
                        angle: ((heading ?? 0) * (pi / 180) * -1),
                        child: mapFloor[mapFloorIndex],
                      ),
                    ),
                  ),

                  // Testing Transition
                  Transform.translate(
                      offset: Offset(
                    coordinateXValue,
                    coordinateYValue,
                  ))
                  // End of Testing Transition
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
