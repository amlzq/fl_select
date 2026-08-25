import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

Future<String> loadJsonData(String fileName) async {
  return await rootBundle.loadString('assets/realestate/shenzhen/$fileName');
}

/// 模拟用户的经纬度
const userLatLon = ('22.543553', '114.057935');

/// 模拟用户的城市ID
const userCityId = '66';
const userCityName = '深圳';

/// 计算两点之间的距离（单位：米）
/// 输入参数都是以「度」为单位的经纬度
double haversineDistance({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadius = 6371000; // 地球半径（米）

  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadius * c;
}

double _degToRad(double deg) => deg * math.pi / 180.0;

/// 判断是否在指定范围内
bool isWithinRadius({
  required double userLat,
  required double userLon,
  required double houseLat,
  required double houseLon,
  required double radiusMeters, // 指定半径/直径用哪个你决定
}) {
  final distance = haversineDistance(
    lat1: userLat,
    lon1: userLon,
    lat2: houseLat,
    lon2: houseLon,
  );

  return distance <= radiusMeters;
}
