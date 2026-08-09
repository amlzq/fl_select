import 'package:flutter/services.dart' show rootBundle;

Future<String> loadJsonData(String fileName) async {
  return await rootBundle.loadString('assets/realestate/austin/$fileName');
}

/// Mock user latitude/longitude
const userLatLon = ('30.2650578', '-97.7474633');

/// Mock user city ID
const userCityId = 'Austin_TX';
