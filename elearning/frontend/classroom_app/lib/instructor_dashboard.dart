// lib/instructor_dashboard.dart
import 'dart:convert';
import 'dart:io';
import 'package:classroom_app/screens/instructor_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './screens/quiz_list_screen.dart';
import 'dart:math';
import 'package:classroom_app/providers/semester_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/class_list_screen.dart';        // Đường dẫn đúng của bạn
import 'instructor_drawer.dart';

// Giả định: Semester và SemesterProvider được định nghĩa trong ../providers/semester_provider.dart

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
    // Giả định: Tải hoặc chọn học kỳ ban đầu ở đây
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<SemesterProvider>(context, listen: false).loadInitial();
    // });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _showSemesterPicker(BuildContext context) {
    // ... (logic giữ nguyên)
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
                    // Giả định Semester là một class có id và name
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
    // ... (logic giữ nguyên)
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
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final provider = Provider.of<SemesterProvider>(context, listen: false);
                await provider.add(name);
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

  // 🔥 HÀM _buildBigCard ĐÃ CẬP NHẬT KIỂM TRA HỌC KỲ
  Widget _buildBigCard(BuildContext context, {required String title, required String count, required IconData icon, required Color color, VoidCallback? onTap}) {
    final isClassCard = title == "Lớp học";
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isClassCard) {
            // Lấy SemesterProvider để kiểm tra học kỳ
            final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
            // Giả định Semester class có thuộc tính id và name
            if (semesterProvider.current == null || semesterProvider.current!.id.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Vui lòng chọn hoặc tạo Học kỳ trước khi xem lớp học."),
                    backgroundColor: Color(0xFF9D50BB),
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
            }
          }
          // Thực hiện điều hướng/hành động mặc định
          onTap?.call();
        },
        child: Card(
          elevation: 16,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.9), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: Colors.white, size: 48),
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(offset: Offset(0, 2), blurRadius: 10, color: Colors.black54)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // === HÀM LEGEND AN TOÀN – KHÔNG LỖI CONTEXT === (Giữ nguyên)
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

      // HEADER (Giữ nguyên)
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
          // NÚT HỌC KỲ – CÓ LISTENER ĐỂ HIỂN THỊ TÊN HỌC KỲ
          Consumer<SemesterProvider>(
            builder: (context, semesterProvider, child) {
              // Giả định Semester là một class có id và name
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

          // ĐOẠN NÀY DÁN VÀO PHẦN actions: CỦA AppBar TRONG INSTRUCTOR DASHBOARD
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructorProfileScreen()));
                if (mounted) setState(() {});
              },
              child: FutureBuilder<Map<String, String>>(
                future: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final name = prefs.getString('instructorName')?.trim();
                  final avatar64 = prefs.getString('instructorAvatarBase64') ?? '';
                  return {'name': name?.isNotEmpty == true ? name! : "Giảng viên", 'avatar': avatar64};
                }(),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? {'name': "Giảng viên", 'avatar': ''};
                  final name = data['name']!;
                  final avatar64 = data['avatar']!;
                  final hasAvatar = avatar64.isNotEmpty;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF6E48AA),
                          backgroundImage: hasAvatar ? MemoryImage(base64Decode(avatar64)) : null,
                          child: hasAvatar ? null : Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // BODY (Giữ nguyên)
      body: Stack(
        children: [
          // Nền sóng Nebula
          AnimatedBuilder(
            animation: _waveAnimation,
            // Giả định _NebulaWavePainter được định nghĩa ở cuối file
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _NebulaWavePainter(_waveAnimation.value, isDark),
            ),
          ),

          // Nội dung chính
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 20), 
              child: Column(
                children: [
                  // Nếu không có học kỳ, hiển thị thông báo
                  Consumer<SemesterProvider>(builder: (context, provider, child) {
                    // Giả định provider.list được tải từ API (hoặc là list rỗng)
                    if (provider.list.isNotEmpty) return const SizedBox.shrink(); 
                    return Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Chưa có học kỳ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 6),
                                  Text('Hãy tạo học kỳ mới từ server để quản lý lớp học.'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E48AA)),
                              onPressed: () => _createNewSemester(context),
                              child: const Text('Tạo học kỳ mới', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // HÀNG 1: Lớp học
                  Row(
                    children: [
                      // NƠI GỌI HÀM _buildBigCard ĐÃ CẬP NHẬT
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
                      _buildBigCard(
                        context,
                        title: "Quiz",
                        count: "18",
                        icon: Icons.quiz_rounded,
                        color: const Color(0xFFFF8F00),
                        onTap: () {
                          final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
                          if (semesterProvider.current == null || semesterProvider.current!.id.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Vui lòng chọn hoặc tạo Học kỳ trước khi xem Quiz."),
                                backgroundColor: Color(0xFFFF8F00),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QuizListScreen()),
                          );
                        },
                      ),
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

                  // BIỂU ĐỒ TRÒN
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
                          colors: isDark ? [Colors.grey[900]!, const Color(0xFF1A0033)] : [Colors.white, const Color(0xFFF8F5FF)],
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

                          // BIỂU ĐỒ TRÒN
                          SizedBox(
                            height: 240,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Giả định CleanDonutPainter được định nghĩa ở cuối file
                                CustomPaint(
                                  size: const Size(240, 240),
                                  painter: CleanDonutPainter(
                                    values: [68, 22, 10], // Giả định %
                                    colors: const [Color(0xFF6E48AA), Colors.green, Colors.red],
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "68%",
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF6E48AA),
                                      ),
                                    ),
                                    Text(
                                      "Đã hoàn thành",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Phần Legend của biểu đồ
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLegendItem("Hoàn thành (68%)", const Color(0xFF6E48AA), isDark),
                              _buildLegendItem("Đang học (22%)", Colors.green, isDark),
                              _buildLegendItem("Thất bại (10%)", Colors.red, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === PAINTER SÓNG (Giữ nguyên) ===
class _NebulaWavePainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  _NebulaWavePainter(this.animationValue, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Sóng 1 (lớn)
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

    // Sóng 2 (nhỏ hơn, màu đậm hơn)
    final path2 = Path();
    paint.color = (isDark ? const Color(0xFF9D50BB) : const Color(0xFF6E48AA)).withOpacity(0.35);
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

// === PAINTER DONUT (Giữ nguyên) ===
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}