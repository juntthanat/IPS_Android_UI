import 'dart:convert';

import 'package:flutter_thesis_project/beacon_loc_request.dart';
import 'package:test/test.dart';

void main() {
  group("Geo Beacon Test", () {
    test("Geo Beacon isEmpty test", () {
      // Setup
      GeoBeacon beacon = GeoBeacon.empty();

      // Execute
      bool isEmpty = beacon.isEmpty();

      // Verify
      expect(isEmpty, true);
    });

    test("JSON to GeoBeacon test", () {
      // Setup
      String jsonString = '[{"beaconId":1,"name":"ECC704-Door","geoX":28.4,"geoY":16.4,"macAddress":"E4:65:B8:0B:BB:06"},{"beaconId":2,"name":"ECC705-Door","geoX":28.0,"geoY":6.2,"macAddress":"D4:8A:FC:CE:99:B2"}]';

      // Execute
      GeoBeaconList result = GeoBeaconList.fromJson(jsonDecode(jsonString));

      // Verify
      GeoBeacon beacon_1 = GeoBeacon(id: 1, name: "ECC704-Door", geoX: 28.4, geoY: 16.4, macAddress: "E4:65:B8:0B:BB:06");
      GeoBeacon beacon_2 = GeoBeacon(id: 2, name: "ECC705-Door", geoX: 28.0, geoY: 6.2, macAddress: "D4:8A:FC:CE:99:B2");
      List<GeoBeacon> verifyList = [beacon_1, beacon_2];

      /// Compare the Beacon lists
      bool testResult = true;
      if (result.geoBeaconList.length != verifyList.length) {
        testResult = false;
      } else {
        for (int i = 0; i < verifyList.length; i++) {
          GeoBeacon b1 = result.geoBeaconList[i];
          GeoBeacon b2 = verifyList[i];

          if (
            b1.id == b2.id &&
            b1.name == b2.name &&
            b1.geoX == b2.geoX &&
            b1.geoY == b2.geoY &&
            b1.macAddress == b2.macAddress
          ) {
            continue;
          } else {
            testResult = false;
            break;
          }
        }
      }

      expect(testResult, true);
    });
  });
  
  group("FloorBeacon Test", () {
    test("Floor Beacon List from JSON Test", () {
      // Setup
      String jsonString = '[{"floorBeaconId":1,"floorId":1,"beaconId":1},{"floorBeaconId":2,"floorId":1,"beaconId":2}]';
      
      // Execute
      FloorBeaconList result = FloorBeaconList.fromJson(jsonDecode(jsonString));

      // Verify
      FloorBeacon fb1 = FloorBeacon(floorBeaconId: 1, floorId: 1, beaconId: 1);
      FloorBeacon fb2 = FloorBeacon(floorBeaconId: 2, floorId: 1, beaconId: 2);
      List<FloorBeacon> floorBeaconExpected = [fb1, fb2];

      List<FloorBeacon> internalList = result.beaconList;

      bool listEqual = true;
      if (internalList.length != floorBeaconExpected.length) {
        listEqual = false;
      }
      
      for (int i = 0; i < internalList.length; i++) {
        FloorBeacon lfb1 = internalList[i];
        FloorBeacon lfb2 = floorBeaconExpected[i];

        if (
          lfb1.beaconId == lfb2.beaconId &&
          lfb1.floorBeaconId == lfb2.floorBeaconId &&
          lfb1.floorId == lfb2.floorId
        ) {
          continue;
        } else {
          listEqual = false;
        }
      }

      expect(listEqual, true);
    });
  });
  
  group("Floor File Test", () {
    test("FloorFileInfo List from JSON Test", () {
      // Setup
      String jsonString = '[{"floorFileId":3,"floorId":1,"fileId":1},{"floorFileId":4,"floorId":2,"fileId":2}]';

      // Execute
      List<FloorFileInfo> result = FloorFileInfoList.fromJson(jsonDecode(jsonString))
        .floorFileInfoList;
        
      // Verify
      FloorFileInfo i1 = FloorFileInfo(floorFileId: 3, floorId: 1, fileId: 1);
      FloorFileInfo i2 = FloorFileInfo(floorFileId: 4, floorId: 2, fileId: 2);
      List<FloorFileInfo> expectedList = [i1, i2];

      bool listEqual = true;
      if (result.length != expectedList.length) {
        listEqual = false;
      }
      
      for (int i = 0; i < result.length; i++) {
        FloorFileInfo li1 = result[i];
        FloorFileInfo li2 = expectedList[i];

        if (
          li1.fileId == li2.fileId &&
          li1.floorFileId == li2.floorFileId &&
          li1.floorId == li2.floorId
        ) {
          continue;
        } else {
          listEqual = false;
        }
      }
      
      expect(listEqual, true);
    });
  });
  
  group("FloorFileDimensionAndLisk Test", () {
    test("Floor File Dimension and Link List from JSON Test", () {
      // Setup
      String jsonString = '[{"fileId":1,"name":"ecc7thfloor-cropped-to-floor.png","size":570523,"downloadUrl":"http://marco.cooldev.win:8080/api/v1/files/download/1","viewUrl":"http://marco.cooldev.win:8080/api/v1/files/view/1","contentType":"image/png","pixelWidth":2758,"pixelHeight":5121},{"fileId":2,"name":"ecc8thfloor-cropped-to-floor.png","size":581530,"downloadUrl":"http://marco.cooldev.win:8080/api/v1/files/download/2","viewUrl":"http://marco.cooldev.win:8080/api/v1/files/view/2","contentType":"image/png","pixelWidth":2760,"pixelHeight":5228}]';

      // Execute
      List<FloorFileDimensionAndLink> result = FloorFileDimensionAndLinkList.fromJson(jsonDecode(jsonString))
        .floorFileDimensionAndLinkList;
      
      // Verify
      FloorFileDimensionAndLink ffdal1 = FloorFileDimensionAndLink(fileId: 1, name: "ecc7thfloor-cropped-to-floor.png", downloadUrl: "http://marco.cooldev.win:8080/api/v1/files/download/1", pixelWidth: 2758, pixelHeight: 5121);
      FloorFileDimensionAndLink ffdal2 = FloorFileDimensionAndLink(fileId: 2, name: "ecc8thfloor-cropped-to-floor.png", downloadUrl: "http://marco.cooldev.win:8080/api/v1/files/download/2", pixelWidth: 2760, pixelHeight: 5228);
      List<FloorFileDimensionAndLink> expected = [ffdal1, ffdal2];

      bool listEqual = true;
      if (result.length != expected.length) {
        listEqual = false;
      }
      
      for (int i = 0; i < result.length; i++) {
        FloorFileDimensionAndLink lffdal1 = result[i];
        FloorFileDimensionAndLink lffdal2 = expected[i];

        if (
          lffdal1.fileId == lffdal2.fileId &&
          lffdal1.name == lffdal2.name &&
          lffdal1.downloadUrl == lffdal2.downloadUrl &&
          lffdal1.pixelWidth == lffdal2.pixelWidth &&
          lffdal1.pixelHeight == lffdal2.pixelHeight
        ) {
          continue;
        } else {
          listEqual = false;
        }
      }
      
      expect(listEqual, true);
    });
  });
}