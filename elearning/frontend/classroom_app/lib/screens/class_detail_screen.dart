// lib/screens/class_detail_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../instructor_drawer.dart';
import './create_annoucement_screen.dart'; // ĐÚNG RỒI, DÙNG FILE RIÊNG
import 'package:shared_preferences/shared_preferences.dart'; // THÊM DÒNG NÀY

class ClassDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const ClassDetailScreen({Key? key, required this.classData}) : super(key: key);

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  int _selectedIndex = 0;
  
  // DANH SÁCH THÔNG BÁO RIÊNG CHO TỪNG LỚP
  List<String> _announcements = [];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
    _loadAnnouncements();
  }

  // THÊM 2 HÀM NÀY
  Future<void> _loadAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final classKey = 'class_${widget.classData['name'] ?? 'unknown'}';
    final savedList = prefs.getStringList(classKey) ?? [];
    setState(() {
      _announcements = savedList;
    });
  }

  Future<void> _saveAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final classKey = 'class_${widget.classData['name'] ?? 'unknown'}';
    await prefs.setStringList(classKey, _announcements);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // MÀU CHỮ & ICON ĐƯỢC TỐI ƯU CHO CẢ 2 CHẾ ĐỘ
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? const Color(0xFFE0AAFF) : const Color(0xFF6E48AA);

    final className = widget.classData['name'] ?? 'Lớp học';
    final subject = widget.classData['subject'] ?? '';
    final section = widget.classData['section'] ?? '';
    final room = widget.classData['room'] ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
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

        title: Text(className,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
            shadows: const [Shadow(offset: Offset(0, 3), blurRadius: 12, color: Colors.black54)],
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(icon: const Icon(Icons.more_vert, color: Colors.white, size: 32), onPressed: () {}),
          ),
        ],
      ),

      drawer: const InstructorDrawer(),

      body: Stack(
        children: [
          // Nền wave tím
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

                // Card thông tin lớp – màu chữ rõ ràng
                if (section.isNotEmpty || room.isNotEmpty)
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
                            if (section.isNotEmpty)
                              _infoRow(Icons.segment, "Phần: $section", iconColor, textColor),
                            if (room.isNotEmpty)
                              _infoRow(Icons.room, "Phòng: $room", iconColor, textColor),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // 3 TAB – MÀU CHỮ + ICON ĐẸP, NỔI BẬT
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: <Widget>[
                      StreamTab(
                        key: ValueKey(_announcements.length),
                        announcements: _announcements,
                        onDelete: (index) async {
                          setState(() {
                            _announcements.removeAt(index);
                          });
                          await _saveAnnouncements();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa thông báo")));
                        },
                        onEdit: (index, newText) async {
                          setState(() {
                            _announcements[index] = newText;
                          });
                          await _saveAnnouncements();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật thông báo")));
                        },
                      ),
                      AssignmentsTab(iconColor: iconColor, textColor: textColor, hintColor: hintColor),
                      PeopleTab(iconColor: iconColor, textColor: textColor),
                    ][_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom bar tím đẹp
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

      // DÙNG MÀN HÌNH RIÊNG – KHÔNG CÒN HÀM DƯ THỪA
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              heroTag: 'detailFab',
              backgroundColor: const Color(0xFF6E48AA),
              elevation: 15,
              child: const Icon(Icons.add, size: 32, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateAnnouncementScreen(
                      onCreated: (content) {
                        setState(() {
                          _announcements.insert(0, content);
                        });
                        _saveAnnouncements(); // LƯU NGAY LẬP TỨC
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Đăng thông báo thành công!"),
                            backgroundColor: Color(0xFF6E48AA),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            )
          : null,
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

// === 3 TAB ĐÃ CHỈNH MÀU HOÀN HẢO CHO DARK & LIGHT ===
// THAY TOÀN BỘ StreamTab BẰNG CÁI NÀY (cực đẹp, giống Google Classroom 100%)
class StreamTab extends StatelessWidget {
  final List<String> announcements;
  final Function(int) onDelete;
  final Function(int, String) onEdit;

  const StreamTab({
    Key? key,
    required this.announcements,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_rounded, size: 110, color: const Color.fromARGB(255, 96, 50, 170)),
            const SizedBox(height: 32),
            const Text("Chưa có thông báo nào", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("Bấm nút + để tạo thông báo đầu tiên", style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF6E48AA),
              child: Text("GV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Giảng viên", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("vừa xong", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(announcements[index]),
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(context, index, announcements[index]);
                } else if (value == 'delete') {
                  onDelete(index);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text("Chỉnh sửa")])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Xóa", style: TextStyle(color: Colors.red))])),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, int index, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Chỉnh sửa thông báo"),
        content: TextField(
          controller: controller,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Nhập nội dung mới",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E48AA)),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onEdit(index, controller.text.trim()); // GỌI TRỰC TIẾP CALLBACK
                Navigator.pop(ctx);
              }
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class AssignmentsTab extends StatelessWidget {
  final Color iconColor, textColor, hintColor;
  const AssignmentsTab({Key? key, required this.iconColor, required this.textColor, required this.hintColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 110, color: iconColor),
          const SizedBox(height: 32),
          Text("Đây là nơi giao bài tập",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 16),
          Text("Bạn có thể thêm bài tập & nhiệm vụ khác cho lớp",
              style: TextStyle(fontSize: 16, color: hintColor)),
        ],
      ),
    );
  }
}

class PeopleTab extends StatelessWidget {
  final Color iconColor, textColor;
  const PeopleTab({Key? key, required this.iconColor, required this.textColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(backgroundColor: const Color(0xFF6E48AA), child: Text("GV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          title: Text("Giáo viên", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          subtitle: Text("Bạn", style: TextStyle(color: textColor.withOpacity(0.8))),
        ),
        const Divider(height: 1),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_outlined, size: 110, color: iconColor.withOpacity(0.8)),
                const SizedBox(height: 32),
                Text("Mời học viên tham gia lớp học",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: Icon(Icons.person_add, color: iconColor),
                  label: Text("Mời học viên", style: TextStyle(color: iconColor, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: iconColor)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// _NebulaWavePainter giữ nguyên như cũ
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