import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:classroom_app/screens/instructor_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ⭐️ Thêm import provider
import 'package:shared_preferences/shared_preferences.dart';
import 'create_class_screen.dart';
import '../instructor_drawer.dart';
import '../services/api_service.dart'; 
import '../providers/semester_provider.dart'; // ⭐️ Thêm import SemesterProvider
import 'class_detail_screen.dart';
import 'edit_class_screen.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key}); 

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  List<Map<String, dynamic>> classes = []; 
  bool _isLoading = false; // ⭐️ Đặt là false vì load ban đầu được gọi trong didChangeDependencies
  String? _error; 

  // ⭐️ Theo dõi ID học kỳ hiện tại để tránh tải lại dữ liệu không cần thiết
  String? _currentSemesterId; 

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
    
    // ❌ KHÔNG GỌI _loadClasses() ở đây. Sẽ gọi trong didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Lấy thông tin học kỳ hiện tại mà không cần lắng nghe (listen: true sẽ được dùng trong build)
    final semesterProvider = Provider.of<SemesterProvider>(context);
    final newSemesterId = semesterProvider.current?.id;

    // Chỉ tải lớp học nếu ID học kỳ đã thay đổi (và không phải null)
    if (newSemesterId != null && newSemesterId != _currentSemesterId) {
      _currentSemesterId = newSemesterId;
      _loadClasses(newSemesterId); // ⭐️ Gọi hàm tải với ID học kỳ mới
    } else if (newSemesterId == null && _currentSemesterId != null) {
      // Trường hợp học kỳ hiện tại bị mất (ví dụ: bị xóa)
      setState(() {
        _currentSemesterId = null;
        classes = [];
        _isLoading = false;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  // ⭐️ CẬP NHẬT HÀM TẢI LỚP HỌC: NHẬN VÀO semesterId
  Future<void> _loadClasses(String semesterId) async {
    setState(() {
      _isLoading = true;
      _error = null;
      // Dọn dẹp danh sách cũ trong khi tải
      classes = []; 
    });

    try {
      // ⭐️ GỌI API THEO ID HỌC KỲ
      final fetchedClasses = await ApiService.fetchClassesBySemesterId(semesterId);
      if (mounted) {
        setState(() {
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

  void _updateExistingClass(Map<String, dynamic> updatedClass, int index) {
    setState(() {
      // Thay thế lớp học cũ bằng dữ liệu mới tại đúng vị trí
      classes[index] = updatedClass; 
    });
    // Hiển thị thông báo (tùy chọn)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cập nhật lớp học thành công (Frontend)!"),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ⭐️ HÀM XÓA VẪN DÙNG classId, không cần thay đổi
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


  // SỬA LỖI: Cập nhật lớp học mới được tạo. Lớp học mới này phải được thêm vào danh sách nếu nó thuộc học kỳ hiện tại
  void _addNewClass(Map<String, dynamic> newClass) { 
    // Giả định backend trả về luôn lớp học đã được gán semesterId
    final classSemesterId = newClass['semesterId'] ?? newClass['semester_id']; 
    
    // Chỉ thêm vào danh sách nếu lớp học này thuộc học kỳ đang hiển thị
    if (classSemesterId.toString() == _currentSemesterId) { 
        setState(() {
          classes.add(newClass);
        });
    }
    // Nếu không thuộc, chỉ thông báo (tùy chọn) hoặc không làm gì.
  }

  // ⭐️ CẬP NHẬT HÀM HIỂN THỊ NỘI DUNG: Xử lý trường hợp chưa chọn học kỳ
  Widget _buildBodyContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final errorColor = isDark ? Colors.redAccent.shade100 : Colors.redAccent;
    
    final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
    final currentSemester = semesterProvider.current;

    // ⭐️ TRƯỜNG HỢP 1: CHƯA CHỌN HỌC KỲ
    if (currentSemester == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 80,
                color: hintColor.withOpacity(0.6),
              ),
              const SizedBox(height: 20),
              Text(
                "Chưa chọn Học kỳ",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Vui lòng chọn hoặc tạo một Học kỳ từ thanh menu bên trái (Drawer) để xem danh sách lớp học.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: hintColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // TRƯỜNG HỢP 2: ĐANG TẢI
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: const Color(0xFF6E48AA),
              strokeWidth: 5,
            ),
            const SizedBox(height: 24),
            Text(
              "Đang tải lớp học cho ${currentSemester.name}...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Vui lòng chờ một chút nhé",
              style: TextStyle(
                fontSize: 15,
                color: hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // TRƯỜNG HỢP 3: LỖI
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.signal_wifi_connected_no_internet_4_rounded,
                size: 80,
                color: errorColor,
              ),
              const SizedBox(height: 20),
              Text(
                "Không thể tải dữ liệu",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: errorColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                // ⭐️ GỌI HÀM THỬ LẠI VỚI ID HỌC KỲ HIỆN TẠI
                onPressed: () => _loadClasses(_currentSemesterId!),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Thử lại"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E48AA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // TRƯỜNG HỢP 4: DANH SÁCH RỖNG
    if (classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 100,
                color: hintColor.withOpacity(0.6),
              ),
              const SizedBox(height: 28),
              Text(
                "Chưa có lớp học nào",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Nhấn vào nút để tạo lớp học đầu tiên cho học kỳ '${currentSemester.name}'",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: hintColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateClassScreen(onClassCreated: _addNewClass),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF6E48AA),
                icon: const Icon(Icons.add, size: 28),
                label: const Text(
                  "Tạo lớp học mới",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // TRƯỜNG HỢP 5: HIỂN THỊ DANH SÁCH LỚP HỌC
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final cls = classes[index];
        final Map<String, String> classMap = cls.map((key, value) => MapEntry(key, value.toString()));
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _buildClassCard(classMap, index),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ⭐️ Lắng nghe Học kỳ hiện tại để xây dựng AppBar
    final semesterProvider = Provider.of<SemesterProvider>(context);
    final currentSemesterName = semesterProvider.current?.name ?? "Chưa chọn Học kỳ"; 
    
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
            // ⭐️ HIỂN THỊ TÊN HỌC KỲ HIỆN TẠI
            Text(
              currentSemesterName, 
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

      drawer: const InstructorDrawer(),

      body: Stack(
        children: [
          // Nền Nebula Wave – giữ nguyên
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
                SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight + 40,
                ),
                Expanded(
                  child: _buildBodyContent(), // ⭐️ Gọi hàm hiển thị nội dung đã được cập nhật
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: 'classListFab',
        backgroundColor: const Color(0xFF6E48AA),
        elevation: 15,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        onPressed: () {
          // ⭐️ TRUYỀN HÀM CALLBACK
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateClassScreen(onClassCreated: _addNewClass)),
          );
        },
      ),
    );
  }

  // ⭐️ _buildClassCard giữ nguyên logic hiển thị...
  Widget _buildClassCard(Map<String, String> cls, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> backgrounds = [
      'assets/images/banner1.jpg',
      'assets/images/banner2.jpg',
      'assets/images/banner3.jpg',
    ];
    final String bgImage = backgrounds[index % backgrounds.length];

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // CHUYỂN SANG MÀN HÌNH CHI TIẾT LỚP – CÓ 3 TAB
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClassDetailScreen(
              classData: classes[index], // Truyền nguyên object gốc (có _id, semesterId,...)
            ),
          ),
        );
      },
      child: Card(
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
                          if ((cls['instructor'] ?? '').isNotEmpty)
                            _infoRow(Icons.segment, "Tên giảng viên: ${cls['instructor']}"),
                          if ((cls['room'] ?? '').isNotEmpty)
                            _infoRow(Icons.room, "Phòng: ${cls['room']}"),
                          if ((cls['subject'] ?? '').isNotEmpty)
                            _infoRow(Icons.book, "Chủ đề: ${cls['subject']}"),
                        ],
                      ),

                      // lib/screens/class_list_screen.dart
                      // (Trong hàm _buildClassCard, giả định cls và index có sẵn)
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
                          // ⭐️ CẬP NHẬT: THÊM 'async' VÀ LOGIC CHỈNH SỬA
                          onSelected: (value) async {
                            if (value == 'edit') {
                              // --- LOGIC CHỈNH SỬA LỚP HỌC (FRONTEND) ---
                              // 1. Điều hướng đến màn hình chỉnh sửa
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditClassScreen(
                                    // Truyền DỮ LIỆU GỐC của lớp học vào màn hình chỉnh sửa
                                    classData: cls,
                                  ),
                                ),
                              );

                              // 2. Xử lý kết quả trả về sau khi chỉnh sửa
                              if (result != null && result is Map<String, dynamic>) {
                                // Bạn cần có hàm này trong _ClassListScreenState
                                _updateExistingClass(result, index); 
                              }
                            } 
                            
                            // --- LOGIC XÓA LỚP HỌC (GIỮ NGUYÊN) ---
                            else if (value == 'delete') {
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
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () {
                                        final String idToDelete = cls['_id'] ?? '';
                                        final String nameToDelete = cls['name'] ?? 'Lớp học';
                                        if (idToDelete.isNotEmpty) {
                                          _deleteClass(idToDelete, nameToDelete); // Giữ nguyên hàm của bạn
                                        }
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text("Xóa", style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          
                          // ⭐️ CẬP NHẬT: THÊM PopupMenuItem cho "Chỉnh sửa"
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit', 
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, color: Color(0xFF6E48AA)), // Màu tím chủ đạo
                                  SizedBox(width: 12), 
                                  Text("Chỉnh sửa lớp học")
                                ]
                              )
                            ),
                            const PopupMenuItem(
                              value: 'delete', 
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red), 
                                  SizedBox(width: 12), 
                                  Text("Xóa lớp học")
                                ]
                              )
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