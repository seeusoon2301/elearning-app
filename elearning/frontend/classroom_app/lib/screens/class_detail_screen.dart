// lib/screens/class_detail_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../instructor_drawer.dart';
import './create_annoucement_screen.dart';
import './invite_student_screen.dart';
import '../services/api_service.dart'; 
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

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
  
  // ⭐️ THAY ĐỔI: Dữ liệu cho tab Stream (Lấy từ API)
  List<Map<String, dynamic>> _announcements = []; 
  // ⭐️ THÊM: Trạng thái loading riêng cho bảng tin
  bool _isAnnouncementsLoading = false; 
  
  // KEY DÙNG ĐỂ TRUY CẬP VÀO STATE CỦA WIDGET _StudentList
  final GlobalKey<_StudentListState> _studentListKey = GlobalKey<_StudentListState>();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
    
    // ⭐️ GỌI HÀM MỚI ĐỂ TẢI BẢNG TIN TỪ API
    _loadAnnouncementsFromApi();
  }

  // ⭐️ HÀM MỚI: Tải bảng tin từ API
  Future<void> _loadAnnouncementsFromApi() async {
    final classId = widget.classData['_id']?.toString() ?? '';
    if (classId.isEmpty) return;

    setState(() {
      _isAnnouncementsLoading = true;
    });

    try {
      // Gọi API
      final loadedAnnouncements = await ApiService.fetchAnnouncementsInClass(classId);
      
      if (mounted) {
        setState(() {
          // Lưu dữ liệu đã tải vào state
          _announcements = loadedAnnouncements;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải bảng tin: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnnouncementsLoading = false;
        });
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
    final classId = widget.classData['_id']?.toString() ?? ''; // Lấy ID
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
          // NÚT DẤU CỘNG MỜI HỌC VIÊN
          if (_selectedIndex == 2) 
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                // Icon dấu cộng theo yêu cầu (Icons.add)
                icon: const Icon(Icons.add, color: Colors.white, size: 30),
                tooltip: 'Mời học viên mới',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InviteStudentScreen(
                        classId: classId,
                        className: className,
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
                      // ⭐️ StreamTab mới sử dụng data từ API
                      StreamTab(
                        key: ValueKey(_announcements.length),
                        announcements: _announcements,
                        isLoading: _isAnnouncementsLoading,
                        onRefresh: _loadAnnouncementsFromApi,
                      ),
                      AssignmentsTab(
                        iconColor: iconColor,
                        textColor: textColor,
                        hintColor: hintColor,
                        classId: classId,  // DÙNG BIẾN classId ĐÃ CÓ SẴN TRONG STATE!
                      ),
                      // SỬ DỤNG WIDGET _StudentList
                      _StudentList(
                        key: _studentListKey, 
                        classId: classId,
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

      // ⭐️ CẬP NHẬT FLOATING ACTION BUTTON
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              heroTag: 'detailFab',
              backgroundColor: const Color(0xFF6E48AA),
              elevation: 15,
              child: const Icon(Icons.add, size: 32, color: Colors.white),
              onPressed: () async {
                // 1. Điều hướng đến màn hình tạo thông báo
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateAnnouncementScreen(
                      classId: classId, // Truyền ID lớp học
                    ),
                  ),
                );

                // 2. KIỂM TRA KẾT QUẢ VÀ TẢI LẠI
                if (result == true) {
                  // Tải lại dữ liệu từ server
                  await _loadAnnouncementsFromApi(); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đăng thông báo thành công!"),
                      backgroundColor: Color(0xFF6E48AA),
                    ),
                  );
                }
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

// ⭐️ WIDGET StreamTab ĐÃ ĐƯỢC CẬP NHẬT ĐỂ NHẬN DỮ LIỆU TỪ API
class StreamTab extends StatelessWidget {
  final List<Map<String, dynamic>> announcements;
  final bool isLoading;
  final VoidCallback onRefresh;

  const StreamTab({
    Key? key,
    required this.announcements,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading && announcements.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: const Color(0xFF6E48AA)),
              const SizedBox(height: 16),
              const Text("Đang tải bảng tin...", style: TextStyle(fontSize: 18)),
            ],
          ),
        );
    }
    
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

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          final content = announcement['content']?.toString() ?? "Nội dung trống";
          final createdAtString = announcement['createdAt']?.toString() ?? announcement['updatedAt']?.toString();
          final createdAt = createdAtString != null && createdAtString.isNotEmpty
                             ? DateTime.tryParse(createdAtString) ?? DateTime.now()
                             : DateTime.now();
          
          final timeAgo = _formatTimeAgo(createdAt);

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
                  Text(timeAgo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(content),
              ),
            ),
          );
        },
      ),
    );
  }

  // Hàm format thời gian đơn giản
  String _formatTimeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inMinutes < 1) return "vừa xong";
    if (duration.inMinutes < 60) return "${duration.inMinutes} phút trước";
    if (duration.inHours < 24) return "${duration.inHours} giờ trước";
    return "${date.day}/${date.month}/${date.year}";
  }
}

class AssignmentsTab extends StatefulWidget {
  final Color iconColor, textColor, hintColor;
  final String classId;
  const AssignmentsTab({
    Key? key,
    required this.iconColor,
    required this.textColor,
    required this.hintColor,
    required this.classId,
  }) : super(key: key);

  @override
  State<AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<AssignmentsTab> {
  // ⭐️ STATIC STORAGE: Lưu trữ bài tập theo Class ID ⭐️
  // Dữ liệu sẽ mất khi ứng dụng bị đóng hoàn toàn (Kill Process / flutter run lại)
  static final Map<String, List<Map<String, dynamic>>> _localAssignmentsStorage = {};

  final TextEditingController _contentController = TextEditingController(); 
  
  List<Map<String, dynamic>> assignments = []; 
  bool isLoadingAssignments = true; 

  // HÀM TẢI DỮ LIỆU TỪ STATIC STORAGE
  Future<void> _loadAssignments() async {
    // 1. Lấy dữ liệu bài tập đã lưu trữ cho classId hiện tại.
    final currentAssignments = _localAssignmentsStorage[widget.classId] ?? [];

    if (mounted) {
      setState(() {
        assignments = currentAssignments; // Gán dữ liệu từ static map
        isLoadingAssignments = false; 
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAssignments(); 
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // HÀM HIỂN THỊ DIALOG TẠO BÀI TẬP
  void _showAssignmentDialog() {
    _contentController.clear(); 

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tạo Bài Tập Mới"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề (Nội dung bài tập)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Trì hoãn để tránh lỗi TapGestureRecognizer
                    Future.delayed(Duration.zero, () {
                      Navigator.of(context).pop(); 
                      _processFileUpload(_contentController.text); 
                    });
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Đính kèm file (.pdf/.csv)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E48AA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Future.delayed(Duration.zero, () {
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  // HÀM XỬ LÝ UPLOAD VÀ LƯU TRỮ (VÀO STATIC MAP)
  Future<void> _processFileUpload(String assignmentTitle) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'csv'],
    );

    if (result == null || result.files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chưa có tệp nào được chọn."), backgroundColor: Colors.grey),
        );
      }
      return;
    }

    final file = result.files.single;
    final fileName = file.name;
    final title = assignmentTitle.isEmpty ? fileName.split('.').first : assignmentTitle; 

    // 1. TẠO OBJECT BÀI TẬP MỚI (MOCK)
    final newAssignment = {
      '_id': DateTime.now().millisecondsSinceEpoch.toString(), 
      'fileName': fileName, 
      'title': title, 
      'createdAt': DateTime.now().toIso8601String(),
    };

    // 2. CẬP NHẬT LOCAL STATE và STATIC STORAGE
    if (mounted) {
      setState(() {
        // Thêm vào danh sách cục bộ
        assignments.insert(0, newAssignment);
        
        // ⭐️ LƯU VÀO STATIC STORAGE cho classId hiện tại ⭐️
        _localAssignmentsStorage[widget.classId] = assignments;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã tạo bài tập: $title. (LOCAL MOCK)"), 
          backgroundColor: const Color(0xFF6E48AA)
        ),
      );
    }
  }

  // ⭐️ HÀM XỬ LÝ XÓA BÀI TẬP ⭐️
  void _deleteAssignment(int index) {
    if (mounted) {
      setState(() {
        assignments.removeAt(index);
        // Cập nhật Static Map
        _localAssignmentsStorage[widget.classId] = assignments;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa bài tập thành công!"), backgroundColor: Colors.red),
      );
    }
  }

  // ⭐️ HÀM XỬ LÝ CHỈNH SỬA TIÊU ĐỀ ⭐️
  void _editAssignment(int index, String newTitle) {
    if (mounted) {
      setState(() {
        // Cập nhật tiêu đề trong danh sách cục bộ
        final finalTitle = newTitle.trim().isEmpty ? assignments[index]['fileName'].split('.').first : newTitle;
        assignments[index]['title'] = finalTitle;
        
        // Cập nhật Static Map
        _localAssignmentsStorage[widget.classId] = assignments;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã cập nhật bài tập thành: ${assignments[index]['title']}"), backgroundColor: const Color(0xFF6E48AA)),
      );
    }
  }

  // HÀM HIỂN THỊ DIALOG CHỈNH SỬA
  void _showEditDialog(Map<String, dynamic> assignment, int index) {
    final editController = TextEditingController(text: assignment['title']);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chỉnh sửa Tiêu đề"),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề mới',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 4,
          ),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Lưu'),
              onPressed: () {
                Navigator.of(context).pop();
                _editAssignment(index, editController.text);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Danh sách bài tập
        isLoadingAssignments
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6E48AA)))
            : assignments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_rounded, size: 110, color: widget.iconColor),
                        const SizedBox(height: 32),
                        Text("Chưa có bài tập", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: widget.textColor)),
                        const SizedBox(height: 16),
                        Text("Bấm nút + để đăng file PDF hoặc CSV", style: TextStyle(fontSize: 16, color: widget.hintColor)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = assignments[index];
                      final fileName = assignment['fileName'] ?? 'assignment.pdf';
                      final title = assignment['title'] ?? fileName.split('.').first;
                      final fileExtension = fileName.split('.').last.toLowerCase();
                      
                      IconData leadingIcon;
                      Color iconColor;

                      if (fileExtension == 'pdf') {
                        leadingIcon = Icons.picture_as_pdf;
                        iconColor = Colors.red;
                      } else if (fileExtension == 'csv') {
                        leadingIcon = Icons.grid_on_rounded;
                        iconColor = Colors.green;
                      } else {
                        leadingIcon = Icons.file_present;
                        iconColor = Colors.grey;
                      }


                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: iconColor,
                            child: Icon(leadingIcon, color: Colors.white),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("File: $fileName"),
                          // ⭐️ NÚT CHỈNH SỬA VÀ XÓA ⭐️
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditDialog(assignment, index);
                              } else if (value == 'delete') {
                                _deleteAssignment(index);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa tiêu đề')),
                              const PopupMenuItem(
                                value: 'delete', 
                                child: Text('Xóa bài tập', style: TextStyle(color: Colors.red))
                              ),
                            ],
                            icon: const Icon(Icons.more_vert),
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Đang tải: $fileName")),
                            );
                          },
                        ),
                      );
                    },
                  ),

        // Nút upload
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'uploadFab',
            backgroundColor: const Color(0xFF6E48AA),
            child: const Icon(Icons.add, size: 32, color: Colors.white), 
            onPressed: _showAssignmentDialog,
          ),
        ),
      ],
    );
  }
}

// ====================================================================
// WIDGET _StudentList (GIỮ NGUYÊN)
// ====================================================================
class _StudentList extends StatefulWidget {
  final String classId;
  final Color iconColor;
  final Color textColor;
  final String className;

  const _StudentList({
    Key? key,
    required this.classId,
    required this.iconColor,
    required this.textColor,
    required this.className,
  }) : super(key: key);

  @override
  State<_StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<_StudentList> {
  //late Future<List<Map<String, dynamic>>> _studentsFuture;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    //_studentsFuture = _fetchStudents();
    _loadStudentsFromApi();
  }

  Future<void> _loadStudentsFromApi() async {
    // Không cần load nếu classId rỗng
    if (widget.classId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final loadedStudents = await ApiService.fetchStudentsInClass(widget.classId);
      if (mounted) {
        setState(() {
          _students = loadedStudents;
        });
        print('DEBUG (Students UI): Cập nhật UI với ${_students.length} sinh viên.');
      }
    } catch (e) {
      if (mounted) {
        // Hiện lỗi nếu có vấn đề về token/mạng
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách sinh viên: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _refreshStudents() {
    _loadStudentsFromApi();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Giáo viên
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
            future: _students.isEmpty ? ApiService.fetchStudentsInClass(widget.classId) : Future.value(_students),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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