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
              child: Text("Please Enable Location Permission"),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!await permissionIsGranted()) {
                await openAppSettings();
              } else {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text("Ok!"),
          ),
        ],
      ),
    );
  }

}
