// lib/screens/create_announcement_screen.dart
import 'package:flutter/material.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final Function(String content) onCreated;

  const CreateAnnouncementScreen({Key? key, required this.onCreated})
      : super(key: key);

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _canPost = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _canPost = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _postAnnouncement() {
    if (_canPost) {
      widget.onCreated(_controller.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark ? Colors.grey[900]! : Colors.grey[50]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Thông báo tin gì đó cho lớp",
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _canPost ? _postAnnouncement : null,
              child: Text(
                "Tạo",
                style: TextStyle(
                  color: _canPost ? const Color(0xFF6E48AA) : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header giống Google Classroom thật
          Container(
            color: cardColor,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF6E48AA),
                  child: const Text(
                    "GV",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: TextStyle(fontSize: 18, color: textColor),
                    decoration: InputDecoration(
                      hintText: "Thông báo tin gì đó cho lớp",
                      hintStyle: TextStyle(color: hintColor),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Các tùy chọn thêm (giữ nguyên như Google Classroom)
          ListTile(
            leading: Icon(Icons.attach_file, color: hintColor),
            title: Text("Thêm tệp đính kèm", style: TextStyle(color: textColor)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Chưa hỗ trợ đính kèm file")),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.link, color: hintColor),
            title: Text("Thêm liên kết", style: TextStyle(color: textColor)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.image, color: hintColor),
            title: Text("Thêm ảnh", style: TextStyle(color: textColor)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}