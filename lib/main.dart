import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'My app',
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  // MainPageState createState() => MainPageState();
  MainBody createState() => MainBody();
}

class MainBody extends State<MainPage> {
  double? heading = 0;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
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
                  Positioned.fill(
                    child: Container(
                      alignment: Alignment.center,
                      height: 100,
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          setState(() {
                            mapFloorIndex =
                                (mapFloorIndex + 1) % mapFloor.length;
                          });
                        },
                        label: const Text("Change Map"),
                      ),
                    ),
                  ),
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
                  Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Transform.rotate(
                      angle: ((heading ?? 0) * (pi / 180) * -1),
                      // child: Image.asset("assets/map/map_1.png", scale: 1.1),
                      child: mapFloor[mapFloorIndex],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
