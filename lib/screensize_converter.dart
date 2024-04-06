import 'dart:collection';

import 'package:flutter/material.dart';

class MapDimension {
  final double geoWidth;
  final double geoHeight;
  final double trueWidth;
  final double trueHeight;

  const MapDimension(this.geoWidth, this.geoHeight, this.trueWidth, this.trueHeight); 
}

class InvalidFloorId implements Exception {
  const InvalidFloorId();
}

class CoordinateMapper {
  HashMap<int, MapDimension> mapDimensions;
  
  CoordinateMapper(this.mapDimensions);

  void addMapDimensionInfo(int floorId, MapDimension mapDimension) {
    mapDimensions[floorId] = mapDimension;
  }
}

class GeoScaledUnifiedMapper extends CoordinateMapper {

  GeoScaledUnifiedMapper(HashMap<int, MapDimension> mapDimensions) : super(mapDimensions);

  double getWidthPixel(double geoX, int floorId) {
    MapDimension? mapDimension = mapDimensions[floorId];

    if (mapDimension == null) {
      throw const InvalidFloorId();
    }

    var widthScale = mapDimension.trueWidth / mapDimension.geoWidth;
    return (geoX * widthScale) - (mapDimension.trueWidth / 2);
  }
  
  double getHeightPixel(double geoY, int floorId) {
    MapDimension? mapDimension = mapDimensions[floorId];

    if (mapDimension == null) {
      throw const InvalidFloorId();
    }

    var heightScale = mapDimension.trueHeight / mapDimension.geoHeight;
    return (-1 * (geoY * heightScale)) + (mapDimension.trueHeight / 2);
  }
}

class ImageRatioMapper extends CoordinateMapper {

  HashMap<int, Image> floorImages;

  ImageRatioMapper(
    HashMap<int, MapDimension> mapDimensions,
    this.floorImages,
  ) : super(mapDimensions);

  double getHeightPixel(double unscaledMapPixel, int floorId) {
    Image? renderedImage = floorImages[floorId];
    MapDimension? mapDimension = mapDimensions[floorId];

    if (renderedImage == null || mapDimension == null) {
      return unscaledMapPixel;
    }
    
    double renderedHeight = renderedImage.height ?? 1;
    double heightScaleRatio = mapDimension.trueHeight / renderedHeight;
    return unscaledMapPixel / heightScaleRatio;
  }
  
  double getWidthPixel(double unscaledMapPixel, int floorId) {
    Image? renderedImage = floorImages[floorId];
    MapDimension? mapDimension = mapDimensions[floorId];

    if (renderedImage == null || mapDimension == null) {
      return unscaledMapPixel;
    }

    double renderedWidth = renderedImage.width ?? 1;   
    double widthScaleRatio = mapDimension.trueWidth / renderedWidth;
    return unscaledMapPixel / widthScaleRatio;
  }

}

class DevicePixelMapper {
  double devicePixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
 
  // Converts Logical Pixel to Physical Pixel
  double getConvertedPixel(double logicalPixel) {
    // return logicalPixel * devicePixelRatio;
    return logicalPixel;
  }
}

class ScreenSizeConverter {

  // physical_size = WidgetsBinding.instance.platformDispatcher.view.first.physicalSize
  // physical_height or physical_width = physical_size.(height or width)
  // device_pixel_ratio = WidgetsBinding.instance.platformDispatcher.view.first.devicePixelRatio
  // logical_size =  (Physical Size / Device Pixel Ratio)
  // logical_height or logical_width = logical_size.(height or width)

  double logicalHeight =
      (WidgetsBinding.instance.platformDispatcher.views.first.physicalSize /
              WidgetsBinding
                  .instance.platformDispatcher.views.first.devicePixelRatio)
          .height;
  double logicalWidth =
      (WidgetsBinding.instance.platformDispatcher.views.first.physicalSize /
              WidgetsBinding
                  .instance.platformDispatcher.views.first.devicePixelRatio)
          .width;

  // These function will convert input from 0 - 1 (for example, 0, 0.1, 0.5, 1.0, 1.5)
  // to be the number of pixel. For example if the screen width is 100 pixel, and the
  // input is 0.1 the result will be 10 pixel.
  double getWidthPixel(double inputWidth) {
    double result = logicalWidth * inputWidth;
    return result;
  }

  double getHeightPixel(double inputHeight) {
    double result = logicalHeight * inputHeight;
    return result;
  }
}
