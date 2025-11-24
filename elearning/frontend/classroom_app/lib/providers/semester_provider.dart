// lib/providers/semester_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Semester {
  final String id;
  final String name;
  Semester({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Semester.fromJson(Map<String, dynamic> json) => Semester(id: json['id'], name: json['name']);
}

class SemesterProvider with ChangeNotifier {
  Semester? _current;
  List<Semester> _list = [];

  Semester? get current => _current;
  List<Semester> get list => _list;

  SemesterProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('semesters');
    final currentId = prefs.getString('currentSemesterId');

    if (saved != null) {
      final List<dynamic> jsonList = List.from(jsonDecode(saved));
      _list = jsonList.map((e) => Semester.fromJson(e)).toList();
    }

    if (_list.isEmpty) {
      final defaultSemester = Semester(id: "1", name: "Học kỳ 1 - 2025-2026");
      _list.add(defaultSemester);
      _current = defaultSemester;
      await _saveToPrefs();
    } else {
      _current = _list.firstWhere((s) => s.id == currentId, orElse: () => _list.first);
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _list.map((s) => s.toJson()).toList();
    await prefs.setString('semesters', jsonEncode(jsonList));
    if (_current != null) {
      await prefs.setString('currentSemesterId', _current!.id);
    }
  }

  void select(Semester semester) {
    _current = semester;
    _saveToPrefs();
    notifyListeners();
  }

  void add(String name) async {
    final newSemester = Semester(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name);
    _list.add(newSemester);
    _current = newSemester;
    await _saveToPrefs();
    notifyListeners();
  }
}