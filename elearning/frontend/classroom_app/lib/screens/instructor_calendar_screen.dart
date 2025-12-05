import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'package:intl/intl.dart';

// ==================== HÀM VÀ DỮ LIỆU HỖ TRỢ LỊCH ====================

// Dữ liệu giả định cho các sự kiện của Giảng viên
final kInstructorEvents = LinkedHashMap<DateTime, List<String>>(
  equals: isSameDay,
  hashCode: (DateTime key) => key.day * 1000000 + key.month * 10000 + key.year,
)..addAll({
    DateTime.utc(2025, 12, 8): ['Lịch dạy: Lập trình Di động (08:00)', 'Họp khoa Công nghệ (10:30)'],
    DateTime.utc(2025, 12, 10): ['Hạn chót chấm Assignment 1', 'Lịch dạy: Cơ sở dữ liệu (13:00)'],
    DateTime.utc(2025, 12, 15): ['Buổi tham vấn sinh viên'],
    DateTime.utc(2025, 12, 20): ['Lịch dạy: Lập trình Di động (08:00)'],
  });

class InstructorCalendarScreen extends StatefulWidget {
  const InstructorCalendarScreen({super.key});

  @override
  State<InstructorCalendarScreen> createState() => _InstructorCalendarScreenState();
}

class _InstructorCalendarScreenState extends State<InstructorCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month; // Mặc định hiển thị dạng tháng
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late ValueNotifier<List<String>> _selectedEvents;
  final Color primaryColor = const Color(0xFF9D50BB); // Màu chủ đạo của Giảng viên

  @override
  void initState() {
    super.initState();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // Hàm lấy sự kiện theo ngày
  List<String> _getEventsForDay(DateTime day) {
    return kInstructorEvents[day] ?? [];
  }

  // Xử lý khi chọn ngày
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Giảng Dạy', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: () {
              // TODO: Logic tạo sự kiện/lịch mới
            },
            tooltip: 'Thêm Lịch/Sự kiện',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. WIDGET LỊCH (TABLE CALENDAR)
          _buildCalendarWidget(isDark),
          
          // 2. TIÊU ĐỀ DANH SÁCH SỰ KIỆN
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
            child: Text(
              'Sự kiện (${DateFormat('dd/MM/yyyy').format(_selectedDay)})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : primaryColor,
              ),
            ),
          ),
          
          // 3. DANH SÁCH SỰ KIỆN
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: _selectedEvents,
              builder: (context, value, child) {
                if (value.isEmpty) {
                  return _buildNoEventPlaceholder(isDark);
                }
                
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return _buildEventTile(value[index], primaryColor, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Build Lịch
  Widget _buildCalendarWidget(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: TableCalendar(
        locale: 'vi_VN', 
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          formatButtonDecoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.0),
          ),
          formatButtonTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        calendarStyle: CalendarStyle(
          weekendTextStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
          markerDecoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: primaryColor.withOpacity(0.5), shape: BoxShape.circle),
          outsideDaysVisible: false, 
        ),
        eventLoader: _getEventsForDay,
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isNotEmpty) {
              return Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: Colors.redAccent, // Đánh dấu nổi bật hơn
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  // Widget Từng Sự kiện
  Widget _buildEventTile(String event, Color primaryColor, bool isDark) {
    IconData icon;
    Color iconColor;

    if (event.contains('Lịch dạy')) {
      icon = Icons.schedule_rounded;
      iconColor = Colors.blue;
    } else if (event.contains('Assignment') || event.contains('chấm')) {
      icon = Icons.edit_note_rounded;
      iconColor = Colors.orange;
    } else {
      icon = Icons.meeting_room_rounded;
      iconColor = primaryColor;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          event,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // TODO: Logic xem chi tiết sự kiện
        },
      ),
    );
  }

  // Widget Không có Sự kiện
  Widget _buildNoEventPlaceholder(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.task_alt_rounded, size: 60, color: isDark ? Colors.lightGreenAccent : Colors.lightGreen),
            const SizedBox(height: 10),
            Text(
              'Không có sự kiện quản lý hay giảng dạy nào cần chú ý!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}