import 'package:flutter/material.dart';

class MapDimensions {
  final double geoWidth;
  final double geoHeight;
  final double trueWidth;
  final double trueHeight;

  const MapDimensions(this.geoWidth, this.geoHeight, this.trueWidth, this.trueHeight); 
}

class GeoScaledUnifiedMapper {
  static const map_dimensions = [
    MapDimensions(39.6, 73.6, 2758.0, 5121.0),
    MapDimensions(37.4, 73.4, 2760.0, 5228.0), // 8th floor
  ];

  static double getWidthPixel(double geoX, int mapFloorIndex) {
    var widthScale = map_dimensions[mapFloorIndex].trueWidth / map_dimensions[mapFloorIndex].geoWidth;
    return geoX * widthScale;
  }
  
  static double getHeightPixel(double geoY, int mapFloorIndex) {
    var heightScale = map_dimensions[mapFloorIndex].trueHeight / map_dimensions[mapFloorIndex].geoHeight;
    return geoY * heightScale;
  }
}

class ImageRatioMapper {
  // TODO: Find a way to use requests or something
  static const mapFloorDimension = [
    (2758.0, 5121.0),
    (2760.0, 5228.0)
  ];

  static double getHeightPixel(double unscaledMapPixel, Image asset, int mapFloorIndex) {
    double renderedHeight = asset.height ?? 1;
    double heightScaleRatio = mapFloorDimension[mapFloorIndex].$2 / renderedHeight;
    
    return unscaledMapPixel / heightScaleRatio;
  }
  
  static double getWidthPixel(double unscaledMapPixel, Image asset, int mapFloorIndex) {
    double renderedWidth = asset.width ?? 1;   
    double widthScaleRatio = mapFloorDimension[mapFloorIndex].$1 / renderedWidth;

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
