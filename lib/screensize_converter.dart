import 'dart:ui';
import 'package:flutter/material.dart';

class ScreenSizeConverter {
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
