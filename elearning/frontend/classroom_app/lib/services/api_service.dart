import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Đảm bảo baseUrl đúng cho môi trường của bạn (ví dụ: http://10.0.2.2:3000/api)
  static const baseUrl = "http://localhost:5000/api"; 

  // =====================================================================
  // HÀM AUTHENTICATION (Giữ nguyên)
  // =====================================================================

  static Future<Map<String, dynamic>> login(String email, String pass) async {
    final url = Uri.parse("$baseUrl/auth/login");
    
    final payload = {
      "email": email,
      "password": pass,
    };
    
    final res = await http.post(
      url, 
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    // Xử lý phản hồi rỗng
    if (res.body.isEmpty) {
        throw Exception("Server không phản hồi. Vui lòng kiểm tra kết nối.");
    }
    
    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      final userData = data["user"]; // Lấy object 'user'

      // 1. LƯU THÔNG TIN CHUNG (Áp dụng cho cả Admin và Student)
      await prefs.setString("token", data["token"]);
      
      // Lấy role từ API. Dùng 'student' làm mặc định nếu không có
      final role = userData?["role"] ?? "student"; 
      await prefs.setString("role", role); 

      // 2. LƯU THÔNG TIN ĐẶC THÙ CHO SINH VIÊN (Dành cho home_page)
      if (role == "student" && userData != null) {
          final studentId = userData["id"];
          final studentName = userData["name"];
          final studentEmail = userData["email"]; // Lấy email từ response
          
          // ⭐️ LƯU CÁC KEY MÀ home_page.dart ĐANG SỬ DỤNG
          await prefs.setString('studentId', studentId); 
          await prefs.setString('studentName', studentName); 
          await prefs.setString('studentEmail', studentEmail); 

          print('✅ ĐĂNG NHẬP THÀNH CÔNG! Role: $role, Student ID: $studentId');
      } else if (role == "admin") {
           // Có thể lưu adminId, adminName nếu cần, nhưng hiện tại chỉ cần token và role
           print('✅ ĐĂNG NHẬP THÀNH CÔNG! Role: $role');
      }
      
      return data;
      
    } else {
      // Khi server trả về lỗi (401, 400, v.v.)
      throw Exception(data["error"] ?? data["message"] ?? "Lỗi đăng nhập không xác định.");
    }
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String pass) async {
    // ... (code register giữ nguyên)
    final url = Uri.parse("$baseUrl/auth/register");
    final res = await http.post(url, body: {
      "name": name,
      "email": email,
      "password": pass,
    });

    return jsonDecode(res.body);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token") != null;
  }

  static Future<List> getStudentCourses(String studentId, {String? semesterId}) async {
    final Map<String, dynamic> queryParams = {};
    if (semesterId != null && semesterId.isNotEmpty) {
      // URL query: /student/:id/classes?semesterId=...
      queryParams['semesterId'] = semesterId; 
    }
    
    // Sử dụng .replace để xây dựng URI với query parameters
    final uri = Uri.parse("$baseUrl/student/$studentId/classes").replace(
      queryParameters: queryParams.isNotEmpty 
        ? queryParams.map((key, value) => MapEntry(key, value.toString())) 
        : null
    );
    
    final res = await http.get(uri, headers: await _getHeaders()); // Sử dụng 'uri' đã có params

    if (res.statusCode == 200) {
      // ⭐️ BƯỚC 2: Giải mã JSON (Logic giữ nguyên)
      final responseBody = jsonDecode(res.body);

      // ⭐️ BƯỚC 3: Trích xuất mảng lớp học từ key "data" (Logic giữ nguyên)
      if (responseBody['success'] == true && responseBody['data'] is List) {
        return List<Map<String, dynamic>>.from(
          responseBody['data'].map((item) => item as Map<String, dynamic>)
        );
      } else {
        return [];
      }
      
    } else {
      // ... (xử lý lỗi giữ nguyên)
      final errorData = jsonDecode(res.body);
      final errorMessage = errorData['message'] ?? 'Failed to fetch courses (HTTP ${res.statusCode})';
      throw Exception(errorMessage);
    }
  }

  // =====================================================================
  // HÀM MỚI: TẠO LỚP HỌC (POST /api/admin/classes/create)
  // =====================================================================
  static Future<Map<String, dynamic>> createClass(Map<String, String> classData) async {
    final url = Uri.parse("$baseUrl/admin/classes/create");
    
    final token = await _getToken(); // Lấy token để xác thực (giả định)

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ⭐️ Thêm token nếu backend cần
      },
      body: json.encode(classData), 
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 201) {
      // Trả về đối tượng lớp học đã tạo
      return responseBody['class']; 
    } else {
      final errorMessage = responseBody['message'] ?? 'Lỗi không xác định khi tạo lớp.';
      throw Exception(errorMessage);
    }
  }

  // =====================================================================
  // HÀM MỚI: LẤY TẤT CẢ LỚP HỌC (GET /api/admin/classes)
  // (Giữ nguyên cho mục đích chung, nhưng nên dùng hàm mới bên dưới cho ClassListScreen)
  // =====================================================================
  static Future<List<Map<String, dynamic>>> fetchAllClasses() async {
    final url = Uri.parse("$baseUrl/admin/classes"); 
    
    try {
      final response = await http.get(
        url,
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        // Backend trả về: { success: true, count: X, data: [...] }
        if (responseBody['success'] == true && responseBody['data'] is List) {
          return (responseBody['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          throw Exception('Cấu trúc phản hồi không hợp lệ.');
        }
      } else {
        throw Exception('Thất bại khi tải lớp học. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối hoặc xử lý dữ liệu: $e');
    }
  }
  
  // =====================================================================
  // 🔥 HÀM MỚI QUAN TRỌNG: LẤY DANH SÁCH LỚP HỌC THEO HỌC KỲ ID
  // Endpoint giả định: GET /api/admin/semesters/:semesterId/classes
  // =====================================================================
  static Future<List<Map<String, dynamic>>> fetchClassesBySemesterId(String semesterId) async {
    // Cập nhật endpoint phù hợp với backend của bạn. Tôi dùng path param.
    final url = Uri.parse("$baseUrl/admin/semesters/$semesterId/classes"); 
    final token = await _getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Cần token để xác thực giảng viên
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        // Giả định backend trả về trực tiếp List hoặc { data: List }
        if (responseBody is List) {
          return responseBody.map((item) => item as Map<String, dynamic>).toList();
        }
        
        if (responseBody is Map && responseBody['data'] is List) {
          return (responseBody['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } 
        
        // Xử lý trường hợp không có lớp học (trả về list rỗng)
        return [];

      } else if (response.statusCode == 404) {
        // Có thể server trả 404 nếu không tìm thấy học kỳ, nhưng thường trả 200 với list rỗng
        return [];
      } else {
        final responseBody = json.decode(response.body);
        final errorMessage = responseBody['message'] ?? 'Thất bại khi tải lớp học theo học kỳ. Mã lỗi: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Lỗi kết nối hoặc xử lý dữ liệu: $e');
    }
  }

  // =====================================================================
  // HÀM XÓA LỚP HỌC MỚI (DELETE /api/admin/classes/:id)
  // =====================================================================
  static Future<void> deleteClass(String classId) async {
    // Endpoint: DELETE /api/admin/classes/delete/:id
    final url = Uri.parse("$baseUrl/admin/classes/delete/$classId"); 
    final token = await _getToken();

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token', // Gửi token để xác thực
      },
    );
    
    // Server trả về 200 OK nếu xóa thành công
    if (response.statusCode == 200) {
      // Xóa thành công
      return; 
    } else if (response.statusCode == 404) {
      // Lớp học không tìm thấy
      throw Exception("Không tìm thấy lớp học để xóa.");
    } else {
      // Các lỗi khác (401 Unauthorized, 500 Internal Server Error)
      final responseBody = json.decode(response.body);
      final errorMessage = responseBody['message'] ?? 'Lỗi không xác định khi xóa lớp.';
      throw Exception(errorMessage);
    }
  }

  // =====================================================================
  // HÀM MỚI: TẠO HỌC KỲ (POST /api/admin/semesters)
  // =====================================================================
  static Future<Map<String, dynamic>> createSemester(String name, String code) async {
    final url = Uri.parse("$baseUrl/admin/semesters");

    final token = await _getToken();

    final payload = {
      'name': name,
      'code': code,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );

    if (response.body.isEmpty) {
      throw Exception('Server không phản hồi.');
    }

    final responseBody = json.decode(response.body);

    if (response.statusCode == 201) {
      return responseBody; // backend trả về object semester
    } else {
      final message = responseBody['error'] ?? responseBody['message'] ?? 'Lỗi khi tạo học kỳ.';
      throw Exception(message);
    }
  }

  // =====================================================================
  // HÀM MỚI: LẤY DANH SÁCH HỌC KỲ (GET /api/admin/semesters)
  // =====================================================================
  static Future<List<Map<String, dynamic>>> fetchSemesters() async {
    final url = Uri.parse("$baseUrl/admin/semesters");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
        // nếu backend trả về object { success: ..., data: [...] }
        if (data is Map && data['data'] is List) {
          return (data['data'] as List).map((e) => e as Map<String, dynamic>).toList();
        }
        throw Exception('Cấu trúc phản hồi không hợp lệ khi lấy học kỳ.');
      } else {
        throw Exception('Thất bại khi tải học kỳ. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối hoặc xử lý dữ liệu: $e');
    }
  }
  
  static Future<void> inviteStudent(String classId, String email) async {
    final url = Uri.parse("$baseUrl/admin/classes/$classId/invite");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(data["error"] ?? "Không thể mời học viên.");
    }
  }

  // =====================================================================
  // HÀM MỚI: LẤY DANH SÁCH SINH VIÊN TRONG LỚP HỌC
  // GET /api/admin/classes/students/:classId
  // =====================================================================
  static Future<List<Map<String, dynamic>>> fetchStudentsInClass(String classId) async {
    // Thay đổi endpoint nếu cần thiết, tôi giả định là /api/admin/classes/:classId/students
    final url = Uri.parse("$baseUrl/admin/classes/$classId/students"); 
    
    final res = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      
      // ⭐️ FIX LỖI: Kiểm tra key 'data' theo cấu trúc backend đã cung cấp
      if (data['data'] is List) {
        print('DEBUG (Students API): Đã tìm thấy ${data['data'].length} sinh viên trong key "data".');
        return List<Map<String, dynamic>>.from(data['data'].map((item) => item as Map<String, dynamic>));
      }

      print('DEBUG (Students API): Phản hồi API không chứa danh sách sinh viên hợp lệ trong key "data".');
      return [];
    } else {
      final data = jsonDecode(res.body);
      final errorMessage = data['message'] ?? data['error'] ?? 'Lỗi không xác định khi tải danh sách sinh viên.';
      throw Exception(errorMessage);
    }
  }

  // =====================================================================
  // HÀM HỖ TRỢ LẤY TOKEN
  // =====================================================================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

    // =====================================================================
  // HÀM MỚI: LẤY THÔNG TIN USER HIỆN TẠI (dùng token)
  // Endpoint: GET /api/auth/me hoặc /api/users/me
  // =====================================================================
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Chưa đăng nhập");
    }

    final url = Uri.parse("$baseUrl/auth/me"); // ← Thử endpoint này trước

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend có thể trả về { user: { ... } } hoặc trực tiếp { name: ..., email: ... }
        if (data['user'] != null) {
          return data['user'] as Map<String, dynamic>;
        }
        return data as Map<String, dynamic>;
      } else {
        // Nếu /auth/me lỗi, thử endpoint khác (nhiều backend dùng /users/me)
        final altUrl = Uri.parse("$baseUrl/users/me");
        final altResponse = await http.get(
          altUrl,
          headers: {'Authorization': 'Bearer $token'},
        );
        if (altResponse.statusCode == 200) {
          return jsonDecode(altResponse.body) as Map<String, dynamic>;
        }
        throw Exception("Không thể lấy thông tin người dùng");
      }
    } catch (e) {
      // Nếu cả 2 endpoint đều lỗi → fallback: dùng email đã lưu
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("userEmail") ?? "student@example.com";
      return {
        "name": email.split('@').first,
        "email": email,
      };
    }
  }

 // === HÀM LẤY HEADER CHUẨN – KHÔNG LỖI, DÙNG ĐƯỢC Ở MỌI NƠI ===
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // =====================================================================
  // HÀM ANNOUNCEMENT MỚI
  // =====================================================================

  // ⭐️ 1. HÀM TẠO BẢNG TIN (POST)
  static Future<void> createAnnouncement(String classId, String content) async {
    final url = Uri.parse("$baseUrl/admin/classes/$classId/announcements");
    
    final payload = json.encode({
      "content": content,
    });
    
    final res = await http.post(
      url,
      headers: await _getHeaders(), 
      body: payload,
    );

    if (res.statusCode != 201) { // 201 Created là mã thành công phổ biến cho POST
      final data = jsonDecode(res.body);
      final errorMessage = data['message'] ?? data['error'] ?? 'Lỗi không xác định khi tạo thông báo.';
      throw Exception(errorMessage);
    }
    // Thành công
  }

  // ⭐️ 2. HÀM LẤY DANH SÁCH BẢNG TIN (GET) - ĐÃ FIX LỖI PARSING
  static Future<List<Map<String, dynamic>>> fetchAnnouncementsInClass(String classId) async {
    final url = Uri.parse("$baseUrl/admin/classes/$classId/announcements");
    
    final res = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      
      // ⭐️ FIX LỖI: Kiểm tra key 'data' theo cấu trúc backend đã cung cấp
      if (data['data'] is List) {
        print('DEBUG: Đã tìm thấy ${data['data'].length} bảng tin trong key "data".');
        return List<Map<String, dynamic>>.from(data['data'].map((item) => item as Map<String, dynamic>));
      }
      
      // Giữ lại logic cũ phòng trường hợp backend thay đổi:
      if (data['announcements'] is List) {
        print('DEBUG: Đã tìm thấy ${data['announcements'].length} bảng tin trong key "announcements".');
        return List<Map<String, dynamic>>.from(data['announcements'].map((item) => item as Map<String, dynamic>));
      }

      print('DEBUG: Phản hồi API không chứa danh sách bảng tin hợp lệ trong key "data" hoặc "announcements".');
      return [];
    } else {
      final data = jsonDecode(res.body);
      final errorMessage = data['message'] ?? data['error'] ?? 'Lỗi không xác định khi tải bảng tin.';
      throw Exception(errorMessage);
    }
  }

  static Future<List<dynamic>> getStudentQuizzes({
  required String studentEmail,
  required String semesterName,
}) async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/api/student/quizzes?email=$studentEmail&semester=$semesterName"),
      headers: await _getHeaders(), // ĐÃ SỬA – KHÔNG LỖI NỮA!
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Backend có thể trả về {"quizzes": [...]} hoặc trực tiếp [...]
      return data is List ? data : data['quizzes'] ?? [];
    } else if (response.statusCode == 404) {
      return []; // Không có quiz → trả rỗng, không lỗi
    } else {
      throw Exception("Lỗi server: ${response.statusCode}");
    }
  } catch (e) {
    if (e is http.ClientException || e.toString().contains('Failed host lookup')) {
      throw Exception("Không kết nối được đến server. Vui lòng kiểm tra mạng.");
    }
    throw Exception("Lỗi tải quiz: ${e.toString()}");
  }
}
}