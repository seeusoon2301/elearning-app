// lib/screens/student_notification_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Dữ liệu Thông báo giả định
class NotificationItem {
  final String id;
  final String title;
  final String content;
  final DateTime time;
  final IconData icon;
  final Color color;

  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    this.icon = Icons.info_outline,
    this.color = const Color(0xFF6E48AA),
  });
}

// Dữ liệu mẫu
List<NotificationItem> initialNotifications = [
  NotificationItem(
    id: '1',
    title: 'Bài kiểm tra mới',
    content: 'Giảng viên Nguyễn Văn A vừa đăng bài Quiz Cơ sở dữ liệu.',
    time: DateTime.now().subtract(const Duration(hours: 1)),
    icon: Icons.quiz_rounded,
    color: Colors.blueAccent,
  ),
  NotificationItem(
    id: '2',
    title: 'Thông báo chung',
    content: 'Đã cập nhật tài liệu học tập cho môn Lập trình di động.',
    time: DateTime.now().subtract(const Duration(hours: 3)),
    icon: Icons.assignment_rounded,
    color: const Color(0xFF6E48AA),
  ),
  NotificationItem(
    id: '3',
    title: 'Hạn nộp sắp tới',
    content: 'Assignment 1 môn Lập trình di động sẽ hết hạn trong 24 giờ.',
    time: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    icon: Icons.warning_rounded,
    color: Colors.redAccent,
  ),
  NotificationItem(
    id: '4',
    title: 'Điểm số mới',
    content: 'Điểm bài tập nhóm môn Cơ sở dữ liệu đã được công bố.',
    time: DateTime.now().subtract(const Duration(days: 4)),
    icon: Icons.score,
    color: Colors.green,
  ),
  NotificationItem(
    id: '5',
    title: 'Cập nhật tài liệu',
    content: 'Giảng viên đã đăng thêm slide mới cho môn Mạng máy tính.',
    time: DateTime.now().subtract(const Duration(days: 8)),
    icon: Icons.folder_shared_rounded,
    color: Colors.orangeAccent,
  ),
];


class StudentNotificationScreen extends StatefulWidget {
  const StudentNotificationScreen({super.key});

  @override
  State<StudentNotificationScreen> createState() => _StudentNotificationScreenState();
}

class _StudentNotificationScreenState extends State<StudentNotificationScreen> {
  // Dùng List để quản lý trạng thái có thể thay đổi (thêm/xóa)
  List<NotificationItem> _notifications = List.from(initialNotifications);

  // Phân loại thông báo theo thời gian
  Map<String, List<NotificationItem>> _groupNotifications(List<NotificationItem> notifications) {
    final now = DateTime.now();
    final Map<String, List<NotificationItem>> grouped = {};

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
    final primaryColor = const Color(0xFF6E48AA);
    final groupedNotifications = _groupNotifications(_notifications);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo mới', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read_rounded),
            onPressed: () {
              setState(() {
                _notifications.clear(); // Xóa tất cả
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu tất cả thông báo là đã đọc.')),
              );
            },
            tooltip: 'Đánh dấu tất cả là đã đọc',
          ),
        ],
      ),
      
      // Nếu không có thông báo nào, hiển thị Placeholder
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

  // WIDGET HIỂN THỊ TỪNG THẺ THÔNG BÁO
  Widget _buildNotificationCard(BuildContext context, NotificationItem notification, bool isDark, Color primaryColor) {
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
          
          // Icon thông báo (màu sắc tùy chỉnh)
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notification.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon, color: notification.color, size: 24),
          ),
          
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
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
                _formatTime(notification.time), // Thời gian
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          onTap: () {
            // TODO: Logic xem chi tiết thông báo
          },
        ),
      ),
    );
  }

  // Hàm định dạng thời gian
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
              'Hộp thư đến trống',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã xem hết các thông báo gần đây. Quay lại sau nhé!',
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