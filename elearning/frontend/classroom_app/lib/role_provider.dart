import 'package:flutter/material.dart';

class RoleProvider extends ChangeNotifier {
  String? role; // "instructor" hoặc "student"

  void setRole(String? newRole) {
    role = newRole;
    notifyListeners();
  }

  void clearRole() {
    role = null;
    notifyListeners();
  }
}