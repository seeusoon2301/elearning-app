// lib/screens/create_class_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';

class CreateClassScreen extends StatefulWidget {
  // Thay đổi kiểu dữ liệu callback để nhận dữ liệu lớp học hoàn chỉnh từ server
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

  // ⭐️ THÊM TRẠNG THÁI CHO HỌC KỲ
  List<Map<String, dynamic>> _semesters = []; // Danh sách học kỳ tải về
  String? _selectedSemesterId; // ID của học kỳ được chọn
  bool _isLoading = false; 
  bool _isSemestersLoading = true; // Trạng thái tải danh sách học kỳ
  String? _semesterLoadError; // Lỗi khi tải danh sách học kỳ

  @override
  void initState() {
    super.initState();
    _fetchSemesters(); // Bắt đầu tải danh sách học kỳ
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sectionCtrl.dispose();
    _roomCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  // ⭐️ HÀM TẢI DANH SÁCH HỌC KỲ
  Future<void> _fetchSemesters() async {
    setState(() {
      _isSemestersLoading = true;
      _semesterLoadError = null;
    });

    try {
      final list = await ApiService.fetchSemesters();
      if (mounted) {
        setState(() {
          _semesters = list.cast<Map<String, dynamic>>();
          _selectedSemesterId = _semesters.isNotEmpty ? _semesters.first['_id'] : null;
          _isSemestersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _semesterLoadError = 'Không thể tải danh sách học kỳ: ${e.toString().replaceFirst("Exception: ", "")}';
          _isSemestersLoading = false;
        });
      }
    }
  }

  // ⭐️ HÀM XỬ LÝ GỌI API TẠO LỚP HỌC MỚI (CÓ THÊM semesterId)
  Future<void> _handleCreateClass() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Kiểm tra đã chọn học kỳ chưa
    if (_selectedSemesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn một học kỳ."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Bắt đầu loading
    setState(() => _isLoading = true);

    final classDataToSend = {
      'name': _nameCtrl.text.trim(),
      'section': _sectionCtrl.text.trim(),
      'room': _roomCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
      // 🔑 GỬI ID HỌC KỲ ĐÃ CHỌN LÊN SERVER
      'semesterId': _selectedSemesterId!, 
    };

    try {
      // 1. GỌI API ĐỂ TẠO LỚP HỌC
      final createdClass = await ApiService.createClass(classDataToSend); 

      // 2. NẾU THÀNH CÔNG: Gọi callback
      widget.onClassCreated(createdClass); 

      // 3. Hiển thị thông báo thành công và đóng màn hình
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tạo lớp học thành công và đã liên kết với Học kỳ!"),
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


  Widget _buildSemesterSelector(bool isDark) {
    if (_isSemestersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_semesterLoadError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          _semesterLoadError!, 
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_semesters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(
          "⚠️ Chưa có Học kỳ nào được tạo. Vui lòng tạo Học kỳ trước.", 
          style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedSemesterId,
      decoration: InputDecoration(
        labelText: "Chọn Học kỳ (Bắt buộc)",
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
      isExpanded: true,
      items: _semesters.map((semester) {
        return DropdownMenuItem<String>(
          value: semester['_id'],
          child: Text(semester['name'] ?? semester['code'] ?? 'Học kỳ không tên'),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSemesterId = newValue;
        });
      },
      validator: (value) => value == null ? "Vui lòng chọn học kỳ" : null,
    );
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
              // Vô hiệu hóa nút TẠO nếu đang loading hoặc không có học kỳ để chọn
              onPressed: _isLoading || _isSemestersLoading || _semesters.isEmpty
                  ? null 
                  : _handleCreateClass, 
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
                : const Text("Tạo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white )),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ⭐️ DROPDOWN: CHỌN HỌC KỲ
              _buildSemesterSelector(isDark),
              const SizedBox(height: 20),
              
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