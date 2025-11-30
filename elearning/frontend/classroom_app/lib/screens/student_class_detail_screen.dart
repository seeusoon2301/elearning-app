// lib/screens/student_class_detail_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../student_drawer.dart'; // ĐÃ ĐỔI THÀNH STUDENT DRAWER

class StudentClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const StudentClassDetailScreen({Key? key, required this.classData}) : super(key: key);

  @override
  State<StudentClassDetailScreen> createState() => _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  int _selectedIndex = 0;

  // Dữ liệu thông báo – dùng SharedPreferences để lưu tạm (giống giảng viên)
  List<String> _announcements = [];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);

    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'student_announcements_${widget.classData['_id'] ?? widget.classData['name']}';
    final saved = prefs.getStringList(key) ?? [
      "Chào mừng đến với lớp học!",
      "Tuần này có Quiz 1 vào thứ 4",
      "Bài tập 1 hạn nộp: 20/03/2025"
    ];
    if (mounted) setState(() => _announcements = saved);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? const Color(0xFFE0AAFF) : const Color(0xFF6E48AA);

    final className = widget.classData['name'] ?? 'Lớp học';
    final instructor = widget.classData['instructor'] ?? 'Giảng viên';
    final room = widget.classData['room'] ?? 'Phòng học trực tuyến';

    return Scaffold(
      extendBodyBehindAppBar: true,

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
                  ? [const Color(0xFF6E48AA).withOpacity(0.98), const Color(0xFF9D50BB).withOpacity(0.95)]
                  : [const Color(0xFF9D50BB).withOpacity(0.98), const Color(0xFF6E48AA).withOpacity(0.95)],
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.6 : 0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
        ),

        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: Colors.white, size: 32,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 10)],
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              className,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
                shadows: [Shadow(offset: Offset(0, 3), blurRadius: 12, color: Colors.black54)],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 32),
              onPressed: () {},
            ),
          ),
        ],
      ),

      drawer: const StudentDrawer(), // ĐÃ ĐỔI THÀNH STUDENT DRAWER

      body: Stack(
        children: [
          // Nền wave đẹp y hệt giảng viên
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _NebulaWavePainter(_waveAnimation.value, isDark),
            ),
          ),

          SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 30),

                // Card thông tin lớp – giống hệt
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(Icons.person, "Giảng viên: $instructor", iconColor, textColor),
                          _infoRow(Icons.room, "Phòng: $room", iconColor, textColor),
                          _infoRow(Icons.code, "Mã lớp: ${widget.classData['code'] ?? 'N/A'}", iconColor, textColor),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 3 TAB CHO SINH VIÊN
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: <Widget>[
                      _StreamTab(announcements: _announcements),
                      const _AssignmentsTab(),
                      const _PeopleTab(),
                    ][_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation giống hệt
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF6E48AA), const Color(0xFF9D50BB)]
                : [const Color(0xFF9D50BB), const Color(0xFF6E48AA)],
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15)],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Bảng tin"),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: "Bài tập"),
            BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: "Mọi người"),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color iconColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 14),
          Text(text, style: TextStyle(fontSize: 17, color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ==================== TAB BẢNG TIN (STREAM) CHO SINH VIÊN ====================
class _StreamTab extends StatelessWidget {
  final List<String> announcements;
  const _StreamTab({Key? key, required this.announcements}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return const Center(
        child: Text("Chưa có thông báo", style: TextStyle(fontSize: 20)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF6E48AA),
              child: Text("GV", style: TextStyle(color: Colors.white)),
            ),
            title: const Text("Giảng viên", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(announcements[index]),
            ),
            trailing: Text("vừa xong", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
        );
      },
    );
  }
}

// ==================== TAB BÀI TẬP ====================
class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final assignments = [
      {"title": "Bài tập 1: Todo List App", "due": "20/03/2025", "status": "Chưa nộp"},
      {"title": "Bài tập 2: Quản lý sinh viên", "due": "30/03/2025", "status": "Đã nộp"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final item = assignments[index];
        return Card(
          child: ListTile(
            leading: Icon(Icons.assignment, color: Colors.purple[600]),
            title: Text(item["title"]!, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("Hạn nộp: ${item["due"]}"),
            trailing: Chip(
              label: Text(item["status"]!, style: TextStyle(color: item["status"] == "Chưa nộp" ? Colors.red : Colors.green)),
              backgroundColor: (item["status"] == "Chưa nộp" ? Colors.red : Colors.green).withOpacity(0.2),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mở bài tập: ${item["title"]}")));
            },
          ),
        );
      },
    );
  }
}

// ==================== TAB MỌI NGƯỜI ====================
class _PeopleTab extends StatelessWidget {
  const _PeopleTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.orange, child: Text("GV")),
          title: const Text("Giảng viên"),
          subtitle: const Text("Nguyễn Văn A"),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text("Học viên", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ...["Trần Thị B", "Lê Văn C", "Phạm Thị D"].map((name) => ListTile(
          leading: CircleAvatar(child: Text(name[0])),
          title: Text(name),
        )),
      ],
    );
  }
}

// NỀN WAVE ĐẸP Y HỆT GIẢNG VIÊN
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