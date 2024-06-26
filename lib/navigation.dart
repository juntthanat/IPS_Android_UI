import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_thesis_project/beacon_loc.dart';

class EnableNavigate {
  bool enable = false;

  void setState(bool state) {
    enable = state;
  }
  
  bool getState() {
    return enable;
  }
}

class NavigationArrow extends StatelessWidget {
  final double x, y;
  final int selectedFloorId;
  final Beacon selectedBeacon;
  final EnableNavigate enableNavigate;

  const NavigationArrow({
    super.key,
    required this.x,
    required this.y,
    required this.selectedBeacon,
    required this.selectedFloorId,
    required this.enableNavigate,
  });

  double getAngle() {
    if (
      selectedBeacon.isEmpty() ||
      !enableNavigate.getState() ||
      selectedFloorId != selectedBeacon.getFloorId()
    ) {
      return 0;
    }

    var xVec = selectedBeacon.x - x;
    var yVec = selectedBeacon.y - y;
    var angle = math.atan2(xVec, yVec);

    return angle;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 75.0,
        height: 75.0,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            )),
        child: Transform.rotate(
          angle: math.pi + getAngle(),
          child: const Icon(
            Icons.arrow_downward,
            color: Colors.white,
            size: 48.0,
          ),
        ),
    );
  }
}

class NavigationCancelButton extends StatelessWidget {
  final EnableNavigate enableNavigate;

  const NavigationCancelButton({
    super.key,
    required this.enableNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 30,
        width: 100,
        child: TextButton(
          onPressed: () {
            enableNavigate.setState(false);
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.blue),
          ),
        )
    );
  }
}

