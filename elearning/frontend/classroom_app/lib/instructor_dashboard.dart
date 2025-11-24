// lib/instructor_dashboard.dart
// HEADER GIỐNG HỆT 100% class_list_screen.dart – TỪNG PIXEL, TỪNG DÒNG CODE!
// GIỮ NGUYÊN 6 Ô + BIỂU ĐỒ BẠN ĐANG THÍCH

import 'dart:math';
import 'package:classroom_app/providers/semester_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/class_list_screen.dart';        // Đường dẫn đúng của bạn
import 'instructor_drawer.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _showSemesterPicker(BuildContext context) {
    final provider = Provider.of<SemesterProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Chọn học kỳ", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...provider.list.map((semester) => ListTile(
                    leading: Icon(
                      semester.id == provider.current?.id ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: const Color(0xFF6E48AA),
                    ),
                    title: Text(semester.name),
                    selected: semester.id == provider.current?.id,
                    onTap: () {
                      provider.select(semester);
                      Navigator.pop(ctx);
                      setState(() {}); // Cập nhật dashboard
                    },
                  )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.green),
                title: const Text("Tạo học kỳ mới"),
                onTap: () {
                  Navigator.pop(ctx);
                  _createNewSemester(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewSemester(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tạo học kỳ mới"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "VD: Học kỳ 2 - 2025-2026",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E48AA)),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Provider.of<SemesterProvider>(context, listen: false).add(controller.text.trim());
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text("Tạo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // === HÀM LEGEND AN TOÀN – KHÔNG LỖI CONTEXT ===
  Widget _buildLegendItem(String text, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const InstructorDrawer(),

      // HEADER GIỐNG HỆT 100% class_list_screen.dart CỦA BẠN
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF6E48AA).withOpacity(0.98),
                      const Color(0xFF9D50BB).withOpacity(0.95),
                    ]
                  : [
                      const Color(0xFF9D50BB).withOpacity(0.98),
                      const Color(0xFF6E48AA).withOpacity(0.95),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.6 : 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),

        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 32,
                shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "E-Learning",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: isDark
                        ? [const Color(0xFFE0AAFF), Colors.white]
                        : [Colors.white, const Color(0xFFE0AAFF)],
                  ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
                letterSpacing: 1.5,
                shadows: const [
                  Shadow(offset: Offset(0, 3), blurRadius: 12, color: Colors.black54),
                ],
              ),
            ),
            Text(
              "Instructor's Dashboard",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),

        actions: [
          // NÚT HỌC KỲ – ĐẸP, KẾ BÊN AVATAR, CHUẨN TDTU
          Consumer<SemesterProvider>(
            builder: (context, semesterProvider, child) {
              final current = semesterProvider.current ?? Semester(id: "", name: "Chưa chọn học kỳ");

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showSemesterPicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6E48AA), Color(0xFF9D50BB)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              current.name.length > 18 ? "${current.name.substring(0, 18)}..." : current.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              );
            },
          ),

          // Avatar GV (giữ nguyên)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(radius: 22, backgroundColor: Color(0xFF6E48AA), child: Text("GV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                  ),
                ),
                const SizedBox(height: 4),
                const Text("Giảng viên", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),

      // BODY: NỀN SÓNG NEBULA + 6 Ô + BIỂU ĐỒ
      body: Stack(
        children: [
          // Nền sóng Nebula giống hệt
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _NebulaWavePainter(_waveAnimation.value, isDark),
            ),
          ),

          // Nội dung chính – giữ nguyên 6 ô + biểu đồ bạn thích
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 20), // 100 để tránh bị AppBar che
              child: Column(
                children: [
                  // HÀNG 1
                  Row(
                    children: [
                      _buildBigCard(context, title: "Lớp học", count: "12", icon: Icons.class_, color: const Color(0xFF8E24AA), onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassListScreen()));
                      }),
                      const SizedBox(width: 16),
                      _buildBigCard(context, title: "Sinh viên", count: "248", icon: Icons.people, color: const Color(0xFF3949AB)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // HÀNG 2
                  Row(
                    children: [
                      _buildBigCard(context, title: "Quiz", count: "18", icon: Icons.quiz, color: const Color(0xFFFF8F00)),
                      const SizedBox(width: 16),
                      _buildBigCard(context, title: "Bài tập", count: "24", icon: Icons.assignment_turned_in, color: const Color(0xFF2E7D32)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // HÀNG 3
                  Row(
                    children: [
                      _buildBigCard(context, title: "Thông báo", count: "5 mới", icon: Icons.notifications_active, color: const Color(0xFFD32F2F)),
                      const SizedBox(width: 16),
                      _buildBigCard(context, title: "Báo cáo", count: "", icon: Icons.bar_chart, color: const Color(0xFF00695C)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // BIỂU ĐỒ TRÒN ĐẸP LUNG LINH
                  Card(
                    elevation: 16,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [Colors.grey[900]!, const Color(0xFF1A0033)]
                              : [Colors.white, const Color(0xFFF8F5FF)],
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Tỷ lệ hoàn thành khóa học",
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // BIỂU ĐỒ TRÒN – ĐÃ BỎ VÒNG TRẮNG Ở GIỮA
                          SizedBox(
                            height: 240,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(240, 240),
                                  painter: CleanDonutPainter(
                                    values: [68, 22, 10],
                                    colors: const [
                                      Color(0xFF4CAF50), // Xanh hoàn thành
                                      Color(0xFFFFC107), // Vàng đang học
                                      Color(0xFFE53935), // Đỏ chưa bắt đầu
                                    ],
                                  ),
                                ),

                                // CHỮ TRUNG TÂM – RÕ RÀNG, ĐẸP Ở CẢ 2 MODE
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "68%",
                                      style: TextStyle(
                                        fontSize: 68,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF6A1B9A),
                                        shadows: isDark
                                            ? [
                                                const Shadow(
                                                  offset: Offset(0, 2),
                                                  blurRadius: 12,
                                                  color: Colors.black54,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Hoàn thành",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // LEGEND ĐẸP – KHÔNG DÙNG CONTEXT TRONG HÀM RIÊNG → KHÔNG LỖI!
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem("Hoàn thành", const Color(0xFF4CAF50), isDark),
                              _buildLegendItem("Đang học", const Color(0xFFFFC107), isDark),
                              _buildLegendItem("Chưa bắt đầu", const Color(0xFFE53935), isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // GIỮ NGUYÊN HÀM CŨ BẠN THÍCH
  Widget _buildBigCard(BuildContext context, {required String title, required String count, required IconData icon, required Color color, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: [color, color.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 28, backgroundColor: Colors.white.withOpacity(0.3), child: Icon(icon, size: 36, color: Colors.white)),
                const SizedBox(height: 20),
                Text(title, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(count.isEmpty ? "Xem chi tiết →" : count, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(String text, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

// COPY NGUYÊN XI TỪ class_list_screen.dart CỦA BẠN
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
      path1.lineTo(i, size.height * 0.3 + sin((i / size.width * 4 * 3.14159) + animationValue * 4 * 3.14159) * 60);
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    final path2 = Path();
    paint.color = (isDark ? const Color(0xFF9D50BB) : const Color(0xFF6E48AA)).withOpacity(0.25);
    path2.moveTo(0, size.height * 0.5);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(i, size.height * 0.5 + sin((i / size.width * 6 * 3.14159) - animationValue * 3 * 3.14159) * 80);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// === PAINTER MỚI – KHÔNG CÓ VÒNG TRẮNG Ở GIỮA ===
class CleanDonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  CleanDonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;
    final strokeWidth = 34.0;
    double startAngle = -pi / 2;

    final total = values.reduce((a, b) => a + b);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    // BỎ HOÀN TOÀN VÒNG TRẮNG Ở GIỮA → ĐỂ TRONG SUỐT
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}