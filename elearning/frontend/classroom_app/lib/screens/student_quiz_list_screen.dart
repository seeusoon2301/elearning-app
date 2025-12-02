// lib/screens/student_quiz_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/semester_provider.dart';
import '../services/api_service.dart';

class StudentQuizListScreen extends StatefulWidget {
  const StudentQuizListScreen({super.key});

  @override
  State<StudentQuizListScreen> createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
  List<dynamic> quizzes = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentSemesterName;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final studentEmail = prefs.getString('userEmail') ?? '';

      if (studentEmail.isEmpty || studentEmail == 'admin') {
        throw Exception("Không tìm thấy thông tin sinh viên");
      }

      final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
      final currentSemester = semesterProvider.current;

      if (currentSemester == null) {
        throw Exception("Vui lòng chọn học kỳ trước khi xem quiz");
      }

      setState(() => currentSemesterName = currentSemester.name);

      // GỌI API THẬT – LẤY TẤT CẢ QUIZ CỦA SINH VIÊN TRONG HỌC KỲ ĐÃ CHỌN
      final response = await ApiService.getStudentQuizzes(
        studentEmail: studentEmail,
        semesterName: currentSemester.name,
      );

      setState(() {
        quizzes = response; // DỮ LIỆU THẬT TỪ BACKEND
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E48AA),
        foregroundColor: Colors.white,
        title: const Text("Quiz của tôi"),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadQuizzes,
            tooltip: "Làm mới",
          ),
        ],
      ),
      body: Consumer<SemesterProvider>(
        builder: (context, semesterProvider, child) {
          final current = semesterProvider.current?.name ?? "Chưa chọn học kỳ";

          // TỰ ĐỘNG RELOAD KHI ĐỔI HỌC KỲ
          if (current != currentSemesterName && !isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuizzes());
          }

          return Column(
            children: [
              // Header học kỳ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF9D50BB).withOpacity(0.12),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, color: Color(0xFF6E48AA), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Học kỳ: $current",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Nội dung chính
              Expanded(
                child: _buildBody(isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6E48AA)),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                "Không thể tải quiz",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[300], fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadQuizzes,
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E48AA)),
              ),
            ],
          ),
        ),
      );
    }

    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 90, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              "Chưa có quiz nào",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              "Quiz sẽ xuất hiện khi giảng viên tạo và phân phối",
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        final bool isSubmitted = quiz['isSubmitted'] == true || quiz['submitted'] == true;

        return Card(
          elevation: 5,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: isSubmitted ? Colors.green : const Color(0xFF9D50BB),
              child: Icon(
                isSubmitted ? Icons.check_circle : Icons.quiz_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            title: Text(
              quiz['title'] ?? "Quiz không tên",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Môn: ${quiz['className'] ?? quiz['courseName'] ?? 'Không rõ'}"),
                Text("Hạn nộp: ${quiz['dueDate'] ?? 'Không có hạn'}"),
              ],
            ),
            trailing: Chip(
              label: Text(isSubmitted ? "Đã nộp" : "Chưa nộp"),
              backgroundColor: isSubmitted ? Colors.green : Colors.orange,
              labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              // Sau này vào trang làm quiz
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Mở quiz: ${quiz['title']}")),
              );
            },
          ),
        );
      },
    );
  }
}