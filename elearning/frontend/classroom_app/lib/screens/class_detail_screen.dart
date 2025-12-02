import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../instructor_drawer.dart';
import './create_annoucement_screen.dart';
import './invite_student_screen.dart';
// 1. IMPORT API SERVICE MỚI
import '../services/api_service.dart'; 


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
  
  // Dữ liệu cho tab Stream
  List<String> _announcements = [];
  
  // KEY DÙNG ĐỂ TRUY CẬP VÀO STATE CỦA WIDGET _StudentList
  final GlobalKey<_StudentListState> _studentListKey = GlobalKey<_StudentListState>();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
    
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'announcements_${widget.classData['_id'] ?? widget.classData['name']}';
    final saved = prefs.getStringList(key) ?? [];
    if (mounted) setState(() => _announcements = saved);
  }

  Future<void> _saveAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'announcements_${widget.classData['_id'] ?? widget.classData['name']}';
    await prefs.setStringList(key, _announcements);
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
    final instructor = widget.classData['instructor'] ?? '';
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
          // ⭐️ CẬP NHẬT: THAY ICON MỜI HỌC VIÊN BẰNG ICONS.ADD
          if (_selectedIndex == 2) 
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                // ĐÃ THAY Icons.person_add thành Icons.add
                icon: const Icon(Icons.add, color: Colors.white, size: 30),
                tooltip: 'Mời học viên mới',
                onPressed: () async {
                  // Đẩy đến màn hình mời
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InviteStudentScreen(
                        classId: widget.classData['_id']?.toString() ?? '',
                        className: widget.classData['name'] ?? 'Lớp học',
                      ),
                    ),
                  );

                  // KHI QUAY LẠI MÀN HÌNH NÀY, làm mới danh sách sinh viên
                  if (_selectedIndex == 2 && _studentListKey.currentState != null) {
                    _studentListKey.currentState!._refreshStudents();
                  }
                },
              ),
            ),
          
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

                // Card thông tin lớp
                if (instructor.isNotEmpty || room.isNotEmpty)
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
                            if (instructor.isNotEmpty)
                              _infoRow(Icons.segment, "Tên giảng viên: $instructor", iconColor, textColor),
                            if (room.isNotEmpty)
                              _infoRow(Icons.room, "Phòng: $room", iconColor, textColor),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // 3 TAB
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
                      // SỬ DỤNG WIDGET _StudentList MỚI ĐỂ GỌI API
                      _StudentList(
                        // GÁN KEY VÀO WIDGET _StudentList
                        key: _studentListKey, 
                        classId: widget.classData['_id']?.toString() ?? '',
                        iconColor: iconColor,
                        textColor: textColor,
                        className: className,
                      ),
                    ][_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom bar
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
                        _saveAnnouncements();
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

// === CÁC TAB KHÁC GIỮ NGUYÊN ===

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
                onEdit(index, controller.text.trim());
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

// ====================================================================
// WIDGET _StudentList SỬ DỤNG FutureBuilder VÀ API SERVICE THỰC TẾ
// ====================================================================
class _StudentList extends StatefulWidget {
  final String classId;
  final Color iconColor;
  final Color textColor;
  final String className;

  const _StudentList({
    Key? key, // Cần có key để truy cập state
    required this.classId,
    required this.iconColor,
    required this.textColor,
    required this.className,
  }) : super(key: key);

  @override
  State<_StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<_StudentList> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    // Bắt đầu gọi API khi widget được khởi tạo
    _studentsFuture = _fetchStudents();
  }

  // Hàm gọi API thực tế
  Future<List<Map<String, dynamic>>> _fetchStudents() async {
    if (widget.classId.isEmpty) {
      // Xử lý trường hợp không có ID lớp
      return []; 
    }
    // Gọi hàm fetchStudentsInClass từ ApiService
    // Đây là nơi kết nối với Backend thực tế
    return ApiService.fetchStudentsInClass(widget.classId);
  }

  // HÀM LÀM MỚI DANH SÁCH SINH VIÊN
  void _refreshStudents() {
    setState(() {
      _studentsFuture = _fetchStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Giáo viên (Giả định giáo viên là người đang xem)
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF6E48AA),
            child: Text("GV", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text("Giáo viên", style: TextStyle(fontWeight: FontWeight.bold, color: widget.textColor)),
          subtitle: Text("Bạn", style: TextStyle(color: widget.textColor.withOpacity(0.8))),
          trailing: IconButton(
            icon: Icon(Icons.refresh, color: widget.iconColor),
            onPressed: _refreshStudents,
          ),
        ),
        const Divider(height: 1),

        // Danh sách sinh viên
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _studentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Đang tải
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: widget.iconColor),
                      const SizedBox(height: 16),
                      Text("Đang tải danh sách học viên...", style: TextStyle(color: widget.textColor.withOpacity(0.8))),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                // Xảy ra lỗi (ví dụ: lỗi kết nối, lỗi server 401/404)
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 80, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text('Lỗi tải dữ liệu: ${snapshot.error}', 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade400, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Vui lòng kiểm tra kết nối mạng và token xác thực.', 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: widget.textColor.withOpacity(0.7))),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: Icon(Icons.refresh, color: widget.iconColor),
                          label: Text("Thử lại", style: TextStyle(color: widget.iconColor, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: widget.iconColor, width: 1.5)),
                          onPressed: _refreshStudents,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final students = snapshot.data ?? [];

              if (students.isEmpty) {
                // Không có sinh viên
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt_outlined, size: 110, color: widget.iconColor.withOpacity(0.8)),
                      const SizedBox(height: 32),
                      Text("Lớp ${widget.className} chưa có học viên nào",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.textColor), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: Icon(Icons.person_add, color: widget.iconColor),
                        label: Text("Mời học viên", style: TextStyle(color: widget.iconColor, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: widget.iconColor, width: 1.5)),
                        onPressed: () {
                          // Thêm điều hướng tới InviteStudentScreen ở đây nếu người dùng nhấn nút này
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InviteStudentScreen(
                                classId: widget.classId,
                                className: widget.className,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }

              // Hiển thị danh sách sinh viên
              return ListView.separated(
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final studentData = students[index];
                  final studentName = studentData['name']?.toString() ?? "Không tên";
                  final studentEmail = studentData['email']?.toString() ?? "";
                  final studentMssv = studentData['mssv']?.toString() ?? "Chưa rõ";

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: widget.iconColor.withOpacity(0.6),
                      child: Text(
                        // Lấy ký tự đầu tiên của tên
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : "?",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(studentName, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w500)),
                    subtitle: Text('MSSV: $studentMssv', style: TextStyle(color: widget.textColor.withOpacity(0.7))),
                    trailing: Text(studentEmail, style: TextStyle(color: widget.textColor.withOpacity(0.7))),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


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