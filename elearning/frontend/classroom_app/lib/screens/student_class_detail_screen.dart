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
  String? _loggedInStudentName; // ⭐️ THÊM TRƯỜNG NÀY

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);

    _loadStudentInfo();
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

  // ⭐️ HÀM MỚI: Tải tên người dùng
  Future<void> _loadStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        // Giả sử bạn lưu tên sinh viên vào 'studentName' trong SharedPreferences khi login
        _loggedInStudentName = prefs.getString('studentName') ?? 'Bạn'; 
      });
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
                          loggedInStudentName: _loggedInStudentName ?? 'Bạn', // ⭐️ TRUYỀN TÊN
                        ),
                      _AssignmentsTab(
    classId: widget.classData['_id'],
),
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
  final List<Map<String, dynamic>> announcements;
  final String Function(String isoString) formatTime; 
  final String loggedInStudentName; // ⭐️ ĐÃ CÓ: Tên sinh viên đăng nhập

  const _StreamTab({
    Key? key, 
    required this.announcements,
    required this.formatTime,
    required this.loggedInStudentName,
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

    // ⭐️ BỎ CÁC ĐỊNH NGHĨA MÀU SẮC DƯ THỪA (vì _AnnouncementItem sẽ tự lo)
    
    return ListView.builder(
      // ⭐️ CẬP NHẬT: Chỉ giữ padding ngang cho ListView
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), 
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        
        // ⭐️ SỬ DỤNG WIDGET MỚI _AnnouncementItem
        return _AnnouncementItem(
          // Key là bắt buộc để Flutter nhận diện State của từng Item
          key: ValueKey(announcement['_id'] ?? index), 
          announcement: announcement,
          formatTime: formatTime,
          loggedInStudentName: loggedInStudentName,
        );
      },
    );
  }
}

// ==================== WIDGET THÔNG BÁO KÈM COMMENT ====================
/// ⭐️ LƯU TRỮ COMMENT TẠM THỜI TOÀN CỤC (GLOBAL STATIC IN-MEMORY STORE)
/// Dữ liệu sẽ được giữ lại khi chuyển tab, nhưng mất khi ứng dụng thoát/restart.
/// Key: Announcement ID (String)
class GlobalCommentStore {
  static final Map<String, List<Map<String, dynamic>>> _comments = {};

  static List<Map<String, dynamic>> getComments(String announcementId) {
    // Trả về danh sách comments cho ID, nếu không có thì trả về danh sách rỗng
    return _comments[announcementId] ?? [];
  }

  static void setComments(String announcementId, List<Map<String, dynamic>> comments) {
    // Lưu danh sách comments mới
    _comments[announcementId] = comments;
  }
}

class _AnnouncementItem extends StatefulWidget {
  final Map<String, dynamic> announcement;
  final String Function(String isoString) formatTime;
  final String loggedInStudentName; 

  const _AnnouncementItem({
    Key? key,
    required this.announcement,
    required this.formatTime,
    required this.loggedInStudentName,
  }) : super(key: key);

  @override
  State<_AnnouncementItem> createState() => _AnnouncementItemState();
}

class _AnnouncementItemState extends State<_AnnouncementItem> {
  List<Map<String, dynamic>> _localComments = []; 
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments(); 
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ⭐️ TẢI DỮ LIỆU TỪ GLOBAL MAP
  void _loadComments() {
    final String announcementId = widget.announcement['_id'] ?? 'default_id';
    
    // Tải dữ liệu từ Global Store
    final List<Map<String, dynamic>> storedComments = GlobalCommentStore.getComments(announcementId);
    
    // Sử dụng List.from() để tạo bản sao, tránh thay đổi trực tiếp Global Store khi gọi setState
    _localComments = List<Map<String, dynamic>>.from(storedComments);
  }

  // ⭐️ LƯU DỮ LIỆU VÀO GLOBAL MAP
  void _saveComments() {
    final String announcementId = widget.announcement['_id'] ?? 'default_id';
    // Lưu danh sách hiện tại (_localComments) vào Global Store
    GlobalCommentStore.setComments(announcementId, _localComments);
  }

  // Cập nhật HÀM XỬ LÝ GỬI COMMENT
  void _postComment() {
    final commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      setState(() {
        _localComments.add({
          'author': widget.loggedInStudentName,
          'content': commentText,
          'time': DateTime.now().toIso8601String(),
        });
      });
      _saveComments(); // ⭐️ LƯU COMMENT MỚI VÀO GLOBAL STORE
      _commentController.clear();
    }
  }
  
  // ⭐️ HÀM BUILD WIDGET COMMENT INPUT (UI MỚI)
  Widget _buildCommentInput(bool isDark, Color primaryColor, Color cardColor) {
    return Container(
      // Padding nhẹ nhàng hơn, dùng Row crossAxisAlignment.end để căn dưới
      padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 10.0, bottom: 10.0), 
      decoration: BoxDecoration(
        color: cardColor, 
        // Đảm bảo góc dưới bo tròn, đồng bộ với Card
        borderRadius: BorderRadius.vertical(top: Radius.zero, bottom: const Radius.circular(16)), 
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, 
        children: [
          CircleAvatar(
            backgroundColor: primaryColor,
            radius: 16, // ⭐️ Giảm kích thước Avatar
            child: Text(
              widget.loggedInStudentName.isNotEmpty ? widget.loggedInStudentName[0].toUpperCase() : 'B',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _commentController,
              keyboardType: TextInputType.multiline,
              maxLines: null, // Cho phép nhiều dòng
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Viết bình luận...',
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25), // ⭐️ Bo góc mềm mại
                  borderSide: BorderSide.none, // ⭐️ Bỏ đường viền
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100], 
              ),
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send_rounded, color: primaryColor, size: 24),
            onPressed: _postComment,
          ),
        ],
      ),
    );
  }
  
  // HÀM BUILD DANH SÁCH COMMENTS (Có thể giữ nguyên hoặc điều chỉnh nhẹ)
  Widget _buildCommentList(bool isDark, Color primaryColor) {
    // Giữ nguyên logic UI comment list từ phiên bản trước
    // ... (Your previous _buildCommentList implementation goes here) ...
    // *Lưu ý: Bạn có thể muốn kiểm tra lại Padding ở đây nếu thấy quá trống.*
    
    // Dưới đây là đoạn code _buildCommentList từ lần trước, có điều chỉnh nhẹ:
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 0, right: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 32.0, right: 16.0, bottom: 0),
            child: Text(
              'Bình luận (${_localComments.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: 14,
              ),
            ),
          ),
          
          ListView.builder(
            reverse: true, 
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(), 
            itemCount: _localComments.length,
            itemBuilder: (context, index) {
              final comment = _localComments[index];
              final String author = comment['author'] ?? 'Người dùng';
              final String content = comment['content'] ?? '';
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: primaryColor.withOpacity(0.5),
                      child: Text(
                        author.isNotEmpty ? author[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              author,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              content,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  // HÀM BUILD CHÍNH CỦA ITEM
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final primaryColor = const Color(0xFF6E48AA); 

    final announcement = widget.announcement;
    final content = announcement['content'] ?? 'Thông báo không có nội dung.';
    final createdAt = announcement['createdAt'] as String? ?? '2025-01-01T00:00:00.000Z';
    
    // Tùy chỉnh bo góc cho Card chính
    final cardBorderRadius = BorderRadius.vertical(
      top: const Radius.circular(16), 
      // Nếu có comment, bo góc dưới sẽ là Radius.zero để nối liền với phần comment/input
      bottom: Radius.zero, 
    );

    return Column(
      children: [
        // 1. CARD THÔNG BÁO 
        Card(
          color: cardColor,
          elevation: 6, 
          margin: const EdgeInsets.only(bottom: 0), 
          shape: RoundedRectangleBorder(borderRadius: cardBorderRadius), 
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryColor.withOpacity(0.15),
                      child: const Icon(Icons.campaign_rounded, color: Color(0xFF6E48AA), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thông báo mới từ Giảng viên',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.formatTime(createdAt), 
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 28, thickness: 1), 
                
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. CONTAINER CHỨA COMMENTS VÀ INPUT
        // Container này nối liền với Card và mang góc bo tròn dưới
        Column(
          children: [
            // DANH SÁCH COMMENTS HIỆN TẠI (chỉ hiển thị nếu có)
            if (_localComments.isNotEmpty)
              Container(
                color: cardColor,
                child: _buildCommentList(isDark, primaryColor),
              ),

            // INPUT COMMENT
            _buildCommentInput(isDark, primaryColor, cardColor!),
          ],
        ),
        
        const SizedBox(height: 16), // Khoảng cách giữa các bài đăng
      ],
    );
  }
}

// ==================== TAB BÀI TẬP ====================
class _AssignmentsTab extends StatefulWidget {
  final String classId;

  const _AssignmentsTab({Key? key, required this.classId}) : super(key: key);

  @override
  State<_AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<_AssignmentsTab> {
  // Dữ liệu bài tập thực tế từ API
  List<Map<String, dynamic>> assignments = [];
  bool isLoadingAssignments = true;

  @override
  void initState() {
    super.initState();
    // ⭐️ Bắt đầu tải dữ liệu khi tab được tạo
    _fetchAssignments();
  }

  // HÀM TẢI DANH SÁCH BÀI TẬP TỪ API
  Future<void> _fetchAssignments() async {
    if (mounted) {
      setState(() {
        isLoadingAssignments = true;
      });
    }

    try {
      // ⭐️ GỌI HÀM API ĐÃ ĐƯỢC ĐỊNH NGHĨA TRONG api_service.dart
      final fetchedAssignments = await ApiService.fetchAssignments(widget.classId);

      if (mounted) {
        setState(() {
          // Sắp xếp bài tập theo ngày tạo (mới nhất lên trên)
          assignments = fetchedAssignments.reversed.toList();
        });
      }
    } catch (e) {
      // Xử lý lỗi và hiển thị thông báo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Lỗi tải bài tập: ${e.toString().replaceFirst("Exception: ", "")}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAssignments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Hiển thị Loading
    if (isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Hiển thị thông báo khi không có bài tập
    if (assignments.isEmpty) {
      return const Center(child: Text("🎉 Lớp học chưa có bài tập nào."));
    }

    // Lấy màu nền và màu chữ hiện tại
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final primaryColor = const Color(0xFF6E48AA);
    final dangerColor = Colors.red[600];

    // 3. Hiển thị danh sách bài tập
    return RefreshIndicator(
      onRefresh: _fetchAssignments, // Kéo xuống để refresh
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0), // Tăng padding tổng thể
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          final String title = assignment['title'] ?? 'Bài tập không tên';
          final fileInfo = assignment['file'] as Map<String, dynamic>?;
          final String originalFileName = fileInfo?['originalFileName'] ?? 'Không có tệp';
          final DateTime dueDate = DateTime.tryParse(assignment['dueDate'] ?? '') ?? DateTime.now().add(const Duration(days: 7));
          final String formattedDueDate = DateFormat('dd/MM/yyyy HH:mm').format(dueDate.toLocal());
          
          // Kiểm tra xem đã quá hạn hay chưa
          final bool isOverdue = dueDate.isBefore(DateTime.now());

          return Card(
            color: cardColor,
            elevation: 8, // Tăng elevation
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              // Thêm border nhẹ để trông nổi bật hơn
              side: BorderSide(color: isOverdue ? dangerColor!.withOpacity(0.5) : primaryColor.withOpacity(0.1), width: 1.5), 
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: isOverdue ? dangerColor : primaryColor,
                child: Icon(
                  isOverdue ? Icons.timer_off_rounded : Icons.assignment_turned_in_rounded, 
                  color: Colors.white, 
                  size: 28
                ),
              ),
              title: Text(
                title, 
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: isDark ? Colors.white : Colors.black87,
                )
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tệp đính kèm: ${originalFileName.length > 30 ? originalFileName.substring(0, 27) + '...' : originalFileName}',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_filled, size: 16, color: isOverdue ? dangerColor : primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          isOverdue ? 'ĐÃ QUÁ HẠN: $formattedDueDate' : 'Hạn nộp: $formattedDueDate', 
                          style: TextStyle(
                            color: isOverdue ? dangerColor : primaryColor, 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 18, color: isDark ? Colors.white70 : Colors.black54),
              onTap: () {
                // TODO: Triển khai màn hình chi tiết bài tập/nộp bài
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Xem chi tiết bài tập: $title')),
                );
              },
            ),
          );
        },
      ),
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