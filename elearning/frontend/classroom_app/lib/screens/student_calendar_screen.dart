// lib/screens/student_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'package:intl/intl.dart';

// ==================== HÀM VÀ DỮ LIỆU HỖ TRỢ LỊCH ====================

// Dữ liệu giả định cho các sự kiện/nhiệm vụ
final kEvents = LinkedHashMap<DateTime, List<String>>(
  equals: isSameDay,
  hashCode: getHashCode,
)..addAll({
    DateTime.utc(2025, 12, 10): ['Nộp Assignment 1', 'Kiểm tra giữa kỳ Toán'],
    DateTime.utc(2025, 12, 15): ['Hạn cuối Đăng ký môn học'],
    DateTime.utc(2025, 12, 25): ['Nghỉ lễ Giáng Sinh'],
    DateTime.utc(2026, 1, 5): ['Báo cáo cuối kỳ Lập trình Di động'],
  });

// Hàm hỗ trợ lấy hashCode
int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

// ==================== WIDGET CHÍNH: LỊCH HỌC SINH VIÊN ====================

class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({super.key});

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  // ⭐️ THAY ĐỔI: Mặc định hiển thị dạng tuần để gọn hơn
  CalendarFormat _calendarFormat = CalendarFormat.week; 
  DateTime _focusedDay = DateTime.now();
  // ⭐️ THAY ĐỔI: Mặc định chọn ngày hiện tại
  DateTime _selectedDay = DateTime.now(); 

  // Danh sách sự kiện cho ngày được chọn
  late ValueNotifier<List<String>> _selectedEvents;

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
    return kEvents[day] ?? [];
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
    final primaryColor = const Color(0xFF6E48AA); 
    final cardColor = isDark ? Colors.grey[850] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Học Của Tôi', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. WIDGET LỊCH (TABLE CALENDAR - Gọn gàng hơn)
          _buildCalendarWidget(isDark, primaryColor, cardColor!),

          // 2. TIÊU ĐỀ SỰ KIỆN CHO NGÀY ĐƯỢC CHỌN
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
            child: Text(
              // ⭐️ SỬA ĐỔI: Luôn hiển thị ngày được chọn
              'Sự kiện (${DateFormat('dd/MM/yyyy').format(_selectedDay)})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : primaryColor,
              ),
            ),
          ),
          
          // 3. DANH SÁCH SỰ KIỆN (ValueListenableBuilder để cập nhật tự động)
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
                    return _buildEventTile(context, value[index], primaryColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET BUILD LỊCH
  Widget _buildCalendarWidget(bool isDark, Color primaryColor, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
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
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        
        // ⭐️ Cấu hình HeaderStyle
        headerStyle: HeaderStyle(
          formatButtonVisible: true, // Cho phép chuyển đổi Week/Month
          formatButtonDecoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.0),
          ),
          formatButtonTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        
        // Cấu hình Calendar Style
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
                    color: primaryColor, 
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

  // WIDGET HIỂN THỊ TỪNG SỰ KIỆN
  Widget _buildEventTile(BuildContext context, String event, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          // ⭐️ Bỏ border để gọn gàng hơn
        ),
        child: ListTile(
          leading: Icon(Icons.assignment_turned_in_rounded, color: primaryColor),
          title: Text(
            event,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87
            ),
          ),
          // Bỏ subtitle để gọn gàng hơn
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            // TODO: Logic xem chi tiết sự kiện
          },
        ),
      ),
    );
  }
  
  // WIDGET PLACEHOLDER KHÔNG CÓ SỰ KIỆN
  Widget _buildNoEventPlaceholder(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 60, color: isDark ? Colors.greenAccent : Colors.green),
            const SizedBox(height: 10),
            Text(
              // ⭐️ SỬA ĐỔI: Thông báo rõ ràng hơn
              'Tuyệt vời! Không có nhiệm vụ nào trong ngày ${_selectedDay.day}/${_selectedDay.month}!',
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