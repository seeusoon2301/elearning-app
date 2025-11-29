// lib/home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm import này
import 'role_provider.dart';
import 'signin.dart';
import 'instructor_dashboard.dart';
import 'home_page.dart'; // Import HomePage

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Hàm này sẽ đọc dữ liệu role đã lưu từ SharedPreferences
  Future<String?> _loadSavedRole() async {
    // 1. Lấy SharedPreferences Instance
    final prefs = await SharedPreferences.getInstance();
    
    // 2. Lấy role đã lưu
    final savedRole = prefs.getString("role"); 

    // 3. Nếu có role đã lưu, cập nhật RoleProvider
    if (savedRole != null) {
      // Đảm bảo cập nhật provider mà không cần rebuild (listen: false)
      // Điều này rất quan trọng để Home có thể build đúng widget sau khi FutureBuilder hoàn tất
      Provider.of<RoleProvider>(context, listen: false).setRole(savedRole);
    }
    
    // Trả về role (có thể là null nếu chưa login bao giờ)
    return savedRole;
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ Bọc toàn bộ widget trong FutureBuilder
    // Điều này giúp chúng ta đợi _loadSavedRole() hoàn tất.
    return FutureBuilder<String?>(
      future: _loadSavedRole(), // Gọi hàm tải dữ liệu đã lưu
      builder: (context, snapshot) {
        
        // 1. Đang tải (Hiển thị màn hình chờ)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6E48AA),
              ),
            ),
          );
        }

        // 2. Tải xong (Kiểm tra và hiển thị trang đúng)
        // Dùng Provider.of LẦN NỮA để đảm bảo lấy giá trị role MỚI NHẤT
        final currentRole = Provider.of<RoleProvider>(context).role;

        // Nếu role là null (chưa đăng nhập), chuyển về SignIn
        if (currentRole == null) {
          return const SignIn();
        }
        
        // PHÂN LOẠI VÀ CHUYỂN HƯỚNG
        if (currentRole == "instructor") {
          return const InstructorDashboard();
        } 
        else if (currentRole == "student") {
          return const HomePage(); // 👈 CHUYỂN ĐẾN TRANG CỦA STUDENT
        } 
        else {
          // Xử lý trường hợp role không xác định (ví dụ: đăng xuất)
          return const SignIn();
        }
      },
    );
  }
}