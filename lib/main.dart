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
  MainCompass createState() => MainCompass();
}

class MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Mapping"),
      ),
      drawer: Drawer(
          child: ListView(
        children: const [
          DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue), child: Column()),
        ],
      )),
      body:
          // const Center(child: Image(image: AssetImage('assets/map/map_1.png'))),
          Center(
              child: Transform.rotate(
        angle: pi / 2,
        child: const Image(image: AssetImage('assets/map/map_1.png')),
      )),
    );
  }
}

class MainCompass extends State<MainPage> {
  double? heading = 0;

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        centerTitle: true,
        title: const Text("Location Map"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 5.0),
              Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        "assets/compass/cadrant.png",
                        scale: 5.0,
                      ),
                      Transform.rotate(
                        angle: ((heading ?? 0) * (pi / 180) * -1),
                        child: Image.asset("assets/compass/compass.png",
                            scale: 5.0),
                      ),
                    ],
                  )),
              Text(
                '${heading!.ceil()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 30.0,
              ),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Transform.rotate(
                  angle: ((heading ?? 0) * (pi / 180) * -1),
                  child: Image.asset("assets/map/map_1.png", scale: 1.1),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
