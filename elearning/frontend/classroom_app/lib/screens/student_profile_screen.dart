import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isSaving = false;
  String? _studentId;
  String? _studentEmail;
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // ⭐️ SỬ DỤNG HÀM MỚI TẠO TỪ ApiService
    final studentInfo = await ApiService.getStudentInfoFromPrefs(); 

    if (studentInfo != null) {
        setState(() {
            _studentId = studentInfo.id; // Lấy ID
            _studentEmail = studentInfo.email; // Lấy Email
            _nameController.text = studentInfo.name; // Lấy Tên
            print("Profile Screen: Loaded Student ID: $_studentId");
        });
    } else {
        // Xử lý trường hợp không tìm thấy thông tin
        setState(() {
            _studentId = 'Không có ID';
            _studentEmail = 'Không có Email';
        });
        print("Profile Screen: Không tìm thấy thông tin sinh viên trong SharedPreferences.");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_studentId == null) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Lỗi: Không tìm thấy Student ID."), backgroundColor: Colors.redAccent));
        }
        return;
    }
    
    setState(() => isSaving = true);
    
    final newName = _nameController.text.trim();

    try {
      // 1. GỌI API ĐỂ CẬP NHẬT TÊN VÀO DATABASE
      await ApiService.updateStudentProfile(_studentId!, newName);
      
      // 2. LƯU TÊN MỚI VÀO SHARED PREFERENCES sau khi DB cập nhật thành công
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentName', newName); 

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã cập nhật tên thành công!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      print("Lỗi khi cập nhật tên: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cập nhật thất bại: ${e.toString().split(':').last}"), 
          backgroundColor: Colors.redAccent
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentAvatarBase64', base64String);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân"),
        backgroundColor: const Color(0xFF6E48AA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    FutureBuilder<String>(
                      future: SharedPreferences.getInstance()
                          .then((p) => p.getString('studentAvatarBase64') ?? ''),
                      builder: (context, snapshot) {
                        final base64String = snapshot.data ?? '';
                        final displayText = _nameController.text.trim().isEmpty
                            ? "H"
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
                          return CircleAvatar(radius: 80, backgroundImage: MemoryImage(bytes));
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Họ và tên",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.trim().isEmpty ? "Vui lòng nhập tên" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E48AA)),
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Lưu thay đổi", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}