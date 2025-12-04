import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'role_provider.dart';
import 'theme_provider.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _error = "";
  bool _isLoading = false;
  bool _obscurePass = true;

  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (_, __) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _NebulaWavePainter(_waveAnimation.value, isDark),
              );
            },
          ),

          // Nội dung chính
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 30,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  color: Theme.of(context).cardColor.withOpacity(0.97),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 60, 40, 50),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => LinearGradient(
                            colors: isDark
                                ? [const Color(0xFFE0AAFF), const Color(0xFF9D50BB)]
                                : [const Color(0xFF6E48AA), const Color(0xFF9D50BB)],
                          ).createShader(bounds),
                          child: const Text(
                            "E-Learning",
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
                          ),
                        ),
                        const Text(
                          "Management App",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 50),

                        // Email
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87), // chữ trắng khi dark
                          decoration: InputDecoration(
                            labelText: "Email hoặc tên đăng nhập",
                            labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                            prefixIcon: Icon(Icons.person_outline, color: isDark ? Colors.white70 : const Color(0xFF9D50BB)),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.12) : Colors.grey[100],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: isDark ? Colors.white60 : const Color(0xFF6E48AA), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password + ẩn/hiện
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: "Mật khẩu",
                            labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                            prefixIcon: Icon(Icons.lock_outline, color: isDark ? Colors.white70 : const Color(0xFF9D50BB)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility,
                                          color: isDark ? Colors.white70 : Colors.grey[600]),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.12) : Colors.grey[100],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: isDark ? Colors.white60 : const Color(0xFF6E48AA), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Nút đăng nhập
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6E48AA),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 15,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),

                        const SizedBox(height: 25),              
                        const SizedBox(height: 20),
                        const Text("© 2025 • Final Project Flutter", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // NÚT CHUYỂN DARK/LIGHT MODE – ĐÃ HẾT LỖI ĐỎ
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white.withOpacity(0.9),
              elevation: 10,
              child: Icon(
                isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                color: isDark ? Colors.amber : Colors.deepPurple,
                size: 28,
              ),
              onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    _error = ""; // reset lỗi cũ
    try {
      String? role;

      // 1. Kiểm tra tài khoản admin (giả lập giảng viên)
      if (_emailCtrl.text.trim() == "admin" && _passCtrl.text == "admin") {
        role = "instructor";

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userEmail", "admin");
        await prefs.setString("role", "instructor"); // lưu luôn role để lần sau tự động login nếu cần
      } 
      // 2. Đăng nhập sinh viên thật qua API
      else {
        final data = await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
        final prefs = await SharedPreferences.getInstance();
        final userData = data["user"];
        final userRole = data["role"];
        if (userData != null && userData["_id"] != null && userRole == 'student') {
          final studentId = userData["_id"];
          final studentName = userData["name"] as String?;
          // 🔑 Lưu ID của người dùng vào key 'userId'
          await prefs.setString('userId', userData["_id"]); 
          if (studentName != null) {
            await prefs.setString('studentName', studentName);
        }
          print("Lưu Student ID thành công: ${studentId}");
      }
        await prefs.setString("userEmail", data['user']['email']);
        if (data['token'] != null) await prefs.setString("token", data['token']);

        role = "student";
      }

      // Đặt role cho Provider
      Provider.of<RoleProvider>(context, listen: false).setRole(role);

      // ĐIỀU HƯỚNG VỀ HOME ĐỂ HOME TỰ CHECK ROLE VÀ CHUYỂN TRANG ĐÚNG
      // Dùng pushAndRemoveUntil để làm sạch navigation stack → tránh lỗi khi đăng xuất rồi đăng nhập lại
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
          (route) => false,
        );
      }
    } catch (e) {
      // Hiển thị lỗi đẹp
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Custom Painter hỗ trợ Dark mode
class _NebulaWavePainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  _NebulaWavePainter(this.animationValue, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final path1 = Path();
    paint.color = (isDark ? const Color(0xFF6E48AA) : const Color(0xFF9D50BB)).withOpacity(0.35);
    path1.moveTo(0, size.height * 0.3);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(i, size.height * 0.3 + sin((i / size.width * 4 * pi) + animationValue * 4 * pi) * 60);
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    final path2 = Path();
    paint.color = (isDark ? const Color(0xFF9D50BB) : const Color(0xFF6E48AA)).withOpacity(0.25);
    path2.moveTo(0, size.height * 0.5);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(i, size.height * 0.5 + sin((i / size.width * 6 * pi) - animationValue * 3 * pi) * 80);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}