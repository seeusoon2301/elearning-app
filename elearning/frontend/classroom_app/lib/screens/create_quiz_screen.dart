// lib/screens/create_quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/semester_provider.dart';
import '../services/api_service.dart';

class CreateQuizScreen extends StatefulWidget {
  final Map<String, dynamic>? quiz;
  final Function(Map<String, dynamic>)? onSave;

  const CreateQuizScreen({super.key, this.quiz, this.onSave});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  late TextEditingController _nameCtrl;
  DateTime? openTime;
  DateTime? closeTime;
  int duration = 30;
  int attempts = 1;

  String? selectedClassId;
  List<Map<String, dynamic>> classes = <Map<String, dynamic>>[];
  // DANH SÁCH CÂU HỎI GIẢNG VIÊN TỰ TẠO
  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.quiz?['name'] ?? '');
    _loadClasses();

    if (widget.quiz != null) {
      openTime = widget.quiz!['openTime'] != null
          ? DateTime.tryParse(widget.quiz!['openTime'])
          : null;
      closeTime = widget.quiz!['closeTime'] != null
          ? DateTime.tryParse(widget.quiz!['closeTime'])
          : null;
      duration = (widget.quiz!['duration'] as num?)?.toInt() ?? 30;
      attempts = (widget.quiz!['attempts'] as num?)?.toInt() ?? 1;
      questions = List<Map<String, dynamic>>.from(widget.quiz!['questions'] ?? []);
    }
  }

  Future<void> _loadClasses() async {
    final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
    if (semesterProvider.current == null) return;

    try {
      final fetched = await ApiService.fetchClassesBySemesterId(semesterProvider.current!.id);
      setState(() {
        classes = fetched;
        if (classes.isNotEmpty && selectedClassId == null) {
          selectedClassId = classes[0]['_id'];
        }
      });
    } catch (e) {}
  }

   void _addQuestion() {
    final questionCtrl = TextEditingController();
    final List<TextEditingController> answerCtrls = List.generate(4, (_) => TextEditingController());
    int correctIndex = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        // TẠO STATE RIÊNG CHO DIALOG ĐỂ RADIO CÓ THỂ REBUILD
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Thêm câu hỏi mới", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8F00))),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: questionCtrl,
                        decoration: InputDecoration(
                          labelText: "Nội dung câu hỏi",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8F00), width: 2)),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(4, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => dialogSetState(() => correctIndex = i), // ← DÙNG dialogSetState
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: correctIndex == i ? const Color(0xFFFF8F00).withOpacity(0.15) : null,
                              border: Border.all(color: correctIndex == i ? const Color(0xFFFF8F00) : Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  correctIndex == i ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: correctIndex == i ? const Color(0xFFFF8F00) : Colors.grey,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: answerCtrls[i],
                                    decoration: InputDecoration(
                                      labelText: "Đáp án ${i + 1}",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFF8F00))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8F00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () {
                    if (questionCtrl.text.trim().isEmpty || 
                        answerCtrls.any((c) => c.text.trim().isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Vui lòng nhập đầy đủ câu hỏi và đáp án!"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    setState(() {
                      questions.add({
                        'question': questionCtrl.text.trim(),
                        'options': answerCtrls.map((c) => c.text.trim()).toList(),
                        'correctAnswer': correctIndex,
                      });
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã thêm câu hỏi thành công!"), backgroundColor: Colors.green),
                    );
                  },
                  child: const Text("Thêm câu hỏi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Color _getTextColor() => Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;
  Color _getFillColor() => Theme.of(context).brightness == Brightness.dark ? Colors.grey[850]! : Colors.grey[50]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz != null ? "Chỉnh sửa Quiz" : "Tạo Quiz mới"),
        backgroundColor: const Color(0xFFFF8F00),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedClassId,
              hint: const Text("Chọn lớp học"),
              decoration: InputDecoration(
                labelText: "Lớp học *",
                filled: true,
                fillColor: _getFillColor(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: classes.map<DropdownMenuItem<String>>((c) {
                final String id = c['_id'] as String;
                final String name = c['name'] as String? ?? 'Lớp không tên';
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedClassId = v),
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Tên Quiz *", border: OutlineInputBorder())),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildDatePicker("Thời gian mở", openTime, (d) => setState(() => openTime = d))),
                const SizedBox(width: 12),
                Expanded(child: _buildDatePicker("Thời gian đóng", closeTime, (d) => setState(() => closeTime = d))),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Thời lượng (phút)", border: OutlineInputBorder()),
                    onChanged: (v) => duration = int.tryParse(v) ?? 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Số lần làm", border: OutlineInputBorder()),
                    onChanged: (v) => attempts = int.tryParse(v) ?? 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Câu hỏi (${questions.length})", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF8F00))),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Thêm câu hỏi"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8F00)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (questions.isEmpty)
              const Center(child: Text("Chưa có câu hỏi nào. Bấm nút để thêm!", style: TextStyle(color: Colors.grey))),
            ...questions.asMap().entries.map((e) {
              final index = e.key;
              final q = e.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(q['question'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Đáp án đúng: ${q['options'][q['correctAnswer']]}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => questions.removeAt(index)),
                  ),
                ),
              );
            }),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.trim().isEmpty || questions.isEmpty || selectedClassId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin và thêm ít nhất 1 câu hỏi!"), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  final quizData = {
                    'name': _nameCtrl.text.trim(),
                    'classId': selectedClassId,
                    'className': classes.firstWhere((c) => c['_id'] == selectedClassId)['name'],
                    'openTime': openTime?.toIso8601String(),
                    'closeTime': closeTime?.toIso8601String(),
                    'duration': duration,
                    'attempts': attempts,
                    'questions': questions,
                  };

                  widget.onSave?.call(quizData);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8F00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  widget.quiz != null ? "CẬP NHẬT QUIZ" : "TẠO QUIZ",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime) onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFFFF8F00)),
            const SizedBox(width: 12),
            Text(date == null ? label : "${date.day}/${date.month}/${date.year}"),
          ],
        ),
      ),
    );
  }
}