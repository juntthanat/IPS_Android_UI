import 'dart:async';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

const NO_OF_RSSI_VALUES_TO_RETAIN = 5;

class BLEDevice {

  late String _id;
  late String _name;
  late int _rssi;
  late DateTime _lastDiscovered;
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
    _lastDiscovered = DateTime.now();
  }

  BLEDevice.empty() {
    _id = "";
    _name = "";
    _rssi = -100;
    _lastDiscovered = DateTime(1970);
  }
  
  bool isEmpty() {
    if (_id.isEmpty && _name.isEmpty && _rssi == -100 && _lastDiscovered == DateTime(1970)) {
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
  
  /// Updates the _lastDiscovered value by setting it to the current timestamp
  void updateLastDiscovered() {
    _lastDiscovered = DateTime.now();
  }
  
  @override
  String toString() {
    return "id: $_id  name: $_name  rssi: $_rssi lastDiscovered: ${DateTime.now().difference(_lastDiscovered).inSeconds} sec ago";
  }

}

class BluetoothNotifier extends ChangeNotifier {
  final flutterReactiveBle = FlutterReactiveBle();
  final serviceUuid = Uuid.parse("422da7fb-7d15-425e-a65f-e0dbcc6f4c6a");

  late StreamSubscription<DiscoveredDevice>? bleDeviceStreamSubscription;
  final _devices = <BLEDevice>[];
  BLEDevice nearestDevice = BLEDevice.empty();
  bool scanning = false;
  bool isInitialized = false;
  
  /// Initializes the BluetoothNotifier class
  void init() {
    bleDeviceStreamSubscription = flutterReactiveBle.scanForDevices(withServices: [serviceUuid], scanMode: ScanMode.lowPower)
      .listen(bleListenCallback, onError: bleListenErrorHandler, cancelOnError: false);
    bleDeviceStreamSubscription?.pause();
    isInitialized = true;
  }
  
  /// Gets called when a new BLE device is discovered
  void bleListenCallback(DiscoveredDevice device) async {
    if (!isInitialized) {
      return;
    }

    // Takes the discovered device and checks if it's already in our list.
    // If not, add device to list.
    var idList = _devices.map((e) => e.id).toList();
    var idIdx = idList.indexOf(device.id);
    if (idIdx != -1) {
      _devices[idIdx].updateRssi(device);
      _devices[idIdx].updateLastDiscovered();
    } else {
      _devices.add(BLEDevice(device));
    }
    
    // Gets the device with the strongest signal
    _devices.sort((a, b) => a._rssi.compareTo(b._rssi));
    nearestDevice = _devices.last;
    
    // Notifies all subscribers
    notifyListeners();
  }
  
  /// The error handler for the BLE Device Stream subscription
  void bleListenErrorHandler(Object exception) {
    bleDeviceStreamSubscription?.pause();
    print(exception.toString());
  }
  
  /// Sets the callback to the Bluetooth Scanner's status
  /// Argument must be of type Function(BleStatus status)
  void setScannerStatusStreamCallback(Function(BleStatus status) callback) {
    flutterReactiveBle.statusStream.listen(callback);
  }
  
  /// Starts the Bluetooth Scanner
  void scan() {
    if (!isInitialized) {
      return;
    }

    bleDeviceStreamSubscription?.resume();
    scanning = true;
  }
  
  /// Pauses the Bluetooth Scanner
  void pause() {
    if (!isInitialized) {
      return;
    }

    bleDeviceStreamSubscription?.pause();
    scanning = false;
  }
  
  /// Toggles the Bluetooth Scanner. Internally calls pause() and resume()
  void toggle() {
    if (!isInitialized) {
      return;
    }

    if (scanning) {
      pause();
    } else {
      scan();
    }
  }
  
  /// Checks if the scanner is scanning.
  /// The result will be based on the internal state
  bool isScanning() {
    return scanning;
  }

  /// Clears all devices from the _devices list
  void clear() {
    _devices.clear();
  }
  
  /// Clears all devices that have not been discovered in the last N seconds
  void clearOldDevices(int seconds) {
    var now = DateTime.now();
    _devices.removeWhere((element) => now.difference(element._lastDiscovered).inSeconds > seconds);
  }
}