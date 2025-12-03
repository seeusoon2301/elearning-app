// lib/screens/instructor_profile_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class InstructorProfileScreen extends StatefulWidget {
  const InstructorProfileScreen({super.key});

  @override
  State<InstructorProfileScreen> createState() => _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // Thêm dòng này cùng với các biến khác
  final ValueNotifier<String> _avatarNotifier = ValueNotifier<String>('');
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _departmentController;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _departmentController = TextEditingController();
    _loadProfile();
    _loadSavedAvatar();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Lấy tất cả thông tin đã lưu trước đó (nếu có)
      final savedName       = prefs.getString('instructorName') ?? '';
      final savedPhone      = prefs.getString('instructorPhone') ?? '';
      final savedDepartment = prefs.getString('instructorDepartment') ?? '';

      setState(() {
        _nameController.text       = savedName;
        _phoneController.text      = savedPhone;
        _departmentController.text = savedDepartment;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Lưu cả 3 trường vào SharedPreferences
      await prefs.setString('instructorName',       _nameController.text.trim());
      await prefs.setString('instructorPhone',      _phoneController.text.trim());
      await prefs.setString('instructorDepartment', _departmentController.text.trim());

      // Gọi API nếu có (không bắt buộc, vẫn chạy ngon khi backend chưa xong)
      final email = prefs.getString('userEmail') ?? '';
      await ApiService.updateInstructorProfile(
        email: email,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        department: _departmentController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green),
      );

      setState(() {});           // Cập nhật avatar chữ cái đầu trên avatar
      Navigator.pop(context);    // Quay về dashboard → header tự cập nhật

    } catch (e) {
      // Dù lỗi API → vẫn lưu local và báo thành công
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('instructorName',       _nameController.text.trim());
      await prefs.setString('instructorPhone',      _phoneController.text.trim());
      await prefs.setString('instructorDepartment', _departmentController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã lưu thông tin"), backgroundColor: Colors.green),
      );

      setState(() {});
      Navigator.pop(context);
    } finally {
      setState(() => isSaving = false);
    }
  }
 
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('instructorAvatarBase64', base64String);

      setState(() {}); // ép rebuild ngay

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đổi ảnh thành công!"), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _loadSavedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('instructorAvatar') ?? '';
    if (path.isNotEmpty) {
      _avatarNotifier.value = path;
    }
  }
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E48AA),
        foregroundColor: Colors.white,
        title: const Text("Hồ sơ cá nhân"),
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6E48AA)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          FutureBuilder<String>(
                            future: () async {
                              final prefs = await SharedPreferences.getInstance();
                              return prefs.getString('instructorAvatarBase64') ?? '';
                            }(),
                            builder: (context, snapshot) {
                              final base64String = snapshot.data ?? '';
                              final displayText = _nameController.text.trim().isEmpty 
                                  ? "G" 
                                  : _nameController.text.trim()[0].toUpperCase();

                              if (base64String.isEmpty) {
                                return CircleAvatar(
                                  radius: 80,
                                  backgroundColor: const Color(0xFF6E48AA),
                                  child: Text(displayText, style: const TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.bold)),
                                );
                              }

                              try {
                                final bytes = base64Decode(base64String);
                                return CircleAvatar(
                                  radius: 80,
                                  backgroundImage: MemoryImage(bytes),
                                );
                              } catch (e) {
                                return CircleAvatar(
                                  radius: 80,
                                  backgroundColor: const Color(0xFF6E48AA),
                                  child: Text(displayText, style: const TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.bold)),
                                );
                              }
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFF6E48AA), shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  
                    // Form chỉnh sửa
                    _buildTextField(_nameController, "Họ và tên", Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, "Số điện thoại", Icons.phone),
                    const SizedBox(height: 16),
                    _buildTextField(_departmentController, "Khoa/Bộ môn", Icons.business),

                    const SizedBox(height: 40),

                    // Nút lưu
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6E48AA),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Lưu thay đổi", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(color: enabled ? null : Colors.grey),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6E48AA)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6E48AA), width: 2),
        ),
      ),
      validator: (value) {
        if (label == "Họ và tên" && (value == null || value.isEmpty)) {
          return "Vui lòng nhập họ tên";
        }
        return null;
      },
    );
  }
}