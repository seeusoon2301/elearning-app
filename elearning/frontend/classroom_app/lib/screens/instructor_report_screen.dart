// lib/screens/instructor_report_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InstructorReportScreen extends StatelessWidget {
  const InstructorReportScreen({super.key});

  final Color primaryColor = const Color(0xFF00695C); // Màu chủ đạo (Xanh đậm)

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Phân tích', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              // TODO: Logic xuất báo cáo (PDF/Excel)
            },
            tooltip: 'Tải xuống Báo cáo',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CHỈ SỐ TÓM TẮT (Key Performance Indicators)
            const Text(
              'Các chỉ số chính',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildSummaryGrid(isDark),
            const SizedBox(height: 28),

            // 2. BIỂU ĐỒ ĐƯỜNG (Xu hướng GPA)
            _buildSectionTitle('Xu hướng GPA theo tháng', primaryColor, isDark),
            _buildLineChartCard(isDark),
            const SizedBox(height: 28),

            // 3. BIỂU ĐỒ TRÒN (Phân bố điểm)
            _buildSectionTitle('Phân bố Điểm số (Lập trình Di động)', primaryColor, isDark),
            _buildPieChartCard(isDark),
            const SizedBox(height: 28),
            
            // 4. DANH SÁCH BÁO CÁO NHANH
            _buildSectionTitle('Báo cáo nhanh', primaryColor, isDark),
            _buildQuickReportList(isDark),
          ],
        ),
      ),
    );
  }
  
  // Widget tiêu đề phần
  Widget _buildSectionTitle(String title, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  // WIDGET 1: Tổng quan chỉ số (Grid 2 cột)
  Widget _buildSummaryGrid(bool isDark) {
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    // ⭐️ SỬA ĐỔI: Giảm tỷ lệ từ 1.5 xuống 1.1 để thẻ nhỏ lại
    childAspectRatio: 3.0, 
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    children: [
      // ... (giữ nguyên nội dung bên trong)
      _buildSummaryCard('Tổng Lớp', '12', Icons.class_rounded, const Color(0xFF00796B), isDark),
      _buildSummaryCard('Sinh viên', '248', Icons.people_alt_rounded, const Color(0xFF3949AB), isDark),
      _buildSummaryCard('GPA TB', '3.5 / 4.0', Icons.auto_graph_rounded, const Color(0xFFFF8F00), isDark),
      _buildSummaryCard('Tỷ lệ nộp bài', '92%', Icons.done_all_rounded, const Color(0xFFD32F2F), isDark),
    ],
  );
}

  // Widget Từng thẻ Chỉ số
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[800])),
        ],
      ),
    );
  }

  // WIDGET 2: Biểu đồ Đường
  Widget _buildLineChartCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
      ),
      height: 250,
      child: LineChart(
        LineChartData(
          minX: 0, maxX: 5, minY: 2.0, maxY: 4.0,
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 30, getTitlesWidget: (value, meta) {
              const titles = ['T8', 'T9', 'T10', 'T11', 'T12', 'T1'];
              return SideTitleWidget(axisSide: meta.axisSide, child: Text(titles[value.toInt()], style: const TextStyle(fontSize: 12)));
            })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 0.5, reservedSize: 40)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1);
          }),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3.0), FlSpot(1, 3.2), FlSpot(2, 3.5), FlSpot(3, 3.4), FlSpot(4, 3.7), FlSpot(5, 3.9)
              ],
              isCurved: true,
              color: Colors.teal,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true, getDotPainter: _getDotPainter),
              belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.15)),
            ),
          ],
        ),
      ),
    );
  }

  // Custom Dot Painter cho LineChart
  static FlDotPainter _getDotPainter(FlSpot spot, double percent, LineChartBarData barData, int index) {
    final color = barData.color ?? Colors.teal; 
    
    return FlDotCirclePainter(
      radius: 4,
      color: color, 
      strokeWidth: 2,
      strokeColor: Colors.white,
    );
  }

  // WIDGET 3: Biểu đồ Tròn
  Widget _buildPieChartCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
      ),
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 0, // Tăng kích thước biểu đồ tròn
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(color: Colors.green, value: 35, title: '35%', radius: 90, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  PieChartSectionData(color: Colors.blue, value: 45, title: '45%', radius: 90, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  PieChartSectionData(color: Colors.orange, value: 15, title: '15%', radius: 90, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  PieChartSectionData(color: Colors.red, value: 5, title: '5%', radius: 90, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
          // Chú thích (Legend)
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(Colors.green, 'A: Giỏi'),
                  _buildLegendItem(Colors.blue, 'B: Khá'),
                  _buildLegendItem(Colors.orange, 'C: Trung bình'),
                  _buildLegendItem(Colors.red, 'D: Yếu'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
  
  // Widget chú thích
  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(width: 14, height: 14, color: color, margin: const EdgeInsets.only(right: 8)),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  // WIDGET 4: Danh sách Báo cáo Nhanh (Ví dụ)
  Widget _buildQuickReportList(bool isDark) {
    final List<Map<String, dynamic>> quickReports = [
      {'title': 'Danh sách sinh viên nộp trễ', 'icon': Icons.watch_later_rounded, 'color': Colors.redAccent},
      {'title': 'So sánh hiệu suất giữa các lớp', 'icon': Icons.compare_arrows_rounded, 'color': Colors.indigo},
      {'title': 'Tải bảng điểm tổng hợp', 'icon': Icons.file_download_rounded, 'color': Colors.green},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quickReports.length,
      itemBuilder: (context, index) {
        final report = quickReports[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Icon(report['icon'] as IconData, color: report['color'] as Color),
            title: Text(report['title'] as String),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Điều hướng đến chi tiết báo cáo
            },
          ),
        );
      },
    );
  }
}