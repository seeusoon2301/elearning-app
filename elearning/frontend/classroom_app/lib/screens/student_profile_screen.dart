import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb; // 🌟 IMPORT QUAN TRỌNG
import 'dart:typed_data';
class StudentProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const StudentProfileScreen({
    super.key,
    this.onProfileUpdated, // Khởi tạo callback
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isSaving = false;
  String? _studentId;
  String? _studentEmail;
  String? _currentAvatarUrl; // URL avatar hiện tại (Cloudinary URL)

  // ⭐️ THAY ĐỔI: Sử dụng Uint8List cho Web và File cho Mobile/Desktop
  File? _newAvatarFile; // File ảnh mới chọn (chỉ dùng cho Mobile/Desktop)
  Uint8List? _newAvatarBytes; // Byte data của ảnh (chỉ dùng cho Web)
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Tải thông tin từ SharedPreferences khi màn hình khởi tạo
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    final id = prefs.getString('studentId');
    final name = prefs.getString('studentName');
    final email = prefs.getString('studentEmail');
    final avatarUrl = prefs.getString('studentAvatarUrl');

    if (mounted) {
      setState(() {
        _studentId = id;
        _nameController.text = name ?? '';
        _studentEmail = email;
        _currentAvatarUrl = avatarUrl; // Lấy URL Cloudinary đã lưu
      });
    }
  }
  
  // Hàm chọn ảnh từ thư viện (Cập nhật cho Web)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      if (kIsWeb) {
        // ⭐️ CASE 1: FLUTTER WEB
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _newAvatarFile = null;
          _newAvatarBytes = bytes; // Lưu byte data
        });
      } else {
        // ⭐️ CASE 2: MOBILE/DESKTOP
        setState(() {
          _newAvatarBytes = null;
          _newAvatarFile = File(pickedFile.path); // Lưu file cục bộ
        });
      }
    }
  }

  // Hàm quan trọng nhất: Gửi và xử lý kết quả cập nhật
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _studentId == null) {
      return;
    }
    
    final currentName = _nameController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    final oldName = prefs.getString('studentName'); 

    final isNameChanged = oldName != null && oldName != currentName;
    final isAvatarChanged = _newAvatarFile != null || _newAvatarBytes != null;

    if (!isNameChanged && !isAvatarChanged) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không có thay đổi nào để lưu.'), backgroundColor: Colors.orange)
            );
        }
        return;
    }

    setState(() => isSaving = true);

    try {
      // 1. GỌI API: Tùy thuộc vào nền tảng, truyền File hoặc Byte Data
      final response = await ApiService.updateStudentProfile(
        studentId: _studentId!,
        name: isNameChanged ? currentName : null, 
        newAvatarFile: _newAvatarFile,
        newAvatarBytes: _newAvatarBytes,
        newAvatarFilename: kIsWeb && _newAvatarBytes != null ? "web_upload_${DateTime.now().millisecondsSinceEpoch}.png" : null,
      );

      if (mounted) {
        if (response['success'] == true) {
          
          // Cập nhật _currentAvatarUrl và _nameController từ SharedPreferences
          // (ApiService đã lưu mới nhất vào SharedPreferences)
          await _loadProfile(); 

          // ⭐️ BƯỚC THÔNG BÁO CHO HOMEPAGE (FIX LỖI QUAN TRỌNG)
          widget.onProfileUpdated?.call(); 
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật profile thành công!'), backgroundColor: Colors.green)
          );
          
          // ⭐️ BƯỚC ĐÓNG MÀN HÌNH (FIX LỖI QUAN TRỌNG)
          Navigator.of(context).pop(); 
          
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response['message']}',), backgroundColor: Colors.redAccent)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Xác định xem có ảnh preview (tạm thời) nào đang được hiển thị không
    final bool hasNewAvatar = _newAvatarFile != null || _newAvatarBytes != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ Sinh viên"),
        backgroundColor: const Color(0xFF6E48AA),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Email: ${_studentEmail ?? 'Đang tải...'}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey.shade300,
                      child: ClipOval(
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          // ⭐️ LOGIC HIỂN THỊ AVATAR (Cập nhật để hỗ trợ Web)
                          child: hasNewAvatar
                              ? kIsWeb // Nếu là Web, dùng Image.memory
                                ? Image.memory(
                                    _newAvatarBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file( // Nếu là Mobile/Desktop, dùng Image.file
                                    _newAvatarFile!,
                                    fit: BoxFit.cover,
                                  )
                              : _currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty 
                                ? CachedNetworkImage( // Hiển thị ảnh mạng Cloudinary
                                    imageUrl: _currentAvatarUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => const Icon(Icons.person, size: 80, color: Color(0xFF6E48AA)),
                                  )
                                : const Icon(Icons.person, size: 80, color: Color(0xFF6E48AA)), // Ảnh mặc định
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage, // Gọi hàm chọn ảnh
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