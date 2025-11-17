import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'instructor_drawer.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class InstructorDashboard extends StatelessWidget {
  const InstructorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const InstructorDrawer(),
      body: Stack(
        children: [
          // Background sóng tím giống hệt SignIn – cùng vibe 100%
          AnimatedBuilder(
            animation: AlwaysStoppedAnimation(DateTime.now().millisecondsSinceEpoch / 8000),
            builder: (_, __) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _NebulaWavePainter(DateTime.now().millisecondsSinceEpoch / 8000 % 1, isDark),
              );
            },
          ),

          // Nội dung chính
          SafeArea(
            child: Column(
              children: [
                // AppBar + Semester Switcher (yêu cầu bắt buộc trong đề)
                _buildAppBar(context),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      

                        const SizedBox(height: 32),

                        // 6 Metric Cards – đẹp, gradient, shadow
                        _buildMetricGrid(isDark),

                        const SizedBox(height: 40),

                        // Biểu đồ tiến độ nộp bài – đẹp lung linh
                        _buildSubmissionChart(isDark),

                        const SizedBox(height: 40),

                        // Nút Import CSV – nổi bật, đúng yêu cầu đề
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: mở màn hình Import CSV (sẽ làm sau)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Sắp có màn hình Import CSV preview + skip duplicate!")),
                              );
                            },
                            icon: const Icon(Icons.upload_file, size: 28),
                            label: const Text("IMPORT DANH SÁCH SINH VIÊN (CSV)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6E48AA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 20,
                              shadowColor: const Color(0xFF9D50BB).withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final semesters = ["HK1 2025-2026", "HK2 2024-2025", "HK1 2024-2025"];
    String currentSemester = semesters[0];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A1B9A),
            Color(0xFF8E24AA),
            Color(0xFFBA68C8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded, size: 32, color: Color(0xFF6A1B9A)),
              ),

              const SizedBox(width: 16),

              const Expanded(
                child: Text(
                  "DASHBOARD GIẢNG VIÊN",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white38),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentSemester,
                    dropdownColor: const Color(0xFF6A1B9A),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    items: semesters
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (v) {},
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              // Avatar
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      "GV",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A)),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chào mừng trở lại,",
                    style: TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                  Text(
                    "Giảng viên TDTU",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(bool isDark) {
    final metrics = [
      {"title": "Khóa học", "value": "18", "icon": Icons.book, "color": Colors.purple},
      {"title": "Nhóm học", "value": "54", "icon": Icons.groups, "color": Colors.blue},
      {"title": "Sinh viên", "value": "1.620", "icon": Icons.people, "color": Colors.green},
      {"title": "Bài tập", "value": "72", "icon": Icons.assignment, "color": Colors.orange},
      {"title": "Quiz", "value": "36", "icon": Icons.quiz, "color": Colors.red},
      {"title": "Thông báo", "value": "156", "icon": Icons.notifications_active, "color": Colors.teal},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, i) {
        final m = metrics[i];
        return Card(
          elevation: 15,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.95),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  (m["color"] as Color).withOpacity(0.7),
                  (m["color"] as Color).withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),            
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(m["icon"] as IconData, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(m["value"] as String, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(m["title"] as String, style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmissionChart(bool isDark) {
    return Card(
      elevation: 20,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Tiến độ nộp bài tập học kỳ hiện tại", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: CustomPaint(
                painter: _LineChartPainter(isDark),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter cho biểu đồ – tự vẽ, đẹp, mượt
class _LineChartPainter extends CustomPainter {
  final bool isDark;
  _LineChartPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [0.1, 0.3, 0.5, 0.75, 0.88, 0.98];
    for (int i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1 - points[i]);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Điểm tròn
    final dotPaint = Paint()..color = Colors.white;
    for (int i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height * (1 - points[i]);
      canvas.drawCircle(Offset(x, y), 10, dotPaint);
      canvas.drawCircle(Offset(x, y), 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// Background sóng giống hệt SignIn
class _NebulaWavePainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  _NebulaWavePainter(this.animationValue, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final path1 = Path();
    paint.color = (isDark ? const Color(0xFF6E48AA) : const Color(0xFF9D50BB)).withOpacity(isDark ? 0.35 : 0.55);
    path1.moveTo(0, size.height * 0.3);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(i, size.height * 0.3 + math.sin((i / size.width * 4 * math.pi) + animationValue * 4 * math.pi) * 60);
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    final path2 = Path();
    paint.color = (isDark ? const Color(0xFF9D50BB) : const Color(0xFF6E48AA)).withOpacity(isDark ? 0.25 : 0.45);    
    path2.moveTo(0, size.height * 0.5);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(i, size.height * 0.5 + math.sin((i / size.width * 6 * math.pi) - animationValue * 3 * math.pi) * 80);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}