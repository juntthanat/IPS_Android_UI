import 'dart:collection';

import 'package:flutter_thesis_project/screensize_converter.dart';
import 'package:test/test.dart';

void main() {
  group('GeoScaledUnifiedMapper Tests', () {
    test("GeoX to Scaled Unified Pixel X, where X = 0 & Valid Floor ID", () {
      // Setup
      double x = 0.0;
      int floorId = 1;

      MapDimension mapDimension = const MapDimension(39.6, 73.6, 2758, 5121);
      HashMap<int, MapDimension> mapDimensions = HashMap.from({ floorId: mapDimension });
      GeoScaledUnifiedMapper mapper = GeoScaledUnifiedMapper(mapDimensions);


      // Execute
      double result = mapper.getWidthPixel(x, floorId);
      
      // Verify
      expect(result, -1 * (2758/2));      
    });

    test("GeoX to Scaled Unified Pixel X, where X = 1 & Valid Floor ID", () {
      // Setup
      double x = 1.0;
      int floorId = 1;

      MapDimension mapDimension = const MapDimension(39.6, 73.6, 2758, 5121);
      HashMap<int, MapDimension> mapDimensions = HashMap.from({ floorId: mapDimension });
      GeoScaledUnifiedMapper mapper = GeoScaledUnifiedMapper(mapDimensions);


      // Execute
      double result = mapper.getWidthPixel(x, floorId);
      
      // Verify
      expect(result, -1309.3535353535353);      
    });

    test("GeoX to Scaled Unified Pixel X, where X = -1 & Valid Floor ID", () {
      // Setup
      double x = -1.0;
      int floorId = 1;

      MapDimension mapDimension = const MapDimension(39.6, 73.6, 2758, 5121);
      HashMap<int, MapDimension> mapDimensions = HashMap.from({ floorId: mapDimension });
      GeoScaledUnifiedMapper mapper = GeoScaledUnifiedMapper(mapDimensions);


      // Execute      
      // Verify
      expect(() => mapper.getWidthPixel(x, floorId), throwsException);      
    });

    test("GeoX to Scaled Unified Pixel X, where X = 100 & Valid Floor ID", () {
      // Setup
      double x = 100.0;
      int floorId = 1;

      MapDimension mapDimension = const MapDimension(39.6, 73.6, 2758, 5121);
      HashMap<int, MapDimension> mapDimensions = HashMap.from({ floorId: mapDimension });
      GeoScaledUnifiedMapper mapper = GeoScaledUnifiedMapper(mapDimensions);


      // Execute
      double result = mapper.getWidthPixel(x, floorId);
      
      // Verify
      expect(result, 5585.646464646465);
    });
  
  test("GeoY to Scaled Unified Pixel Y, where Y = 0 & Valid Floor ID", () {
      // Setup
      double y = 0.0;
      int floorId = 1;

      MapDimension mapDimension = const MapDimension(39.6, 73.6, 2758, 5121);
      HashMap<int, MapDimension> mapDimensions = HashMap.from({ floorId: mapDimension });
      GeoScaledUnifiedMapper mapper = GeoScaledUnifiedMapper(mapDimensions);


      // Execute
      double result = mapper.getHeightPixel(y, floorId);
      
      // Verify
      expect(result, 5121/2);      
    });

    test("GeoY to Scaled Unified Pixel Y, where Y = 1 & Valid Floor ID", () {
      // Setup
      double y = 1.0;
      int floorId = 1;

      MapDimension mapDimension = const MapDimension(39.6, 73.6, 2758, 5121);
      HashMap<int, MapDimension> mapDimensions = HashMap.from({ floorId: mapDimension });
      GeoScaledUnifiedMapper mapper = GeoScaledUnifiedMapper(mapDimensions);


      // Execute
      double result = mapper.getHeightPixel(y, floorId);
      
      // Verify
      expect(result, 2490.921195652174);      
    });

    test("GeoY to Scaled Unified Pixel Y, where Y = -1 & Valid Floor ID", () {
      // Setup
      double y = -1.0;
      int floorId = 1;

      MapDimension mapDimension = const MapDimension(39.6, 73.6, 2758, 5121);
      HashMap<int, MapDimension> mapDimensions = HashMap.from({ floorId: mapDimension });
      GeoScaledUnifiedMapper mapper = GeoScaledUnifiedMapper(mapDimensions);


      // Execute
      // Verify
      expect(() => mapper.getHeightPixel(y, floorId), throwsException);      
    });

    test("GeoY to Scaled Unified Pixel Y, where Y = 100 & Valid Floor ID", () {
      // Setup
      double y = 100.0;
      int floorId = 1;

      MapDimension mapDimension = const MapDimension(39.6, 73.6, 2758, 5121);
      HashMap<int, MapDimension> mapDimensions = HashMap.from({ floorId: mapDimension });
      GeoScaledUnifiedMapper mapper = GeoScaledUnifiedMapper(mapDimensions);


      // Execute
      double result = mapper.getHeightPixel(y, floorId);
      
      // Verify
      expect(result, -4397.380434782609);
    });
    
    test("GeoX to Scaled Unified Pixel X, where X = 0 & Invalid Floor ID", () {
      // Setup
      double x = 0.0;
      int floorId = 1;

      MapDimension mapDimension = const MapDimension(39.6, 73.6, 2758, 5121);
      HashMap<int, MapDimension> mapDimensions = HashMap.from({ floorId: mapDimension });
      GeoScaledUnifiedMapper mapper = GeoScaledUnifiedMapper(mapDimensions);


      // Execute
      int invalidFloorId = 2;
      
      // Verify
      expect(() => mapper.getWidthPixel(x, invalidFloorId), throwsA(const TypeMatcher<InvalidFloorId>()));      
    });
  });
}