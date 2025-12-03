// lib/screens/create_annoucement_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart'; 

class CreateAnnouncementScreen extends StatefulWidget {
  // ⭐️ THAY ĐỔI: Chỉ nhận classId, loại bỏ onCreated
  final String classId; 

  const CreateAnnouncementScreen({
    Key? key,
    required this.classId,
  }) : super(key: key);

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // HÀM GỌI API ĐỂ TẠO BẢNG TIN
  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ⭐️ GỌI HÀM API MỚI
      await ApiService.createAnnouncement(widget.classId, content); 

      // Thành công: Trả về `true` để ClassDetailScreen biết và tải lại dữ liệu
      if (mounted) {
        Navigator.pop(context, true); 
      }
    } catch (e) {
      // Thất bại: Hiển thị thông báo lỗi
      if (mounted) {
        final errorMessage = e.toString().replaceFirst("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Tắt trạng thái loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo thông báo mới"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                minLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nội dung thông báo không được để trống.';
                  }
                  return null;
                },
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "Nhập nội dung thông báo...",
                  hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.12) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFFE0AAFF) : const Color(0xFF6E48AA), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E48AA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                    ),
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      _isLoading ? "Đang tạo..." : "Đăng thông báo", 
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isLoading ? null : _createAnnouncement, 
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}