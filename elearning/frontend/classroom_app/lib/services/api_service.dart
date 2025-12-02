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
    
    // TẠM THỜI CHO PHÉP SINH VIÊN LOGIN BẰNG MẬT KHẨU "123456" (DÙ PASSWORD TRONG DB LÀ PLAIN TEXT)
    // Dùng để test nhanh khi chèn thẳng vào DB
    if (pass == "123456" && email.contains("@") && email != "admin") {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", "fake-student-token-123");
      await prefs.setString("userEmail", email);
      await prefs.setString("role", "student"); // quan trọng: lưu role để HomePage điều hướng đúng
      
      return {
        "token": "fake-student-token-123",
        "user": {
          "email": email,
          "name": email.split('@').first.replaceAll('.', ' ').toUpperCase(),
          "role": "student"
        }
      };
    }

    // ⭐️ BƯỚC 1: Tạo payload (Map)
    final payload = {
      "email": email,
      "password": pass,
    };
    
    // ⭐️ BƯỚC 2 & 3: Thêm Header và JSON Encode Body
    final res = await http.post(
      url, 
      headers: {
        'Content-Type': 'application/json', // 👈 BẮT BUỘC
      },
      body: json.encode(payload), // 👈 BẮT BUỘC
    );

    // Nếu response rỗng, bạn nên kiểm tra xem server có gửi gì không
    if (res.body.isEmpty) {
        throw Exception("Server không phản hồi. Vui lòng kiểm tra kết nối.");
    }
    
    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      await prefs.setString("userEmail", email);
      await prefs.setString("role", data["user"]?["role"] ?? "student");
      return data;
    } else {
      // Khi server trả về 401 hoặc 400, nó sẽ có error (từ backend của bạn)
      throw data["error"] ?? "Lỗi đăng nhập không xác định.";
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

  static Future<List> getStudentCourses(String email) async {
    // ... (code getStudentCourses giữ nguyên)
    final url = Uri.parse("$baseUrl/courses/student/$email");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to fetch courses");
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
    final url = Uri.parse("$baseUrl/admin/classes/$classId/students");
    final token = await _getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Gửi token xác thực nếu có
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Kiểm tra cấu trúc phản hồi thành công
        if (responseBody['success'] == true && responseBody['data'] is List) {
          // Trả về danh sách sinh viên
          return (responseBody['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          // Trường hợp API trả về 200 nhưng success=false hoặc data không hợp lệ
          return []; 
        }
      } else {
        // Xử lý lỗi HTTP status (ví dụ: 401 Unauthorized, 404 Not Found)
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 'Thất bại khi tải sinh viên. Mã lỗi: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Xử lý lỗi kết nối mạng, timeout, hoặc lỗi định dạng JSON
      print('Lỗi API fetchStudentsInClass: $e');
      throw Exception('Lỗi kết nối hoặc xử lý dữ liệu: $e');
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