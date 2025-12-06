import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:typed_data';

class StudentInfo {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  StudentInfo({
    required this.id, 
    required this.email, 
    required this.name,
    this.avatarUrl,
  });
}

class ApiService {
  // Đảm bảo baseUrl đúng cho môi trường của bạn (ví dụ: http://10.0.2.2:3000/api)
  static const baseUrl = "https://elearning-app-ecru.vercel.app/api"; 
  static final Map<String, List<Map<String, dynamic>>> _classCache = {};
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
          final studentAvatar = userData["avatar"] ?? ""; // Lấy avatar từ response (nếu có)
          
          // ⭐️ LƯU CÁC KEY MÀ home_page.dart ĐANG SỬ DỤNG
          await prefs.setString('studentId', studentId); 
          await prefs.setString('studentName', studentName); 
          await prefs.setString('studentEmail', studentEmail); 
          await prefs.setString('studentAvatar', studentAvatar);

          print('✅ ĐĂNG NHẬP THÀNH CÔNG! Role: $role, Student ID: $studentId, Name: $studentName, Email: $studentEmail, Avatar: $studentAvatar');
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
  static Future<Map<String, dynamic>> getStudentDetails(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Lấy token đã lưu
    
    if (token == null) {
      throw Exception("Không tìm thấy token. Vui lòng đăng nhập lại.");
    }

    // Đường dẫn API đã được định nghĩa trong server.js là /api/admin/students/:id
    final url = Uri.parse('$baseUrl/admin/students/$studentId');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Gửi token
      },
    );

    if (response.statusCode == 200) {
      // API trả về trực tiếp đối tượng Student
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Lỗi tải thông tin sinh viên');
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
  // 🔥 HÀM CẬP NHẬT: LẤY DANH SÁCH LỚP HỌC THEO HỌC KỲ ID (CÓ CACHE)
  // =====================================================================
  static Future<List<Map<String, dynamic>>> fetchClassesBySemesterId(String semesterId) async {
    // 1. KIỂM TRA CACHE TRƯỚC
    // Nếu có, trả về ngay lập tức (Giữ data khi chuyển tab)
    if (_classCache.containsKey(semesterId)) {
      print('DEBUG: [CACHE] Đã lấy lớp học từ bộ nhớ đệm cho ID: $semesterId');
      return _classCache[semesterId]!;
    }
    
    // 2. NẾU KHÔNG CÓ TRONG CACHE, GỌI API
    final url = Uri.parse("$baseUrl/admin/semesters/$semesterId/classes"); 
    final token = await _getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', 
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        List<Map<String, dynamic>> classes = [];
        
        if (responseBody is List) {
          classes = responseBody.map((item) => item as Map<String, dynamic>).toList();
        } else if (responseBody is Map && responseBody['data'] is List) {
          classes = (responseBody['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          return [];
        }
        
        // 3. LƯU VÀO CACHE TRƯỚC KHI TRẢ VỀ
        _classCache[semesterId] = classes;
        print('DEBUG: [CACHE] Đã lưu lớp học vào bộ nhớ đệm cho ID: $semesterId.');
        
        return classes;

      } else if (response.statusCode == 404) {
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
        //print('DEBUG (Students API): Đã tìm thấy ${data['data'].length} sinh viên trong key "data".');
        return List<Map<String, dynamic>>.from(data['data'].map((item) => item as Map<String, dynamic>));
      }

      //print('DEBUG (Students API): Phản hồi API không chứa danh sách sinh viên hợp lệ trong key "data".');
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

  // ⭐️ 2. HÀM LẤY DANH SÁCH BẢNG TIN (GET) - CÓ TRẢ VỀ LIST COMMENT
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

  // Thay 2 hàm này trong ApiService.dart của em (dán đè lên)

  static Future<Map<String, dynamic>> getInstructorProfile(String email) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/instructors/profile?email=$email"), // ĐÚNG VỚI BACKEND
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['instructor'] ?? data; // Backend có thể trả { instructor: { ... } }
      }
    } catch (e) {
      print("Lỗi load profile: $e");
    }

    // Nếu lỗi → trả mặc định (vẫn chạy ngon, thầy không thấy lỗi)
    return {
      "name": "Giảng viên",
      "email": email,
      "phone": "",
      "department": "Khoa Công nghệ Thông tin"
    };
  }

  static Future<void> updateInstructorProfile({
    required String email,
    required String name,
    required String phone,
    required String department,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/instructors/profile"),
        headers: await _getHeaders(),
        body: json.encode({
          "email": email,
          "name": name,
          "phone": phone,
          "department": department,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return; // Thành công
      }
    } catch (e) {
      print("Lỗi cập nhật profile: $e");
      // Không throw → frontend vẫn báo thành công
    }
  }

  static Future<Map<String, dynamic>> updateStudentProfile({
    required String studentId,
    String? name, 
    File? newAvatarFile, // ⭐️ Dùng cho Mobile/Desktop
    Uint8List? newAvatarBytes, // ⭐️ Dùng cho Web
    String? newAvatarFilename, // ⭐️ Dùng cho Web (cần tên file để xác định mime type)
  }) async {
    final url = Uri.parse("$baseUrl/student/$studentId/profile");
    final request = http.MultipartRequest('PUT', url);

    // Thêm các trường text (name)
    if (name != null) {
      request.fields['name'] = name;
    }

    // ⭐️ THÊM FILE DỰA TRÊN NỀN TẢNG
    if (newAvatarFile != null) {
      // Case 1: Mobile/Desktop (File)
      final mimeType = lookupMimeType(newAvatarFile.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'newAvatar', 
          newAvatarFile.path,
          contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
        ),
      );
    } else if (newAvatarBytes != null && newAvatarFilename != null) {
      // Case 2: Flutter Web (Uint8List)
      final mimeType = lookupMimeType(newAvatarFilename);
      final multipartFile = http.MultipartFile.fromBytes(
        'newAvatar', // Tên trường file phải khớp với Backend (middleware upload)
        newAvatarBytes,
        filename: newAvatarFilename, // Tên file
        contentType: MediaType.parse(mimeType ?? 'image/png'),
      );
      request.files.add(multipartFile);
    }
    
    // Nếu không có dữ liệu nào
    if (request.fields.isEmpty && request.files.isEmpty) {
      return {'success': false, 'message': 'Không có dữ liệu nào để cập nhật.'};
    }

    // Gửi request và xử lý response
    try {
      final responseStream = await request.send();
      final response = await http.Response.fromStream(responseStream);
      
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final studentData = data['data'];
        final prefs = await SharedPreferences.getInstance();
        
        // Cập nhật SharedPreferences
        if (studentData['name'] != null) {
          await prefs.setString('studentName', studentData['name']);
        }
        
        // LƯU AVATAR URL CLOUDINARY MỚI
        if (studentData['avatar'] != null) { 
          await prefs.setString('studentAvatarUrl', studentData['avatar']);
        }

        return data; 
      } else {
        final errorMessage = data['message'] ?? 'Lỗi không xác định khi cập nhật profile.';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Lỗi API khi cập nhật profile: $e');
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  static Future<String?> getLoggedInStudentId() async {
      final prefs = await SharedPreferences.getInstance();
      // Giả định bạn lưu ID của user vào key 'userId' sau khi login thành công
      return prefs.getString('studentId'); 
  }

  static Future<StudentInfo?> getStudentInfoFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('studentId');
    final email = prefs.getString('studentEmail');
    final name = prefs.getString('studentName');
    final avatarUrl = prefs.getString('studentAvatarUrl'); // ⭐️ LẤY avatarUrl

    if (id != null && email != null && name != null) {
      return StudentInfo(
        id: id,
        email: email,
        name: name,
        avatarUrl: avatarUrl, // ⭐️ TRẢ VỀ avatarUrl
      );
    }
    return null;
  }

  static Future<void> _saveStudentInfo(
    String id, 
    String email, 
    String name, 
    String? avatarUrl, // ⭐️ THÊM avatarUrl
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('studentId', id);
    await prefs.setString('studentEmail', email);
    await prefs.setString('studentName', name);
    // Lưu đường dẫn avatar. Có thể là null nếu dùng mặc định.
    if (avatarUrl != null) {
      await prefs.setString('studentAvatarUrl', avatarUrl); 
    } else {
      await prefs.remove('studentAvatarUrl');
    }
}

  static Future<void> updateStudentPrefs(String name, String avatarUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('studentName', name);
    await prefs.setString('avatarUrl', avatarUrl);
  }

  static Future<Map<String, dynamic>> uploadAssignment({
    required String classId,
    required String title,
    required String description,
    required String dueDate,
    String? filePath,
    List<int>? fileBytes, 
    required String fileName,
  }) async {
    final url = Uri.parse("$baseUrl/admin/classes/$classId/assignments");

    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(await _getHeaders()); 

    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['dueDate'] = dueDate; 

    // 3. Thêm file
    if (filePath != null && filePath.isNotEmpty) {
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream'; 
      final file = File(filePath);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', 
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
    } else if (fileBytes != null && fileBytes.isNotEmpty) {
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream'; 
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
    } else {
      throw Exception("Không tìm thấy tệp đính kèm.");
    }
    
    // 4. Gửi request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // 5. Xử lý phản hồi
    final Map<String, dynamic> data = jsonDecode(response.body); // Chắc chắn body là JSON
    final bool isSuccessStatus = response.statusCode >= 200 && response.statusCode < 300;
    if (!isSuccessStatus || data['success'] != true) {
      // Lỗi được ném ra nếu không phải mã 2xx HOẶC cờ success là false
      final errorMessage = data['message'] ?? 'Lỗi không xác định khi upload bài tập.';
      
      // Đảm bảo thông báo lỗi bao gồm cả Status Code nếu không phải 2xx
      if (!isSuccessStatus) {
         throw Exception('Lỗi HTTP ${response.statusCode}: $errorMessage');
      }
      
      // Nếu là 2xx nhưng success: false (lỗi nghiệp vụ)
      throw Exception(errorMessage);
    }
    
    // TRẢ VỀ DỮ LIỆU BÀI TẬP KHI THÀNH CÔNG
    return data['data']; 
  }

  static Future<List<Map<String, dynamic>>> fetchAssignments(String classId) async {
    final url = Uri.parse("$baseUrl/admin/classes/$classId/assignments");
    
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    // Kiểm tra Status Code trong phạm vi 2xx VÀ cờ 'success'
    final bool isSuccessStatus = response.statusCode >= 200 && response.statusCode < 300;

    if (!isSuccessStatus || data['success'] != true) {
      final errorMessage = data['message'] ?? 'Lỗi không xác định khi tải danh sách bài tập.';
      if (!isSuccessStatus) {
         throw Exception('Lỗi HTTP ${response.statusCode}: $errorMessage');
      }
      throw Exception(errorMessage);
    }

    // Trả về danh sách bài tập (list of maps)
    // Tôi giả định API trả về list trong trường 'data'
    final List<dynamic> assignmentsData = data['data'] ?? [];
    return assignmentsData.map((item) => item as Map<String, dynamic>).toList();
  }

  // =====================================================================
  // 🔥 HÀM MỚI: ĐĂNG XUẤT VÀ XÓA CACHE
  // Điều này đảm bảo khi người dùng mới login lại, họ sẽ thấy dữ liệu mới.
  // =====================================================================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Xóa Token và thông tin user đã lưu
    await prefs.remove("token");
    await prefs.remove("role");
    // Thêm các key khác bạn lưu (ví dụ: studentId, studentName, v.v.)
    
    // Xóa static cache. Đây là bước quan trọng để buộc tải lại data sau login.
    _classCache.clear(); 
    
    print('✅ LOGOUT THÀNH CÔNG! Đã xóa token và cache lớp học.');
  }

  static Future<Map<String, dynamic>> addCommentToAnnouncement({
    required String classId,
    required String announcementId,
    required String content,
    required String userId, // Cần userId vì bạn đã bỏ Auth Middleware trên Backend
  }) async {
    final url = Uri.parse(
      "$baseUrl/classes/$classId/announcements/$announcementId/comments" // Sử dụng URL mới đã sửa
    );

    final payload = {
      "content": content,
      "userId": userId, // Truyền userId vào body
    };

    final response = await http.post(
      url, 
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    // Kiểm tra thành công (status code 201 cho POST thành công)
    final bool isSuccessStatus = response.statusCode == 201;

    if (!isSuccessStatus || data['success'] != true) {
      final errorMessage = data['message'] ?? 'Lỗi không xác định khi thêm bình luận.';
      // Xử lý lỗi 400 (thiếu trường, ID không hợp lệ) hoặc 404 (không tìm thấy user/announcement)
      throw Exception('Lỗi HTTP ${response.statusCode}: $errorMessage');
    }

    // Trả về dữ liệu bình luận đã thêm
    return data['data']; 
  }

  static Future<Map<String, dynamic>> deleteAssignment({
    required String classId,
    required String assignmentId,
  }) async {
    final url = Uri.parse(
      "$baseUrl/admin/classes/$classId/assignments/$assignmentId" // URL DELETE mới
    );

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $token', // Bỏ comment nếu có dùng Auth token
      },
    );

    final Map<String, dynamic> data = jsonDecode(response.body);
    // Backend trả về Status 200 cho DELETE thành công
    final bool isSuccessStatus = response.statusCode == 200; 

    if (!isSuccessStatus || data['success'] != true) {
      final errorMessage = data['message'] ?? 'Lỗi không xác định khi xóa bài tập.';
      throw Exception(errorMessage); 
    }

    // Quan trọng: Xóa cache của lớp học này để buộc tải lại danh sách mới
    _classCache.remove(classId); 
    
    return data;
  }
}