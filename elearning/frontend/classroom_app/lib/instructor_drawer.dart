import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'role_provider.dart';
import 'signin.dart';

class InstructorDrawer extends StatelessWidget {
  const InstructorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFF8E24AA),
              Color(0xFFBA68C8),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header Drawer – Avatar + Tên + Email
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              accountName: const Text(
                "Giảng viên TDTU",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text(
                "admin@tdtu.edu.vn",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              currentAccountPicture: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: const Text(
                  "GV",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A)),
                ),
              ),
              otherAccountsPictures: const [
                // Có thể thêm avatar nhỏ khác nếu muốn, hoặc để trống
              ],
            ),

            // Menu Items – An toàn 100% với đề thầy Mai Văn Mạnh
            _buildMenuItem(context, Icons.dashboard_rounded, "Dashboard", isActive: true),
            _buildMenuItem(context, Icons.class_rounded, "Danh sách lớp"),
            _buildMenuItem(context, Icons.assignment_turned_in_rounded, "Bài tập"),
            _buildMenuItem(context, Icons.quiz_rounded, "Quiz"),
            _buildMenuItem(context, Icons.bar_chart_rounded, "Thống kê"),
            const Divider(height: 40, thickness: 1, color: Colors.white24, indent: 20, endIndent: 20),

            // ĐĂNG XUẤT – BẮT BUỘC CÓ
            _buildMenuItem(
              context,
              Icons.logout_rounded,
              "Đăng xuất",
              onTap: () async {
                // 1. Đặt role về null TRƯỚC
                Provider.of<RoleProvider>(context, listen: false).setRole("");

                // 2. Dùng pushAndRemoveUntil để xóa hết stack và về SignIn
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignIn()),
                  (route) => false,
                );

                // 3. ĐẢM BẢO role = null ngay lập tức (tránh race condition)
                // Không cần thêm gì ở đây, vì pushAndRemoveUntil đã xóa hết
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    bool isActive = false,
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white, size: 26),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      selected: isActive,
      selectedTileColor: Colors.white.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: onTap ?? () => Scaffold.of(context).closeDrawer(),
    );
  }
}