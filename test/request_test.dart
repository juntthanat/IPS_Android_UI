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
}