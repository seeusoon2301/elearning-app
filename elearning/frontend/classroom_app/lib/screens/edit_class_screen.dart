// lib/screens/edit_class_screen.dart
import 'package:flutter/material.dart';
// KHÔNG CẦN import ApiService nữa vì chỉ làm Frontend

class EditClassScreen extends StatefulWidget {
  final Map<String, dynamic> classData;

  const EditClassScreen({super.key, required this.classData});

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers cho các trường form
  late TextEditingController _nameController;
  late TextEditingController _subjectController;
  late TextEditingController _roomController;
  late TextEditingController _instructorController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controllers với dữ liệu lớp học hiện tại
    _nameController = TextEditingController(text: widget.classData['name'] ?? '');
    _subjectController = TextEditingController(text: widget.classData['subject'] ?? '');
    _roomController = TextEditingController(text: widget.classData['room'] ?? '');
    _instructorController = TextEditingController(text: widget.classData['instructor'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _roomController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  // Hàm xử lý việc gửi form (CHỈ LÀM LOGIC FRONTEND)
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ⭐️ BẮT ĐẦU LOGIC GIẢ LẬP GỌI API (Frontend Only)
    setState(() {
      _isLoading = true;
    });

    // Mô phỏng độ trễ của API
    await Future.delayed(const Duration(milliseconds: 500)); 

    // Dữ liệu mới được tạo ra (Gộp dữ liệu cũ và các trường mới)
    final updatedData = {
      // Giữ lại các trường không sửa đổi (như _id, semester,...)
      ...widget.classData, 
      'name': _nameController.text.trim(),
      'subject': _subjectController.text.trim(),
      'room': _roomController.text.trim(),
      'instructor': _instructorController.text.trim(),
    };
    
    // Nếu bạn muốn gọi API:
    // try {
    //   final result = await ApiService.updateClass(widget.classData['_id']!, updatedData);
    //   Navigator.pop(context, result);
    // } catch (e) { ... }

    if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Trả về dữ liệu lớp học đã được cập nhật
        Navigator.pop(context, updatedData); 
    }
    // ⭐️ KẾT THÚC LOGIC GIẢ LẬP GỌI API
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6E48AA);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chỉnh Sửa Lớp Học",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        foregroundColor: primaryColor,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tên lớp
                    _buildTextFormField(
                      controller: _nameController,
                      label: "Tên Lớp học (*)",
                      icon: Icons.school_rounded,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên lớp học.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Chủ đề/Môn học
                    _buildTextFormField(
                      controller: _subjectController,
                      label: "Môn Học (Chủ đề)",
                      icon: Icons.book_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Phòng học
                    _buildTextFormField(
                      controller: _roomController,
                      label: "Phòng Học (Tùy chọn)",
                      icon: Icons.room_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Tên Giảng viên
                    _buildTextFormField(
                      controller: _instructorController,
                      label: "Tên Giảng viên",
                      icon: Icons.person_rounded,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên giảng viên.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Nút Lưu
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_rounded, size: 28),
                      label: const Text(
                        "Lưu Thay Đổi",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 10,
                        shadowColor: primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper widget cho TextFormField
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    const primaryColor = Color(0xFF6E48AA);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
    final fillColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final labelColor = isDark ? Colors.white70 : Colors.black87;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: primaryColor, size: 26),
        filled: true,
        fillColor: fillColor,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }
}