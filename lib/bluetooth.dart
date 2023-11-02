import 'dart:async';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

const NO_OF_RSSI_VALUES_TO_RETAIN = 5;

class BLEDevice {

  late String _id;
  late String _name;
  late int _rssi;
  final _rssiList = <int>[];
  
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
  
  /// Takes a DiscoveredDevice and update this device's rssi value
  void updateRssi(DiscoveredDevice discoveredDevice) {
    while (_rssiList.length >= NO_OF_RSSI_VALUES_TO_RETAIN) {
      _rssiList.removeAt(0);
    }
    _rssiList.add(discoveredDevice.rssi);
    _rssi = _rssiList.average.round();
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

      // Takes the discovered device and checks if it's already in our list.
      // If not, add device to list.
      var idList = _devices.map((e) => e.id).toList();
      var idIdx = idList.indexOf(device.id);
      if (idIdx != -1) {
        _devices[idIdx].updateRssi(device);
      } else {
        _devices.add(BLEDevice(device));
      }
      
      // Gets the device with the strongest signal
      _devices.sort((a, b) => a._rssi.compareTo(b._rssi));
      nearestDevice = _devices.last;
      
      // Notifies all subscribers
      notifyListeners();

    });
    bleDeviceStreamSubscription.pause();

  }
  
  /// Starts the Bluetooth Scanner
  void scan() {
    bleDeviceStreamSubscription.resume();
    scanning = true;
  }
  
  /// Pauses the Bluetooth Scanner
  void pause() {
    bleDeviceStreamSubscription.pause();
    scanning = false;
  }
  
  /// Toggles the Bluetooth Scanner. Internally calls pause() and resume()
  void toggle() {
    if (scanning) {
      pause();
    } else {
      scan();
    }
  }

  /// Clears all devices from the _devices list
  void clear() {
    _devices.clear();
  }
}