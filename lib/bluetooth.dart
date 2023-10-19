import 'dart:async';

import 'package:flutter/material.dart';
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

  BLEDevice.empty() {
    _id = "";
    _name = "";
    _rssi = -100;
  }
  
  bool isEmpty() {
    if (_id.isEmpty && _name.isEmpty && _rssi == -100) {
      return true;
    }
    
    return false;
  }
  
  @override
  String toString() {
    return "id: $_id  name: $_name  rssi: $_rssi";
  }

}

class BluetoothNotifier extends ChangeNotifier {
  final flutterReactiveBle = FlutterReactiveBle();
  final serviceUuid = Uuid.parse("422da7fb-7d15-425e-a65f-e0dbcc6f4c6a");

  late Stream<DiscoveredDevice> bleDeviceStream;
  late StreamSubscription<DiscoveredDevice> bleDeviceStreamSubscription;
  var _devices = <BLEDevice>[];
  BLEDevice nearestDevice = BLEDevice.empty();
  bool scanning = false;
  
  BluetoothNotifier() {
    bleDeviceStream = flutterReactiveBle.scanForDevices(withServices: [serviceUuid], scanMode: ScanMode.lowPower);
    bleDeviceStreamSubscription = bleDeviceStream.listen((device) async {

      print("Discovered: ${device.id}");
      var idList = _devices.map((e) => e.id).toList();
      var idIdx = idList.indexOf(device.id);
      if (idIdx != -1) {
        _devices[idIdx].rssi = device.rssi;
      } else {
        _devices.add(BLEDevice(device));
      }
      
      _devices.sort((a, b) => a._rssi.compareTo(b._rssi));
      nearestDevice = _devices.last;
      print("Nearest Device: ${nearestDevice.id}    ${nearestDevice.rssi}");
      
      notifyListeners();

    });
    bleDeviceStreamSubscription.pause();

  }
  
  void scan() {
    bleDeviceStreamSubscription.resume();
    scanning = true;
  }
  
  void pause() {
    bleDeviceStreamSubscription.pause();
    scanning = false;
  }
  
  void toggle() {
    if (scanning) {
      pause();
    } else {
      scan();
    }
  }
}