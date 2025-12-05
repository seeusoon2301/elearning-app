// lib/screens/instructor_notification_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Dữ liệu Thông báo Giảng viên giả định
class InstructorNotificationItem {
  final String id;
  final String title;
  final String content;
  final DateTime time;
  final IconData icon;
  final Color color;
  final String tag; // Ví dụ: 'Assignment', 'Enrollment', 'System'

  InstructorNotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    this.icon = Icons.info_outline,
    this.color = const Color(0xFF6E48AA),
    this.tag = 'System',
  });
}

// Dữ liệu mẫu (Tập trung vào các hoạt động quản lý lớp học)
List<InstructorNotificationItem> initialInstructorNotifications = [
  InstructorNotificationItem(
    id: '1',
    title: 'Assignment đã nộp',
    content: '15 sinh viên lớp Lập trình Di động vừa nộp Bài tập lớn.',
    time: DateTime.now().subtract(const Duration(minutes: 30)),
    icon: Icons.upload_file_rounded,
    color: Colors.green,
    tag: 'Assignment',
  ),
  InstructorNotificationItem(
    id: '2',
    title: 'Yêu cầu tham gia lớp',
    content: 'Sinh viên Nguyễn Văn B vừa gửi yêu cầu tham gia lớp Cơ sở dữ liệu.',
    time: DateTime.now().subtract(const Duration(hours: 2)),
    icon: Icons.person_add_alt_1_rounded,
    color: Colors.blueAccent,
    tag: 'Enrollment',
  ),
  InstructorNotificationItem(
    id: '3',
    title: 'Hệ thống bảo trì',
    content: 'Hệ thống sẽ bảo trì từ 23:00 - 01:00 sáng mai. Vui lòng lưu công việc.',
    time: DateTime.now().subtract(const Duration(days: 1)),
    icon: Icons.handyman_rounded,
    color: Colors.orangeAccent,
    tag: 'System',
  ),
  InstructorNotificationItem(
    id: '4',
    title: 'Quiz vừa nộp',
    content: '5 sinh viên đã hoàn thành Bài kiểm tra giữa kỳ môn Toán cao cấp.',
    time: DateTime.now().subtract(const Duration(days: 3)),
    icon: Icons.quiz_rounded,
    color: const Color(0xFF6E48AA),
    tag: 'Quiz',
  ),
];

// Hàm định dạng thời gian (giống bên sinh viên)
String _formatTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} phút trước';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} giờ trước';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} ngày trước';
  } else {
    return DateFormat('dd/MM/yyyy HH:mm').format(time);
  }
}

class InstructorNotificationScreen extends StatefulWidget {
  const InstructorNotificationScreen({super.key});

  @override
  State<InstructorNotificationScreen> createState() => _InstructorNotificationScreenState();
}

class _InstructorNotificationScreenState extends State<InstructorNotificationScreen> {
  List<InstructorNotificationItem> _notifications = List.from(initialInstructorNotifications);

  // Phân loại thông báo theo thời gian (giống bên sinh viên)
  Map<String, List<InstructorNotificationItem>> _groupNotifications(List<InstructorNotificationItem> notifications) {
    final now = DateTime.now();
    final Map<String, List<InstructorNotificationItem>> grouped = {};

    for (var notification in notifications) {
      String groupKey;
      final difference = now.difference(notification.time);

      if (difference.inHours < 24 && now.day == notification.time.day) {
        groupKey = 'Hôm nay';
      } else if (difference.inDays <= 7) {
        groupKey = 'Tuần này';
      } else if (difference.inDays <= 30) {
        groupKey = 'Tháng này';
      } else {
        groupKey = 'Cũ hơn';
      }

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(notification);
    }
    return grouped;
  }

  // Xóa thông báo
  void _dismissNotification(String id) {
    setState(() {
      _notifications.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF9D50BB); // Màu tím đậm hơn cho Giảng viên
    final groupedNotifications = _groupNotifications(_notifications);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo quản lý', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_rounded),
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc.')),
              );
            },
            tooltip: 'Đánh dấu tất cả là đã đọc',
          ),
        ],
      ),
      
      body: _notifications.isEmpty
          ? _buildEmptyPlaceholder(isDark)
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              children: groupedNotifications.keys.map((groupKey) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề nhóm
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        groupKey,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    // Danh sách thông báo trong nhóm
                    ...groupedNotifications[groupKey]!.map((notification) {
                      return _buildNotificationCard(context, notification, isDark, primaryColor);
                    }).toList(),
                    
                    if (groupKey != groupedNotifications.keys.last) 
                       const Divider(height: 20, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
    );
  }

  // WIDGET HIỂN THỊ TỪNG THẺ THÔNG BÁO (Có Tag/Category)
  Widget _buildNotificationCard(BuildContext context, InstructorNotificationItem notification, bool isDark, Color primaryColor) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _dismissNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa thông báo "${notification.title}"')),
        );
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDark ? Colors.grey[850] : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notification.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon, color: notification.color, size: 24),
          ),
          
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                notification.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              // ⭐️ THÊM TAG/PHÂN LOẠI
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  notification.tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(notification.time),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          onTap: () {
            // TODO: Logic xem chi tiết thông báo
          },
        ),
      ),
    );
  }

  // WIDGET PLACEHOLDER KHI KHÔNG CÓ THÔNG BÁO
  Widget _buildEmptyPlaceholder(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_rounded, size: 80, color: isDark ? Colors.grey[700] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có thông báo mới',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã xem hết các hoạt động quản lý gần đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}