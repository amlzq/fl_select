import 'dart:math' as math;

import 'package:flutter/foundation.dart';

void largePrint(String message) {
  const chunkSize = 800;
  for (var i = 0; i < message.length; i += chunkSize) {
    final end = math.min(i + chunkSize, message.length);
    debugPrint(message.substring(i, end));
  }
}
