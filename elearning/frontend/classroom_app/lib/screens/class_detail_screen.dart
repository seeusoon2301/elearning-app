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

  String _selectedGroup = "Chưa có nhóm";
  List<String> _groups = [];
  
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
    
    _loadGroups();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final groupKey = _selectedGroup == "Tất cả nhóm" ? "all" : _selectedGroup;
    final key = 'announcements_${widget.classData['name']}_$groupKey';
    final saved = prefs.getStringList(key) ?? [];
    if (mounted) setState(() => _announcements = saved);
  }

  Future<void> _saveAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final groupKey = _selectedGroup == "Tất cả nhóm" ? "all" : _selectedGroup;
    final key = 'announcements_${widget.classData['name']}_$groupKey';
    await prefs.setStringList(key, _announcements);
  }

  Future<void> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'groups_${widget.classData['name'] ?? 'class'}';
    final saved = prefs.getStringList(key) ?? [];
    
    if (mounted) {
      setState(() {
        _groups = saved;
        if (_groups.isEmpty) {
          _selectedGroup = "Chưa có nhóm";
        } else {
          _selectedGroup = _groups[0];
        }
      });
    }
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _showGroupSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: _groups.isEmpty
            // TRƯỜNG HỢP CHƯA CÓ NHÓM NÀO
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_outlined, size: 100, color: Colors.grey[500]),
                    const SizedBox(height: 24),
                    Text(
                      "Chưa có nhóm học nào",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Tạo nhóm đầu tiên để bắt đầu quản lý lớp",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final controller = TextEditingController();
                        final name = await showDialog<String>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            title: Text("Tạo nhóm đầu tiên", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: "Ví dụ: Nhóm 1, Nhóm LT, Nhóm A...",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, controller.text.trim()),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E48AA)),
                                child: const Text("Tạo", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (name != null && name.isNotEmpty) {
                          setState(() {
                            _groups.add(name);
                            _selectedGroup = name;
                          });
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setStringList('groups_${widget.classData['name']}', _groups);
                          _loadAnnouncements();
                        }
                      },
                      icon: const Icon(Icons.add_circle, size: 28),
                      label: const Text("Tạo nhóm đầu tiên", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E48AA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 10,
                      ),
                    ),
                  ],
                ),
              )
            // TRƯỜNG HỢP ĐÃ CÓ NHÓM
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thanh kéo
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 6,
                    decoration: BoxDecoration(color: isDark ? Colors.grey[700] : Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text("Chọn nhóm học", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1, thickness: 1),
                  SizedBox(
                    height: 360,
                    child: ListView.builder(
                      itemCount: _groups.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        final isSelected = group == _selectedGroup;

                        return ListTile(
                          leading: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? const Color(0xFF6E48AA) : (isDark ? Colors.grey[600] : Colors.grey),
                            size: 28,
                          ),
                          title: Text(
                            group,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            color: isDark ? Colors.grey[800] : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final controller = TextEditingController(text: group);
                                final newName = await showDialog<String>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                    title: Text("Sửa tên nhóm", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                                    content: TextField(controller: controller, autofocus: true),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, controller.text.trim()),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E48AA)),
                                        child: const Text("Lưu", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (newName != null && newName.isNotEmpty && newName != group) {
                                  setState(() {
                                    _groups[index] = newName;
                                    if (_selectedGroup == group) _selectedGroup = newName;
                                  });
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setStringList('groups_${widget.classData['name']}', _groups);
                                  _loadAnnouncements();
                                }
                              } else if (value == 'delete') {
                                if (_selectedGroup == group) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Không thể xóa nhóm đang chọn!")),
                                  );
                                  return;
                                }
                                setState(() => _groups.removeAt(index));
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setStringList('groups_${widget.classData['name']}', _groups);
                                await prefs.remove('announcements_${widget.classData['name']}_$group');
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa nhóm: $group")));
                              }
                              Navigator.pop(context);
                              _showGroupSelector(context);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text("Chỉnh sửa")])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 12), Text("Xóa", style: TextStyle(color: Colors.red))])),
                            ],
                          ),
                          onTap: () {
                            setState(() => _selectedGroup = group);
                            _loadAnnouncements();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  // Nút tạo nhóm mới
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final controller = TextEditingController();
                        final name = await showDialog<String>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            title: const Text("Tạo nhóm mới"),
                            content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: "Tên nhóm")),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, controller.text.trim()),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E48AA)),
                                child: const Text("Tạo", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (name != null && name.isNotEmpty && !_groups.contains(name)) {
                          setState(() {
                            _groups.add(name);
                            _selectedGroup = name;
                          });
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setStringList('groups_${widget.classData['name']}', _groups);
                          _loadAnnouncements();
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 26),
                      label: const Text("Tạo nhóm mới", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E48AA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 10,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
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
            GestureDetector(
              onTap: () => _showGroupSelector(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _groups.isEmpty
                        ? [Colors.orange.withOpacity(0.4), Colors.red.withOpacity(0.3)]
                        : [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.15)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _groups.isEmpty ? Colors.orange : Colors.white.withOpacity(0.7),
                    width: 1.8,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _groups.isEmpty ? Icons.warning_amber_rounded : Icons.groups_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _groups.isEmpty ? "Chưa có nhóm" : _selectedGroup,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),

        actions: [
          // ⭐️ THÊM ICON MỜI HỌC VIÊN KHI Ở TAB "MỌI NGƯỜI" (index 2)
          if (_selectedIndex == 2) 
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: const Icon(Icons.person_add, color: Colors.white, size: 28),
                tooltip: 'Mời học viên',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InviteStudentScreen(
                        // Truyền ID và Tên lớp để màn hình mời sử dụng
                        classId: widget.classData['_id']?.toString() ?? '',
                        className: widget.classData['name'] ?? 'Lớp học',
                      ),
                    ),
                  );
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
    required this.classId,
    required this.iconColor,
    required this.textColor,
    required this.className,
  });

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
                          // Không cần điều hướng ở đây, vì đã có nút mời ở AppBar
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