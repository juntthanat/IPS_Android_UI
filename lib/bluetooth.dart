import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BLEDevice {

  late String _id;
  late String _name;
  late int _rssi;
  
  String get id => _id;
  String get name => _name;
  int get rssi => _rssi;
  
  set id(String id) {
    _id = id;
  }
  
  set name(String name) {
    _name = name;
  }
  
  set rssi(int rssi) {
    _rssi = rssi;
  }
  
  BLEDevice(DiscoveredDevice discoveredDevice) {
    _id = discoveredDevice.id;
    _name = discoveredDevice.name;
    _rssi = discoveredDevice.rssi;
  }

}

class BluetoothNotifier extends ChangeNotifier {
  final flutterReactiveBle = FlutterReactiveBle();
  late Stream<DiscoveredDevice> bleDeviceStream;
  late StreamSubscription<DiscoveredDevice> bleDeviceStreamSubscription;
  var _devices = <BLEDevice>[];
  
  BluetoothNotifier() {
    bleDeviceStream = flutterReactiveBle.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency);
    bleDeviceStreamSubscription = bleDeviceStream.listen((device) async {

      print("Discovered: $device.id");
      var idList = _devices.map((e) => e.id).toList();
      var idIdx = idList.indexOf(device.id);
      if (idIdx != -1) {
        _devices[idIdx].rssi = device.rssi;
      } else {
        _devices.add(BLEDevice(device));
      }
      
      notifyListeners();

    });
    bleDeviceStreamSubscription.pause();

  }
  
  void scan() {
    bleDeviceStreamSubscription.resume();
  }
  
  void pause() {
    bleDeviceStreamSubscription.pause();
  }
}