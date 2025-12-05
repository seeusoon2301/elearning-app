// lib/screens/student_list_for_instructor_screen.dart

import 'package:flutter/material.dart';

class StudentListForInstructorScreen extends StatelessWidget {
  const StudentListForInstructorScreen({super.key});

  // Dữ liệu sinh viên giả định
  final List<Map<String, String>> _students = const [
    {'name': 'Nguyễn Văn A', 'id': 'SV001', 'class': 'Lập trình Di động'},
    {'name': 'Trần Thị B', 'id': 'SV002', 'class': 'Cơ sở dữ liệu'},
    {'name': 'Lê Minh C', 'id': 'SV003', 'class': 'Lập trình Di động'},
    {'name': 'Phạm Văn D', 'id': 'SV004', 'class': 'Mạng Máy Tính'},
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3949AB); // Màu xanh của widget Sinh viên

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sinh viên', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.8),
                child: Text(student['name']![0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(student['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ID: ${student['id']} | Lớp: ${student['class']}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Logic xem chi tiết sinh viên
              },
            ),
          );
        },
      ),
    );
  }
}