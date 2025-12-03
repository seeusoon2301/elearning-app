import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('studentName') ?? '';
    setState(() {
      _nameController.text = savedName;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('studentName', _nameController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã lưu thông tin!"), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
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