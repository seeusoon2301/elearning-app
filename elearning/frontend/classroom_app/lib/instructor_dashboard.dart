// lib/instructor_dashboard.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'screens/create_class_screen.dart';
import 'instructor_drawer.dart';
class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  List<Map<String, String>> classes = [
    {'name': 'Học Tập Để Thành Công', 'section': '', 'room': '', 'subject': ''},
  ];

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

  void _addNewClass(Map<String, String> newClass) {
    setState(() {
      classes.add(newClass);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,

      // HEADER ĐÃ ĐƯỢC NÂNG CẤP SIÊU ĐẸP, SIÊU NỔI, SIÊU CHUẨN TDTU
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90, // Tăng chiều cao cho sang trọng
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
              icon: Icon(
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
                shadows: [
                  Shadow(
                    offset: const Offset(0, 3),
                    blurRadius: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF6E48AA),
                      child: const Text(
                        "GV",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Giảng viên",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      drawer: const InstructorDrawer(),

      body: Stack(
        children: [
          // Nền Nebula Wave
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _NebulaWavePainter(_waveAnimation.value, isDark),
            ),
          ),

          // Danh sách lớp học
          SafeArea(
            child: Column(
              children: [
                // HEADER ĐÃ NÂNG CẤP SIÊU ĐẸP (bạn đã có rồi, giữ nguyên)
                // ... (phần header tím của bạn)

                const SizedBox(height: 20),

                // DANH SÁCH LỚP HỌC – ĐÃ SỬA HOÀN TOÀN, KHÔNG LỖI, CÓ INDEX
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final cls = classes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildClassCard(cls, index), // ĐÃ TRUYỀN INDEX → KHÔNG LỖI
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6E48AA),
        elevation: 15,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateClassScreen(onClassCreated: _addNewClass)),
          );
        },
      ),
    );
  }

  // _buildClassCard và _NebulaWavePainter giữ nguyên như cũ
  Widget _buildClassCard(Map<String, String> cls, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> backgrounds = [
      'assets/images/banner1.jpg',
      'assets/images/banner2.jpg',
      'assets/images/banner3.jpg',
    ];
    final String bgImage = backgrounds[index % backgrounds.length];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 200,
          child: Stack(
            children: [
              // Ảnh nền
              Positioned.fill(
                child: Image.asset(
                  bgImage,
                  fit: BoxFit.cover,
                ),
              ),

              // Lớp tối nhẹ để chữ dễ đọc
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),

              // Nội dung chính
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cls['name'] ?? 'Lớp học',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(offset: Offset(0, 2), blurRadius: 8, color: Colors.black87),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        if ((cls['section'] ?? '').isNotEmpty)
                          _infoRow(Icons.segment, "Phần: ${cls['section']}"),
                        if ((cls['room'] ?? '').isNotEmpty)
                          _infoRow(Icons.room, "Phòng: ${cls['room']}"),
                        if ((cls['subject'] ?? '').isNotEmpty)
                          _infoRow(Icons.book, "Chủ đề: ${cls['subject']}"),
                      ],
                    ),

                    // NÚT 3 CHẤM + MENU XÓA
                    Align(
                      alignment: Alignment.bottomRight,
                      child: PopupMenuButton<String>(
                        color: isDark ? Colors.grey[900]! : Colors.white, // ĐỒNG BỘ DARK/LIGHT
                        surfaceTintColor: Colors.transparent,
                        shadowColor: Colors.black.withOpacity(0.3),
                        elevation: 12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        offset: const Offset(0, -50),
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: isDark ? Colors.grey[900]! : Colors.white,
                                surfaceTintColor: Colors.transparent,
                                title: Row(
                                  children: [
                                    const Icon(Icons.delete, color: Colors.red, size: 28),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Xóa lớp học",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  "Bạn có chắc chắn muốn xóa lớp \"${cls['name'] ?? 'này'}\" không?\n\nHành động này không thể hoàn tác.",
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(
                                      "Hủy",
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        classes.removeAt(index);
                                      });
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Đã xóa lớp học thành công!"),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: const Text("Xóa", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, color: Colors.red),
                                const SizedBox(width: 12),
                                Text(
                                  "Xóa lớp học",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget hỗ trợ hiển thị thông tin lớp
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// _NebulaWavePainter giữ nguyên như cũ...
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