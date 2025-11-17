// lib/home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'role_provider.dart';
import 'signin.dart';
import 'instructor_dashboard.dart';
import 'home_page.dart'; // ← Đây là file HomePage sinh viên của bạn hiện tại

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy role từ Provider
    final role = Provider.of<RoleProvider>(context).role;

    // DỰA VÀO ROLE ĐỂ TRẢ VỀ TRANG ĐÚNG – ĐÚNG 100% ĐỀ THẦY MAI VĂN MẠNH
    if (role == "instructor") {
      return const InstructorDashboard();
    } 
    else if (role == "student") {
      return const HomePage(); // ← Trang sinh viên bạn đã làm sẵn
    } 
    else {
      // role == null → chưa đăng nhập → về SignIn
      return const SignIn();
    }
  }
}