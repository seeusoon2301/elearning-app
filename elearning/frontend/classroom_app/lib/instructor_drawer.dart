// lib/instructor_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../signin.dart';
import 'role_provider.dart';
import 'services/api_service.dart';   // <<< THÊM DÒNG NÀY
import 'instructor_dashboard.dart';
import './screens/quiz_list_screen.dart';

class InstructorDrawer extends StatelessWidget {
  const InstructorDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

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
            // HEADER
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

            _buildItem(
              context,
              Icons.home,
              "Trang chủ",
              selected: true,
              onTap: () {
                Navigator.pop(context);
                // Chỉ chuyển trang nếu chưa đang ở Dashboard
                if (!Navigator.canPop(context) || ModalRoute.of(context)?.settings.name != '/dashboard') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const InstructorDashboard()),
                  );
                }
              },
            ),
            _buildItem(
              context, 
              Icons.quiz, 
              "Quizzes",
              onTap: () {
                Navigator.pop(context); // Đóng drawer
                // Chuyển đến trang QuizListScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizListScreen()),
                );
              },
            ),
            _buildItem(context, Icons.calendar_today, "Lịch"),
            _buildItem(context, Icons.notifications, "Thông báo"),

            const Divider(height: 40, thickness: 1, color: Colors.white24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Đang giảng dạy",
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.purple[700],
                    fontWeight: FontWeight.bold),
              ),
            ),

            // 🟣🟣 FUTURE BUILDER LẤY DỮ LIỆU TỪ API 🟣🟣
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ApiService.fetchAllClasses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Lỗi khi tải lớp học",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final classes = snapshot.data ?? [];

                if (classes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Không có lớp nào."),
                  );
                }

                return Column(
                  children: classes.map((cls) {
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF9D50BB),
                        child: Icon(Icons.class_, color: Colors.white),
                      ),
                      title: Text(
                        cls["name"] ?? "Không tên",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Phòng: ${cls["room"] ?? "N/A"}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {},
                    );
                  }).toList(),
                );
              },
            ),

            const Divider(height: 40),

            _buildItem(context, Icons.settings, "Cài đặt"),
            _buildItem(context, Icons.help_outline, "Trợ giúp"),

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

  Widget _buildItem(BuildContext context, IconData icon, String title, {bool selected = false, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icon, 
        color: selected ? const Color(0xFFE0AAFF) : (isDark ? Colors.white70 : Colors.purple[700])
      ),
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
      onTap: onTap ?? () => Navigator.pop(context), // Nếu không truyền onTap → đóng drawer như cũ
    );
  }
}
