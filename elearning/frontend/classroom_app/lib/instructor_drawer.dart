// lib/instructor_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../signin.dart';
import 'role_provider.dart'; // Đảm bảo đúng đường dẫn

class InstructorDrawer extends StatelessWidget {
  const InstructorDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Xóa hết dữ liệu

    // ĐẶT ROLE VỀ null → ĐÃ SỬA, KHÔNG CÒN LỖI
    Provider.of<RoleProvider>(context, listen: false).setRole(null);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignIn()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF2A1B3D), const Color(0xFF1A0F2E)]
                : [const Color(0xFFE6E6FA), const Color(0xFFD8BFD8)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF6E48AA), const Color(0xFF9D50BB)]
                      : [const Color(0xFF9D50BB), const Color(0xFF6E48AA)],
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Text(
                  "E-Learning",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
            ),

            _buildItem(context, Icons.home, "Lớp học", selected: true),
            _buildItem(context, Icons.calendar_today, "Lịch"),
            _buildItem(context, Icons.notifications, "Thông báo"),

            const Divider(height: 40, thickness: 1, color: Colors.white24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Đang giảng dạy",
                style: TextStyle(color: isDark ? Colors.white70 : Colors.purple[700], fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF9D50BB),
                child: Text("H", style: TextStyle(color: Colors.white)),
              ),
              title: const Text("Học Tập Để Thành Công", style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {},
            ),

            const Divider(height: 40),

            _buildItem(context, Icons.settings, "Cài đặt"),
            _buildItem(context, Icons.help_outline, "Trợ giúp"),

            // NÚT ĐĂNG XUẤT – ĐẸP, AN TOÀN, KHÔNG LỖI
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                "Đăng xuất",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, {bool selected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: selected ? const Color(0xFFE0AAFF) : (isDark ? Colors.white70 : Colors.purple[700])),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? const Color(0xFFE0AAFF) : (isDark ? Colors.white70 : Colors.purple[800]),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFF9D50BB).withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onTap: () => Navigator.pop(context),
    );
  }
}