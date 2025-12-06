// lib/managers/student_info_manager.dart

import 'package:shared_preferences/shared_preferences.dart';
// ⚠️ Cần import ApiService, giả sử nó ở thư mục 'services'
import '../services/api_service.dart'; 

class StudentInfoManager {
  // Biến tĩnh để lưu trữ dữ liệu đã tải một lần
  static String? studentId;
  static String? studentName;
  static String? studentEmail;
  static String? studentAvatarUrl;
  
  // Biến này có thể dùng để kiểm tra xem đã load dữ liệu lần đầu chưa
  // static bool _isLoaded = false; // Đã bỏ

  /// Tải thông tin sinh viên từ SharedPreferences (để lấy ID) và sau đó từ API.
  static Future<void> loadStudentInfo({String? overrideId}) async {
        final prefs = await SharedPreferences.getInstance();
        
        // 1. Lấy ID sinh viên đã lưu từ lúc đăng nhập
        // ⭐ ƯU TIÊN ID ĐƯỢC TRUYỀN VÀO (từ màn hình Login), nếu không có mới dùng SharedPreferences
        final idToUse = overrideId ?? prefs.getString('studentId'); 

        if (idToUse == null) {
            print('❌ StudentInfoManager: Không tìm thấy Student ID. Không thể gọi API.');
            return; 
        }

        // Cập nhật biến tĩnh studentId với giá trị đã tìm được
        studentId = idToUse;
        
        // 2. Gọi API để lấy thông tin chi tiết mới nhất
        try {
            // ... (phần code gọi API và lưu vào biến tĩnh giữ nguyên)
            final studentData = await ApiService.getStudentDetails(studentId!); 
            
            // 3. Cập nhật các biến tĩnh với dữ liệu MỚI TỪ API
            studentName = studentData['name'] as String?;
            studentEmail = studentData['email'] as String?;
            studentAvatarUrl = studentData['avatar'] as String?;

            // 4. Cập nhật lại SharedPreferences 
            if (studentName != null) await prefs.setString('studentName', studentName!);
            if (studentEmail != null) await prefs.setString('userEmail', studentEmail!);
            
            if (studentAvatarUrl != null && studentAvatarUrl!.isNotEmpty) {
              await prefs.setString('studentAvatarUrl', studentAvatarUrl!);
            } else {
              await prefs.remove('studentAvatarUrl');
            }
            
            print('✅ StudentInfoManager Loaded from API: ID: $studentId, Name: $studentName, Email: $studentEmail, AvatarUrl: $studentAvatarUrl');
            
        } catch (e) {
            print('❌ Lỗi khi tải thông tin chi tiết sinh viên từ API ($e). Tải dữ liệu dự phòng từ SharedPreferences.');
            // ... (phần code tải dữ liệu dự phòng giữ nguyên)
        }
    }

  /// Xóa dữ liệu khi đăng xuất
  static void clearStudentInfo() {
    studentId = null;
    studentName = null;
    studentEmail = null;
    studentAvatarUrl = null;
    // _isLoaded = false; // Đã bỏ
  }
}