// lib/instructor_dashboard.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'screens/create_class_screen.dart';
import 'instructor_drawer.dart';
import 'services/api_service.dart'; // ⭐️ Import ApiService

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  // ⭐️ Danh sách lớp học từ API. Dùng Map<String, dynamic> để linh hoạt với dữ liệu server (có _id, createdAt...)
  List<Map<String, dynamic>> classes = []; 
  bool _isLoading = true; // ⭐️ Trạng thái tải dữ liệu ban đầu
  String? _error; // ⭐️ Biến lưu lỗi nếu có

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
    
    // ⭐️ GỌI API KHI KHỞI TẠO MÀN HÌNH
    _loadClasses(); 
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  // ⭐️ HÀM MỚI: TẢI DANH SÁCH LỚP HỌC TỪ API
  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final fetchedClasses = await ApiService.fetchAllClasses();
      if (mounted) {
        setState(() {
          // Ép kiểu List<Map<String, dynamic>>
          classes = fetchedClasses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst("Exception: ", "Lỗi: ");
          _isLoading = false;
        });
      }
    }
  }

  // ⭐️ HÀM MỚI: XÓA LỚP HỌC QUA API
  Future<void> _deleteClass(String classId, String className) async {
    // Đóng dialog xác nhận ngay lập tức
    Navigator.of(context).pop(); 

    // Hiển thị thông báo đang xử lý
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Đang xóa lớp '$className'...", style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6E48AA),
        duration: const Duration(seconds: 5),
      ),
    );

    try {
      await ApiService.deleteClass(classId);

      // Xóa thành công, cập nhật UI:
      if (mounted) {
        setState(() {
          // Tìm và xóa lớp học theo ID từ danh sách cục bộ
          classes.removeWhere((cls) => cls['_id'] == classId);
        });
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã xóa lớp '$className' thành công!", style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Xử lý lỗi và hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "Lỗi xóa lớp: ")),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }


  // ⭐️ SỬA LỖI: Cập nhật lớp học mới được tạo. Dữ liệu này là Map<String, dynamic> từ API
  void _addNewClass(Map<String, dynamic> newClass) { 
    setState(() {
      classes.add(newClass);
    });
  }

  // ⭐️ HÀM HỖ TRỢ HIỂN THỊ DỮ LIỆU/LOADING/LỖI
  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6E48AA)),
            SizedBox(height: 20),
            Text("Đang tải danh sách lớp học...", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadClasses,
              icon: const Icon(Icons.refresh),
              label: const Text("Thử lại"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E48AA),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, color: Colors.grey.withOpacity(0.5), size: 80),
            const SizedBox(height: 20),
            const Text(
              "Bạn chưa tạo lớp học nào.", 
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              "Nhấn nút '+' để bắt đầu tạo lớp mới.", 
              style: TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.8)),
            ),
          ],
        ),
      );
    }

    // HIỂN THỊ DANH SÁCH LỚP HỌC
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        // Ép kiểu lớp học về Map<String, String> để sử dụng _buildClassCard cũ
        final cls = classes[index].map((key, value) => MapEntry(key, value.toString())); 
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _buildClassCard(cls, index),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Code AppBar và Drawer giữ nguyên)
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFF6E48AA),
                      child: Text(
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

      // ⭐️ BODY ĐÃ ĐƯỢC CẬP NHẬT ĐỂ HIỂN THỊ LOADING/ERROR/CONTENT
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
            child: Padding(
              padding: const EdgeInsets.only(top: 80), // Để tránh bị che bởi AppBar
              child: _buildBodyContent(), // ⭐️ Sử dụng hàm kiểm tra trạng thái
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6E48AA),
        elevation: 15,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        onPressed: () {
          // ⭐️ TRUYỀN HÀM CALLBACK ĐÃ SỬA LỖI
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateClassScreen(onClassCreated: _addNewClass)),
          );
        },
      ),
    );
  }

  // ⭐️ _buildClassCard phải nhận Map<String, String> vì đó là kiểu dữ liệu bạn đang sử dụng trong hàm này
  Widget _buildClassCard(Map<String, String> cls, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> backgrounds = [
      // ... (Giữ nguyên danh sách ảnh nền)
      'assets/images/banner1.jpg',
      'assets/images/banner2.jpg',
      'assets/images/banner3.jpg',
    ];
    // Chú ý: Bạn cần đảm bảo các file ảnh này tồn tại trong thư mục assets và đã khai báo trong pubspec.yaml
    final String bgImage = backgrounds[index % backgrounds.length];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 250,
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
                        color: isDark ? Colors.grey[900]! : Colors.white, 
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
                                    // ⭐️ GỌI HÀM XÓA QUA API THỰC TẾ
                                    onPressed: () {
                                      final String idToDelete = cls['_id'] ?? '';
                                      final String nameToDelete = cls['name'] ?? 'Lớp học không tên';
                                      
                                      if (idToDelete.isNotEmpty) {
                                        _deleteClass(idToDelete, nameToDelete); // Gọi hàm xóa API
                                      } else {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Lỗi: Không tìm thấy ID lớp học."),
                                            backgroundColor: Colors.orange,
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
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

  // Widget hỗ trợ hiển thị thông tin lớp (Giữ nguyên)
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