// lib/screens/quiz_list_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'create_quiz_screen.dart';
import '../instructor_drawer.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List<Map<String, dynamic>> quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  // TẢI QUIZ TỪ BỘ NHỚ
  Future<void> _loadQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('quizzes');
    if (data != null) {
      setState(() {
        quizzes = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  // LƯU QUIZ VÀO BỘ NHỚ
  Future<void> _saveQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quizzes', jsonEncode(quizzes));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const InstructorDrawer(),

      appBar: AppBar(
        title: const Text("Danh sách Quiz"),
        backgroundColor: const Color(0xFFFF8F00),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // Lệnh mở Drawer
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
      body: quizzes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  const Text("Chưa có quiz nào", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateScreen(),
                    icon: const Icon(Icons.add_circle),
                    label: const Text("Tạo Quiz đầu tiên", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8F00)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (context, i) {
                final q = quizzes[i];
                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFF8F00),
                      child: Text("${i + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(q['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${q['className'] ?? 'Lớp không tên'} • ${q['groupName'] ?? 'Toàn lớp'}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF8F00),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${q['questions'].length} câu • ${q['duration']} phút • ${q['attempts']} lần làm",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFFF8F00)),
                    onTap: () => _openCreateScreen(quiz: q, index: i),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF8F00),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        onPressed: _openCreateScreen,
      ),
    );
  }

  void _openCreateScreen({Map<String, dynamic>? quiz, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateQuizScreen(
          quiz: quiz,
          onSave: (newQuiz) async {
            if (index != null) {
              quizzes[index] = newQuiz;
            } else {
              quizzes.add(newQuiz);
            }
            setState(() {});
            await _saveQuizzes(); // LƯU NGAY KHI TẠO/SỬA
            _loadQuizzes(); // Load lại để chắc chắn
          },
        ),
      ),
    ).then((_) => _loadQuizzes()); // Khi back lại cũng load
  }
}