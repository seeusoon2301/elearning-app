import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart'; // ⭐️ CẦN CHỈNH SỬA ĐƯỜNG DẪN NẾU CẦN
import 'instructor_profile_screen.dart';

class InstructorSettingsScreen extends StatefulWidget {
  const InstructorSettingsScreen({super.key});

  @override
  State<InstructorSettingsScreen> createState() => _InstructorSettingsScreenState();
}

class _InstructorSettingsScreenState extends State<InstructorSettingsScreen> {
  // Biến cục bộ để hiển thị trạng thái hiện tại của Switch
  bool _isDarkMode = false; 
  final Color primaryColor = const Color(0xFF9D50BB); // Màu chủ đạo (Tím)
  
  // Biến theo dõi để chỉ khởi tạo theme một lần duy nhất
  bool _isThemeInitialized = false; 
  
  // Sử dụng didChangeDependencies() để truy cập Provider an toàn
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Khởi tạo _isDarkMode từ ThemeProvider
    if (!_isThemeInitialized) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      // Giả định ThemeProvider có thuộc tính themeMode
      _isDarkMode = themeProvider.themeMode == ThemeMode.dark;
      _isThemeInitialized = true;
    }
  }
  
  // Hàm chuyển đổi chế độ Sáng/Tối
  void _toggleTheme(bool newValue) {
    // ⭐️ GỌI PROVIDER: Dùng toggleTheme() của ThemeProvider để thay đổi Theme toàn ứng dụng
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
    
    // Cập nhật trạng thái cục bộ để Switch lập tức thay đổi (dù Provider cũng sẽ rebuild)
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
    // ⭐️ Lắng nghe Provider ở đây để UI tự cập nhật khi theme thay đổi
    // (Dù SwitchListTile sử dụng giá trị cục bộ, việc rebuild toàn bộ màn hình vẫn cần thiết)
    // Hoặc chỉ cần lắng nghe themeProvider.themeMode để lấy themeMode hiện tại
    final currentThemeMode = Provider.of<ThemeProvider>(context).themeMode;
    // Cập nhật _isDarkMode dựa trên ThemeMode hiện tại (nếu bạn muốn nó luôn đồng bộ)
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
              // ⭐️ LOGIC ĐIỀU HƯỚNG ĐÃ SỬA
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InstructorProfileScreen()),
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
            // Sử dụng _isDarkMode đã được cập nhật từ Provider
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