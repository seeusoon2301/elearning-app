// lib/screens/home_page.dart - STUDENT HOMEPAGE - LOAD THẬT TỪ API, KHÔNG GÁN CỨNG, ĐẸP NHƯ GOOGLE CLASSROOM
import 'dart:convert';
import 'dart:math';
import 'package:classroom_app/screens/student_profile_screen.dart';
import 'package:classroom_app/student_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'providers/semester_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  List<dynamic> enrolledClasses = [];
  String studentName = "Sinh viên";
  String studentEmail = "";
  bool isLoading = true;

  // Danh sách màu ngẫu nhiên nhưng đẹp, dùng để tô lớp học
  final List<Color> classColors = [
    const Color(0xFF6E48AA),
    const Color(0xFF9D50BB),
    const Color(0xFFE0AAFF),
    const Color(0xFF00C4B4),
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFD93D),
    const Color(0xFF7209B7),
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("userEmail") ?? "";

    if (email.isEmpty || email == "admin") {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      // LOAD THẬT TỪ API – CÁC LỚP MÀ SINH VIÊN NÀY ĐÃ ĐƯỢC MỜI/THAM GIA
      final List<dynamic> courses = await ApiService.getStudentCourses(email);

      setState(() {
        studentEmail = email;
        studentName = email.split('@').first.replaceAll('.', ' ').split(' ').map((s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1)).join(' ');
        enrolledClasses = courses;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không tải được lớp học: $e"), backgroundColor: Colors.red),
      );
    }
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
                  onTap: () async {
                    provider.select(semester);
                    Navigator.pop(ctx);
                    // TỰ ĐỘNG LOAD LẠI LỚP THEO HỌC KỲ
                    await _loadStudentData(); // Gọi lại API
                  },
                )),
          ],
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const StudentDrawer(), // Nếu có drawer thì để, không thì xóa

      // HEADER GIỐNG HỆT INSTRUCTOR DASHBOARD
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 100,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF6E48AA).withOpacity(0.98), const Color(0xFF9D50BB).withOpacity(0.95)]
                    : [const Color(0xFF9D50BB).withOpacity(0.98), const Color(0xFF6E48AA).withOpacity(0.95)],
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
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 32),
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
                      colors: isDark ? [const Color(0xFFE0AAFF), Colors.white] : [Colors.white, const Color(0xFFE0AAFF)],
                    ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
                  letterSpacing: 1.5,
                  shadows: const [Shadow(offset: Offset(0, 3), blurRadius: 12, color: Colors.black54)],
                ),
              ),
              const Text(
                "Student's Home",
                style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500, letterSpacing: 1.2),
              ),
            ],
          ),

          actions: [
            // NÚT HỌC KỲ – GIỐNG HỆT INSTRUCTOR 100%
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
                                current.name.length > 20 ? "${current.name.substring(0, 20)}..." : current.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProfileScreen()));
                  if (mounted) setState(() {});
                },
                child: FutureBuilder<Map<String, String>>(
                  future: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final name = prefs.getString('studentName')?.trim();
                    final avatar64 = prefs.getString('studentAvatarBase64') ?? '';
                    return {'name': name?.isNotEmpty == true ? name! : "Học sinh", 'avatar': avatar64};
                  }(),
                  builder: (context, snapshot) {
                    final data = snapshot.data ?? {'name': "Học sinh", 'avatar': ''};
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
      ),

      // NÚT + Ở GÓC DƯỚI PHẢI
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6E48AA),
        elevation: 12,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        onPressed: _showJoinClassDialog,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // BODY
      body: Stack(
        children: [
          // Nền wave
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _NebulaWavePainter(_waveAnimation.value, isDark),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20), // Đẩy nội dung xuống dưới AppBar

                // "Lớp học của bạn" – ĐƯA LÊN GẦN HEADER, GỌN ĐẸP
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    "Lớp học của bạn",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 16), // Khoảng cách vừa đủ, không bị "đần"

                // NỘI DUNG CHÍNH
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6E48AA)))
                      : enrolledClasses.isEmpty
                          ? _buildEmptyState(isDark)
                          : _buildClassGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TRẠNG THÁI RỖNG – ĐẸP, GIỮA MÀN HÌNH
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 120,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 32),
          Text(
            "Hiện tại bạn chưa tham gia lớp học nào",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Nhấn nút (+) để tham gia bằng mã lớp",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // GRID LỚP HỌC – MÀU NGẪU NHIÊN ĐẸP
  Widget _buildClassGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
      ),
      itemCount: enrolledClasses.length,
      itemBuilder: (ctx, index) {
        final cls = enrolledClasses[index];
        final color = classColors[index % classColors.length];
        return _buildClassTile(cls, color, index); // <-- truyền index vào
      },
    );
  }

  // CARD LỚP HỌC SIÊU ĐẸP
  Widget _buildClassTile(Map<String, dynamic> cls, Color baseColor, int index) {
  return GestureDetector(
    onTap: () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đang mở: ${cls['name'] ?? 'Lớp học'}"), backgroundColor: baseColor),
      );
    },
    child: Hero(
      tag: "class-${cls['id'] ?? index}", // <-- DÙNG index THAY VÌ i
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [baseColor, baseColor.withOpacity(0.85)],
          ),
          boxShadow: [
            BoxShadow(color: baseColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.auto_stories, size: 100, color: Colors.white.withOpacity(0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    child: const Icon(Icons.menu_book, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    cls['name'] ?? "Lớp không tên",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cls['code'] ?? "",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cls['instructorName'] ?? cls['instructor'] ?? "Giảng viên",
                    style: TextStyle(color: Colors.white60, fontSize: 13),
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

  // Dialog nhập mã lớp (có thể làm sau)
  void _showJoinClassDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tham gia lớp học"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nhập mã lớp"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Đã gửi yêu cầu tham gia mã: ${controller.text}")),
              );
            },
            child: const Text("Tham gia"),
          ),
        ],
      ),
    );
  }
}

// Nền wave – giữ nguyên, đẹp hoàn hảo
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