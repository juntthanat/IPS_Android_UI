import 'package:flutter/material.dart';
import 'package:flutter_thesis_project/beacon_loc.dart';
import 'package:flutter_thesis_project/screensize_converter.dart';

class InteractiveMap extends StatefulWidget {
  final double coordinateXValue, coordinateYValue;
  final Beacon currentBeaconInfo;
  final List<Image> mapFloor;
  final int mapFloorIndex;

  const InteractiveMap({
    required Key key,
    required this.coordinateXValue,
    required this.coordinateYValue,
    required this.mapFloor,
    required this.mapFloorIndex,
    required this.currentBeaconInfo,
  }) : super(key: key);
  
  @override
  State<InteractiveMap> createState() => InteractiveMapState();
}

class InteractiveMapState extends State<InteractiveMap> with TickerProviderStateMixin {
  final TransformationController mapTransformationController = TransformationController();

  Animation<Matrix4>? mapAnimationReset;

  late final AnimationController mapControllerReset = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  void onMapAnimationReset() {
    mapTransformationController.value = mapAnimationReset!.value;
    if (!mapControllerReset.isAnimating) {
      mapAnimationReset!.removeListener(onMapAnimationReset);
      mapAnimationReset = null;
      mapControllerReset.reset();
    }
  }

  void mapAnimationResetInitialize() {
    mapControllerReset.reset();
    mapAnimationReset = Matrix4Tween(
      begin: mapTransformationController.value,
      end: Matrix4.identity(),
    ).animate(mapControllerReset);
    mapAnimationReset!.addListener(onMapAnimationReset);
    mapControllerReset.forward();
  }

  // Stop the reset to inital position transform animation.
  void mapAnimateResetStop() {
    mapControllerReset.stop();
    mapAnimationReset?.removeListener(onMapAnimationReset);
    mapAnimationReset = null;
    mapControllerReset.reset();
  }

  // If user translate during the initial position transform animation, the animation cancel and follow the user.
  void onInteractionStart(ScaleStartDetails details) {
    if (mapControllerReset.status == AnimationStatus.forward) {
      mapAnimateResetStop();
    }
  }

  @override
  void dispose() {
    mapControllerReset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: mapTransformationController,
      minScale: 0.1,
      maxScale: 2.0,
      onInteractionStart: onInteractionStart,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Transform.rotate(
            //angle: ((heading ?? 0) * (pi / 180) * -1),
            angle: 0,
            child: Stack(
              children: [
                MapImage(
                  coordinateXValue: widget.coordinateXValue,
                  coordinateYValue: widget.coordinateYValue,
                  mapFloor: widget.mapFloor, 
                  mapFloorIndex: widget.mapFloorIndex,
                ),
                UserPositionPin(mapFloorIndex: widget.mapFloorIndex, currentFloor: widget.currentBeaconInfo.getFloor(),),
                BeaconPin(
                  pinX: 100,
                  pinY: 100,
                  coordinateXValue: widget.coordinateXValue,
                  coordinateYValue: widget.coordinateYValue,
                  mapFloor: widget.mapFloor,
                  mapFloorIndex: widget.mapFloorIndex
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapImage extends StatelessWidget {
  final double coordinateXValue, coordinateYValue;
  final List<Image> mapFloor;
  final int mapFloorIndex;

  const MapImage({
    super.key,
    required this.coordinateXValue,
    required this.coordinateYValue,
    required this.mapFloor,
    required this.mapFloorIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: Offset(
          ImageRatioMapper.getWidthPixel(coordinateXValue * -1, mapFloor[mapFloorIndex], mapFloorIndex),
          ImageRatioMapper.getHeightPixel(coordinateYValue, mapFloor[mapFloorIndex], mapFloorIndex) - 20,
        ),
        child: mapFloor[mapFloorIndex],
      ),
    );
  }
}

class UserPositionPin extends StatelessWidget {
  final ScreenSizeConverter screenConverter = ScreenSizeConverter();
  final int mapFloorIndex;
  final int currentFloor;

  UserPositionPin({
    super.key,
    required this.mapFloorIndex,
    required this.currentFloor
  });

  @override
  Widget build(BuildContext context) {
    return Visibility(
      // TODO: REVERT
      // visible: mapFloorIndex == 0 && currentFloor == 7 || mapFloorIndex == 1 && currentFloor == 8,
      visible: true,
      child: SizedBox(
        height: screenConverter.getHeightPixel(0.75),
        width: screenConverter.getWidthPixel(1.0),
        child: Center(
          child: Container(
            // TODO: REVERT
            /* height: 24,
            width: 24, */
            height: 10,
            width: 10,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.rectangle,
              // TODO: REVERT
              // shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class BeaconPin extends StatelessWidget {
  final ScreenSizeConverter screenConverter = ScreenSizeConverter();
  final ImageRatioMapper imageRatioMapper = ImageRatioMapper();

  final double coordinateXValue, coordinateYValue;
  final double pinX, pinY;
  final List<Image> mapFloor;
  final int mapFloorIndex;

  BeaconPin({
    super.key,
    required this.pinX,
    required this.pinY,
    required this.coordinateXValue,
    required this.coordinateYValue,
    required this.mapFloor,
    required this.mapFloorIndex,
  });

  @override
  Widget build(BuildContext context) {
    var dx = ImageRatioMapper.getWidthPixel((coordinateXValue * -1) + pinX, mapFloor[mapFloorIndex], mapFloorIndex);
    var dy = ImageRatioMapper.getHeightPixel(coordinateYValue + (pinY * -1), mapFloor[mapFloorIndex], mapFloorIndex);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: SizedBox(
        height: screenConverter.getHeightPixel(0.75),
        width: screenConverter.getWidthPixel(1.0),
        child: Center(
          child: Container(
            height: 10,
            width: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.rectangle,
            ),
          ),
        ),
      ),
    );
  }
}
