import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const baseUrl = "http://localhost:3000/api";

  static Future<Map<String, dynamic>> login(String email, String pass) async {
    final url = Uri.parse("$baseUrl/auth/login");
    final res = await http.post(url, body: {
      "email": email,
      "password": pass,
    });

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      return data;
    } else {
      throw data["error"];
    }
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String pass) async {
    final url = Uri.parse("$baseUrl/auth/register");
    final res = await http.post(url, body: {
      "name": name,
      "email": email,
      "password": pass,
    });

    return jsonDecode(res.body);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token") != null;
  }

  static Future<List> getStudentCourses(String email) async {
    final url = Uri.parse("$baseUrl/courses/student/$email");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to fetch courses");
    }
  }
}
