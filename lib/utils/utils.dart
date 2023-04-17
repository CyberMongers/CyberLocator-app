import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

createUserId() async {
  var uuid = const Uuid();
  String userId = uuid.v4();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("userId", userId);
  debugPrint("userId: $userId");
}

getUserId() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString("userId"); //returns null if doesn't exist
  return userId;
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  // result in meters
  return 12742 * asin(sqrt(a)) * 1000;
}

bool isManOutOfBound(lat1, lon1, lat2, lon2) {
  var distance = calculateDistance(lat1, lon1, lat2, lon2);
  if (distance >= 8000) {
    return true;
  }
  return false;
}
