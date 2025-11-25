// lib/providers/semester_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class Semester {
  final String id;
  final String name;
  final String? code;
  Semester({required this.id, required this.name, this.code});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code};
  factory Semester.fromJson(Map<String, dynamic> json) {
    // backend may return _id or id
    final id = json['_id'] ?? json['id'] ?? '';
    final name = json['name'] ?? '';
    final code = json['code'];
    return Semester(id: id.toString(), name: name.toString(), code: code?.toString());
  }
}

class SemesterProvider with ChangeNotifier {
  Semester? _current;
  List<Semester> _list = [];

  Semester? get current => _current;
  List<Semester> get list => _list;

  SemesterProvider() {
    _init();
  }

  Future<void> _init() async {
    final loaded = await _loadFromServer();
    if (!loaded) {
      await _loadFromPrefs();
    }
    notifyListeners();
  }

  Future<bool> _loadFromServer() async {
    try {
      final data = await ApiService.fetchSemesters();
      _list = data.map((e) => Semester.fromJson(e)).toList();

      // If server returns empty list, keep _list empty and _current null
      if (_list.isEmpty) {
        _current = null;
        return true; // treated as successful load (empty state)
      }

      final prefs = await SharedPreferences.getInstance();
      final currentId = prefs.getString('currentSemesterId');
      _current = _list.firstWhere((s) => s.id == currentId, orElse: () => _list.first);
      return true;
    } catch (_) {
      return false;
    }
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
    // Only persist the currently selected semester id locally.
    final prefs = await SharedPreferences.getInstance();
    if (_current != null) {
      await prefs.setString('currentSemesterId', _current!.id);
    } else {
      await prefs.remove('currentSemesterId');
    }
  }

  void select(Semester semester) {
    _current = semester;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> add(String name) async {
    // Try create on backend first. Generate a code from name.
    final generatedCode = _generateCodeFromName(name);
    // Create via backend; do not fallback to local-only creation.
    final created = await ApiService.createSemester(name, generatedCode);
    final sem = Semester.fromJson(created);
    // Insert or replace if exists
    _list.removeWhere((s) => s.id == sem.id || s.code == sem.code);
    _list.insert(0, sem);
    _current = sem;
    await _saveToPrefs();
    notifyListeners();
    return;
  }

  String _generateCodeFromName(String name) {
    // Chuyển về chữ hoa để dễ xử lý
    final upperName = name.toUpperCase();

    // 1. Thay thế "HỌC KỲ" bằng "HK"
    String result = upperName.replaceAll('HỌC KỲ', 'HK');

    // 2. Loại bỏ các khoảng trắng và dấu gạch ngang (trừ dấu gạch ngang phân cách chính)
    // và các ký tự không cần thiết khác.
    // Ví dụ: "HK 1 - 2024-2025"
    
    // Loại bỏ các ký tự không phải chữ cái, số, hoặc dấu gạch ngang
    result = result.replaceAll(RegExp(r'[^A-Z0-9\-]'), ''); 

    // Xử lý chuỗi "HK1-2024-2025" thành "HK1-20242025"
    // Giữ lại dấu gạch ngang đầu tiên, loại bỏ các dấu gạch ngang sau đó
    final parts = result.split('-');
    
    if (parts.length >= 2) {
      // Lấy phần đầu tiên (ví dụ: "HK1")
      final prefix = parts.first; 
      
      // Nối các phần còn lại, loại bỏ các dấu gạch ngang giữa năm (ví dụ: "2024" + "2025" = "20242025")
      final suffix = parts.sublist(1).join(''); 
      
      return '$prefix-$suffix'; // Nối lại với dấu gạch ngang phân cách
    }

    // Trường hợp dự phòng nếu không theo định dạng "X - Y"
    return result;
  }
}