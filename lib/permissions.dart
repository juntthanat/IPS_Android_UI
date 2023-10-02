import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class RequestLocationPermissionPage extends StatelessWidget {
  const RequestLocationPermissionPage({super.key});

  Future<bool> permissionIsGranted() async {
    Map<Permission, PermissionStatus> permissionStatus = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    if (permissionStatus[Permission.locationWhenInUse] == PermissionStatus.permanentlyDenied) {
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_location_alt, size: 96.0),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Please Enable Location Permission",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 75.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!await permissionIsGranted()) {
                          await openAppSettings();
                        } else {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: const Text("Ok!"),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
