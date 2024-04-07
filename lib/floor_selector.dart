import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thesis_project/beacon_loc.dart';
import 'package:flutter_thesis_project/beacon_loc_request.dart';
import 'package:flutter_thesis_project/screensize_converter.dart';

class SelectedFloor {
  int id;

  SelectedFloor({
    required this.id,
  });
  
  void setId(int id) {
    this.id = id;
  }

  int getId() {
    return id;
  }
}

enum FloorState {
  normal,
  top,
  bottom,
  none
}

class FloorSelectorButton extends StatefulWidget {
  final String floorName;
  final int floorId;
  final SelectedFloor currentlySelectedFloor;
  final List<Beacon> beaconsToRender;
  final FloorState floorState;
  final GeoScaledUnifiedMapper geoScaledUnifiedMapper;
  final Dio dio;

  const FloorSelectorButton({
    super.key,
    required this.floorName,
    required this.floorId,
    required this.currentlySelectedFloor,
    required this.beaconsToRender,
    required this.geoScaledUnifiedMapper,
    required this.dio,
    this.floorState = FloorState.normal,
  });

  @override
  State<FloorSelectorButton> createState() => _FloorSelectorButtonState();
}

class _FloorSelectorButtonState extends State<FloorSelectorButton> {
  
  RoundedRectangleBorder getBorderShape() {
    double topLeft = 0;
    double topRight = 0;
    double bottomLeft = 0;
    double bottomRight = 0;

    if (widget.floorState == FloorState.top) {
      topLeft = 100;
      topRight = 100;
    } else if (widget.floorState == FloorState.bottom) {
      bottomLeft = 100;
      bottomRight = 100;
    }
    
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(topLeft),
        topRight: Radius.circular(topRight),
        bottomLeft: Radius.circular(bottomLeft),
        bottomRight: Radius.circular(bottomRight)
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: FittedBox(
        child: FloatingActionButton(
          heroTag: widget.floorName,
          backgroundColor: widget.currentlySelectedFloor.getId() == widget.floorId ? Colors.blue : Theme.of(context).colorScheme.inversePrimary,
          foregroundColor: widget.currentlySelectedFloor.getId() == widget.floorId ? Colors.white : Colors.black,
          onPressed: () async {
            widget.currentlySelectedFloor.setId(widget.floorId);
            FloorBeaconList floorBeaconList = await fetchAllFloorBeaconsByFloor(widget.dio, widget.floorId);
            List<int> floorBeaconIdList = floorBeaconList.beaconList
              .map((e) => e.beaconId)
              .toList();
            List<Beacon> allBeaconsOfFloor = await fetchBeaconListFromIdList(
              widget.dio,
              floorBeaconIdList,
              widget.geoScaledUnifiedMapper,
              widget.floorId
            );

            widget.beaconsToRender.clear();
            widget.beaconsToRender.addAll(allBeaconsOfFloor);
          },
          shape: getBorderShape(),
          child: Text(
            widget.floorName,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
