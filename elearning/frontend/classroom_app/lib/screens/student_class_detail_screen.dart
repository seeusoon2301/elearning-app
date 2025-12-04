// lib/screens/student_class_detail_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../student_drawer.dart'; // ĐÃ ĐỔI THÀNH STUDENT DRAWER
import '../services/api_service.dart';
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _members = [];
  String? _loggedInStudentId;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);

    _loadAnnouncements();
    _loadMembers();
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      // Nếu thời gian cách đây ít phút, hiển thị 'Vừa xong'
      if (DateTime.now().difference(dateTime).inMinutes < 5) {
        return 'Vừa xong';
      }
      // Định dạng ngày giờ cụ thể (ví dụ: 10:30 AM, 04/12/2025)
      return DateFormat('hh:mm a, dd/MM/yyyy').format(dateTime); 
    } catch (e) {
      //print('Lỗi định dạng thời gian: $e');
      return 'Không rõ thời gian';
    }
  }

  Future<void> _loadAnnouncements() async {
    final classId = widget.classData['_id']; 
    if (classId == null) {
      if(mounted) {
        setState(() {
          _isLoading = false;
          _error = "Không có ID lớp học.";
        });
      }
      return;
    }

    try {
      // 2. Gọi API để lấy danh sách thông báo (List<Map<String, dynamic>>)
      final announcementsMapList = await ApiService.fetchAnnouncementsInClass(classId);

      // 3. Chuyển đổi List<Map> thành List<String> (chỉ lấy nội dung thông báo)
      final announcementsContent = announcementsMapList.map<String>((announcement) {
        // Giả định backend trả về trường 'content' cho nội dung thông báo
        return announcement['content'] ?? 'Thông báo không có nội dung.'; 
      }).toList();

      if (mounted) {
        setState(() {
          _announcements = announcementsMapList;
          _isLoading = false;
          _error = null;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Hiển thị thông báo lỗi chi tiết hơn nếu có
          _error = "Lỗi tải thông báo: $e"; 
          //_announcements = ["Lỗi tải thông báo: Vui lòng kiểm tra kết nối."]; 
        });
      }
      print('Error loading announcements: $e');
    }
  }

  Future<void> _loadMembers() async {
    // 1. Lấy classId và ID người dùng
    final classId = widget.classData['_id'];
    if (classId == null) return;
    
    final userId = await ApiService.getLoggedInStudentId();

    try {
      // 2. Gọi API lấy danh sách sinh viên
      final students = await ApiService.fetchStudentsInClass(classId);

      if (mounted) {
        setState(() {
          _members = students;
          _loggedInStudentId = userId;
          // Dùng chung _isLoading cho cả màn hình chi tiết
          // _isLoading = false; // Nếu bạn muốn tách loading, hãy thêm biến riêng
        });
      }
    } catch (e) {
      if (mounted) {
        print('Lỗi tải danh sách thành viên: $e');
        // Có thể hiện error message trên tab Mọi người nếu cần
      }
    }
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
                      if (_isLoading) 
                        const Center(child: CircularProgressIndicator())
                      else if (_error != null)
                        Center(
                          key: const ValueKey('ErrorTab'),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                          )
                        )
                      else
                        _StreamTab(
                          key: const ValueKey('StreamTab'), 
                          announcements: _announcements, 
                          formatTime: _formatTime, // <-- Truyền hàm vào đây
                        ),
                      const _AssignmentsTab(),
                      _PeopleTab(
          key: const ValueKey('_PeopleTab'),
          instructorName: widget.classData['instructor'] ?? 'Giảng viên', 
          students: _members,
          loggedInStudentId: _loggedInStudentId,
          isLoading: _isLoading, // Có thể dùng chung
        ),
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
  // ⭐️ NHẬN LIST OF MAP thay vì List<String>
  final List<Map<String, dynamic>> announcements;
  // ⭐️ NHẬN HÀM ĐỊNH DẠNG THỜI GIAN
  final String Function(String isoString) formatTime; 

  const _StreamTab({
    Key? key, 
    required this.announcements,
    required this.formatTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có thông báo nào được đăng.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        
        // ⭐️ TRÍCH XUẤT THÔNG TIN: content và createdAt
        final content = announcement['content'] ?? 'Thông báo không có nội dung.';
        final createdAt = announcement['createdAt'] as String? ?? '2025-01-01T00:00:00.000Z'; // Dùng giá trị mặc định nếu không có

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⭐️ HIỂN THỊ THỜI GIAN THỰC TỪ CREATEAT
                Text(
                  formatTime(createdAt), // SỬ DỤNG HÀM ĐỊNH DẠNG
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thông báo mới',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(content),
              ],
            ),
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
  // ⭐️ THÊM TRƯỜNG DỮ LIỆU
  final String instructorName;
  final List<Map<String, dynamic>> students;
  final String? loggedInStudentId;
  final bool isLoading;

  const _PeopleTab({
    Key? key,
    required this.instructorName,
    required this.students,
    this.loggedInStudentId,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sắp xếp danh sách sinh viên theo tên (A-Z)
    final sortedStudents = List<Map<String, dynamic>>.from(students)
      ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    // Chuyển đổi danh sách sinh viên Map sang List<Widget>
    final studentWidgets = sortedStudents.map((student) {
      // ⭐️ ĐẢM BẢO CHUYỂN ID THÀNH CHUỖI ĐỂ SO SÁNH CHÍNH XÁC
      final studentIdFromApi = student['_id']?.toString(); 
      final studentName = student['name'] ?? 'Sinh viên không tên';
      
      // LOGIC THÊM CHÚ THÍCH (Bạn)
      final isCurrentUser = studentIdFromApi != null && 
                            loggedInStudentId != null && // Kiểm tra cả hai đều có giá trị
                            studentIdFromApi == loggedInStudentId; // So sánh hai chuỗi
      
      final displayName = isCurrentUser 
          ? '$studentName (Bạn)' 
          : studentName;
      
      final firstLetter = studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';

      return ListTile(
        leading: CircleAvatar(child: Text(firstLetter)),
        title: Text(displayName,
            // ⭐️ Thêm kiểu chữ đậm cho người dùng hiện tại (Tùy chọn)
            style: isCurrentUser ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue) : null, 
        ), 
        subtitle: Text(student['mssv'] ?? student['email'] ?? 'Sinh viên'), 
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Giảng viên
        ListTile(
          title: Text(
            'Giảng viên',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: CircleAvatar(
            child: Text(instructorName.isNotEmpty ? instructorName[0] : 'G'),
            backgroundColor: Colors.purple.shade100,
          ),
          title: Text(instructorName),
          subtitle: const Text('Giảng viên'),
        ),
        
        const Divider(height: 30),

        // 2. Sinh viên
        ListTile(
          title: Text(
            'Sinh viên (${students.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        
        // Hiển thị danh sách sinh viên đã được load từ API
        ...studentWidgets,
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