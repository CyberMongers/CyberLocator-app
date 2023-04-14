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
