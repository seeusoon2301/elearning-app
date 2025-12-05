import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart'; // ⭐️ CẦN CHỈNH SỬA ĐƯỜNG DẪN NẾU CẦN
import 'student_profile_screen.dart'; // Giả định có trang Profile cho sinh viên

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  // Biến cục bộ để hiển thị trạng thái hiện tại của Switch
  bool _isDarkMode = false; 
  final Color primaryColor = const Color(0xFF6E48AA); // Màu chủ đạo của Sinh viên (Xanh tím than)
  
  // Biến theo dõi để chỉ khởi tạo theme một lần duy nhất
  bool _isThemeInitialized = false; 
  
  // Sử dụng didChangeDependencies() để truy cập Provider an toàn
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Khởi tạo _isDarkMode từ ThemeProvider
    if (!_isThemeInitialized) {
      // Sử dụng listen: false để tránh gọi rebuild không cần thiết
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false); 
      _isDarkMode = themeProvider.themeMode == ThemeMode.dark;
      _isThemeInitialized = true;
    }
  }
  
  // Hàm chuyển đổi chế độ Sáng/Tối
  void _toggleTheme(bool newValue) {
    // Gọi hàm toggleTheme() của ThemeProvider để thay đổi Theme toàn ứng dụng
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
    
    // Cập nhật trạng thái cục bộ
    setState(() {
      _isDarkMode = newValue;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chuyển sang chế độ ${newValue ? "Tối" : "Sáng"}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe ThemeProvider để UI tự cập nhật khi theme thay đổi
    final currentThemeMode = Provider.of<ThemeProvider>(context).themeMode;
    _isDarkMode = currentThemeMode == ThemeMode.dark; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 1. Chỉnh sửa Profile
          ListTile(
            leading: Icon(Icons.person_rounded, color: primaryColor),
            title: const Text('Chỉnh sửa Profile', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Cập nhật thông tin cá nhân và mật khẩu.'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              // Điều hướng đến trang Student Profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),

          // 2. Nút Switch Dark/Light Mode
          SwitchListTile(
            secondary: Icon(
              _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: _isDarkMode ? Colors.amber : Colors.blueGrey,
            ),
            title: const Text('Chế độ Tối (Dark Mode)'),
            subtitle: Text('Chuyển đổi giao diện sang chế độ ${_isDarkMode ? "Sáng" : "Tối"}.'),
            value: _isDarkMode, 
            onChanged: _toggleTheme,
            activeColor: primaryColor,
          ),
          const Divider(indent: 16, endIndent: 16),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}