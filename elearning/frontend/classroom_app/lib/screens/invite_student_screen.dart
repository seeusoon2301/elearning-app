// lib/screens/invite_student_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Đảm bảo đã import ApiService

class InviteStudentScreen extends StatefulWidget {
  final String classId;
  final String className;

  const InviteStudentScreen({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  State<InviteStudentScreen> createState() => _InviteStudentScreenState();
}

class _InviteStudentScreenState extends State<InviteStudentScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Hàm gọi API gửi lời mời
  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Đặt trạng thái loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi hàm API đã định nghĩa trong api_service.dart
      await ApiService.inviteStudent(widget.classId, _emailController.text.trim());

      // Thành công: Hiển thị thông báo và quay lại màn hình chi tiết lớp học
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã gửi lời mời thành công đến ${_emailController.text}!"),
            backgroundColor: const Color(0xFF6E48AA),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context); // Quay lại màn hình ClassDetailScreen
      }
    } catch (e) {
      // Thất bại: Hiển thị thông báo lỗi
      if (mounted) {
        // Loại bỏ tiền tố "Exception: " để thông báo đẹp hơn
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
    final iconColor = isDark ? const Color(0xFFE0AAFF) : const Color(0xFF6E48AA);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mời học viên vào lớp ${widget.className}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
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
              Text(
                "Nhập địa chỉ Email của học viên để gửi lời mời tham gia lớp học.",
                style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 30),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email.';
                  }
                  // Validation email đơn giản
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Email không hợp lệ.';
                  }
                  return null;
                },
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: "Email học viên",
                  prefixIcon: Icon(Icons.email_outlined, color: iconColor),
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.12) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: iconColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
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
                      _isLoading ? "Đang gửi..." : "Gửi lời mời",
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isLoading ? null : _sendInvitation,
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