// lib/screens/assignment_list_for_instructor_screen.dart

import 'package:flutter/material.dart';

class AssignmentListForInstructorScreen extends StatelessWidget {
  const AssignmentListForInstructorScreen({super.key});

  // Dữ liệu Bài tập giả định
  final List<Map<String, dynamic>> _assignments = const [
    {
      'title': 'Assignment 1: Xây dựng giao diện',
      'class': 'Lập trình Di động',
      'due_date': '20/12/2025',
      'submitted': 45,
      'total': 60,
      'color': Color(0xFF2E7D32),
    },
    {
      'title': 'Báo cáo cuối kỳ: Phân tích dữ liệu',
      'class': 'Cơ sở dữ liệu',
      'due_date': '05/01/2026',
      'submitted': 12,
      'total': 50,
      'color': Color(0xFFD32F2F), // Màu đỏ: Sắp hết hạn/ít nộp
    },
    {
      'title': 'Bài tập nhóm: Mô hình hóa',
      'class': 'Thiết kế hệ thống',
      'due_date': '15/11/2025', // Đã qua hạn
      'submitted': 30,
      'total': 30,
      'color': Color(0xFF00695C), // Màu xanh đậm: Hoàn thành
    },
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2E7D32); // Màu xanh của widget Bài tập

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Bài tập', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: () {
              // TODO: Logic thêm bài tập mới
            },
            tooltip: 'Tạo Bài tập mới',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final assignment = _assignments[index];
          final progress = assignment['submitted'] / assignment['total'];
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: Icon(Icons.assignment_rounded, color: assignment['color']),
              title: Text(
                assignment['title']!, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Lớp: ${assignment['class']}'),
                  Text('Hạn chót: ${assignment['due_date']}'),
                  const SizedBox(height: 8),
                  
                  // Thanh tiến trình nộp bài
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(assignment['color']),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã nộp: ${assignment['submitted']}/${assignment['total']} (${(progress * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                // TODO: Logic xem chi tiết/chấm bài
              },
            ),
          );
        },
      ),
    );
  }
}