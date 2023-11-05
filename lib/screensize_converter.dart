import 'dart:ui';
import 'package:flutter/material.dart';

class ScreenSizeConverter {
  // double currentDeviceWidth = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width;
  // double currentDeviceHeight = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.height;

  // These will get the current device screen size.
  // FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
  //Dimension in physical pixel
  // Size physicalSize = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
  double physicalHeight = WidgetsBinding
      .instance.platformDispatcher.views.first.physicalSize.height;
  double physicalWidth =
      WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width;

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
    // double result = currentDeviceWidth * inputWidth;
    // double result = physicalWidth * inputWidth;
    double result = logicalWidth * inputWidth;
    return result;
  }

  double getHeightPixel(double inputHeight) {
    // double result = currentDeviceHeight * inputHeight;
    // double result = physicalHeight * inputHeight;
    double result = logicalHeight * inputHeight;
    return result;
  }
}
