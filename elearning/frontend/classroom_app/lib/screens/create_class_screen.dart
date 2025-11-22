// lib/screens/create_class_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ⭐️ Import ApiService
import 'dart:async'; // Cần thiết cho Future và async/await

class CreateClassScreen extends StatefulWidget {
  // ⭐️ Thay đổi kiểu dữ liệu callback để nhận dữ liệu lớp học hoàn chỉnh từ server
  final Function(Map<String, dynamic>) onClassCreated; 
  const CreateClassScreen({super.key, required this.onClassCreated});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  bool _isLoading = false; // ⭐️ Biến trạng thái loading

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sectionCtrl.dispose();
    _roomCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  // ⭐️ HÀM XỬ LÝ GỌI API TẠO LỚP HỌC MỚI
  Future<void> _handleCreateClass() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Bắt đầu loading
    setState(() => _isLoading = true);

    final classDataToSend = {
      'name': _nameCtrl.text.trim(),
      'section': _sectionCtrl.text.trim(),
      'room': _roomCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
    };

    try {
      // 1. GỌI API ĐỂ TẠO LỚP HỌC
      final createdClass = await ApiService.createClass(classDataToSend); 

      // 2. NẾU THÀNH CÔNG: Gọi callback để cập nhật danh sách ở Dashboard
      widget.onClassCreated(createdClass); 

      // 3. Hiển thị thông báo thành công và đóng màn hình
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tạo lớp học thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      // 4. Xử lý lỗi và hiển thị SnackBar
      if (mounted) {
        final errorMessage = e.toString().replaceFirst("Exception: ", ""); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi tạo lớp học: $errorMessage"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Kết thúc loading
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Tạo lớp học", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              // ⭐️ SỬ DỤNG HÀM XỬ LÝ MỚI và vô hiệu hóa khi đang loading
              onPressed: _isLoading ? null : _handleCreateClass, 
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E48AA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: _isLoading
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                  )
                : const Text("Tạo", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // -------------------------------------------------------------
              // TextFormField: Tên lớp
              // -------------------------------------------------------------
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: "Tên lớp (bắt buộc)",
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.12) : Colors.grey[100],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6E48AA), width: 2),
                  ),
                ),
                validator: (value) => value!.trim().isEmpty ? "Vui lòng nhập tên lớp" : null,
              ),
              const SizedBox(height: 20),
              // -------------------------------------------------------------
              // TextFormField: Phần (Section)
              // -------------------------------------------------------------
              TextFormField(
                controller: _sectionCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: "Phần",
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.12) : Colors.grey[100],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6E48AA), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // -------------------------------------------------------------
              // TextFormField: Phòng (Room)
              // -------------------------------------------------------------
              TextFormField(
                controller: _roomCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: "Phòng",
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.12) : Colors.grey[100],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6E48AA), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // -------------------------------------------------------------
              // TextFormField: Chủ đề (Subject)
              // -------------------------------------------------------------
              TextFormField(
                controller: _subjectCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: "Chủ đề",
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.12) : Colors.grey[100],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6E48AA), width: 2),
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