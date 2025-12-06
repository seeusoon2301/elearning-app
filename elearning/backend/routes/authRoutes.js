const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken'); 
const Student = require('../models/Student'); // ⭐️ BỔ SUNG: Import Student Model

// -------------------------------------------------------------
// ⭐️ THÔNG TIN ADMIN CỐ ĐỊNH VÀ CẤU HÌNH JWT
// -------------------------------------------------------------
const ADMIN_EMAIL = 'admin';
const ADMIN_PASSWORD = 'admin';
const ADMIN_TOKEN_SECRET = 'YOUR_SECRET_KEY_FOR_ADMIN_ENV'; // KHÓA BÍ MẬT JWT

// Hàm tạo Token
const generateToken = (id, role, secret) => {
    return jwt.sign({ id, role }, secret, {
        expiresIn: '30d', 
    });
};

// -------------------------------------------------------------
// ⭐️ API ĐĂNG NHẬP (Phục vụ Admin Cố định VÀ Sinh viên từ DB)
// -------------------------------------------------------------
// @route   POST /api/auth/login
// @desc    Đăng nhập Admin hoặc Sinh viên
// @access  Public
router.post('/login', async (req, res) => { // ⭐️ CHUYỂN THÀNH ASYNC
    const { email, password } = req.body;

    // 1. Kiểm tra thiếu trường dữ liệu
    if (!email || !password) {
        return res.status(400).json({ error: 'Vui lòng cung cấp email và mật khẩu.' });
    }

    // 2. KIỂM TRA TÀI KHOẢN ADMIN CỐ ĐỊNH
    if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
        const adminId = 'admin_tdtu_id_001';
        const token = generateToken(adminId, 'admin', ADMIN_TOKEN_SECRET); // Đặt role là 'instructor'

        return res.status(200).json({
            success: true,
            message: 'Đăng nhập Giảng viên (Admin) thành công.',
            user: {
                id: adminId,
                name: 'Admin TDTU',
                email: ADMIN_EMAIL,
                role: 'admin', 
            },
            token: token,
        });
    }

    // 3. ⭐️ KIỂM TRA TÀI KHOẢN SINH VIÊN TỪ DATABASE
    try {
        // Cần select('+password') vì trường này có select: false trong Schema
        const student = await Student.findOne({ email }).select('+password'); 

        if (student && (await student.matchPassword(password))) {
            // Đăng nhập Sinh viên thành công
            const token = generateToken(student._id, 'student', ADMIN_TOKEN_SECRET);

            return res.status(200).json({
                success: true,
                message: 'Đăng nhập Sinh viên thành công.',
                user: {
                    id: student._id,
                    name: student.name,
                    email: student.email,
                    mssv: student.mssv,
                    avatar: student.avatar, // ⭐️ Thêm avatar vào phản hồi
                    role: 'student',
                },
                token: token,
            });
        }
    } catch (error) {
        console.error('Lỗi khi đăng nhập Sinh viên:', error.message);
        // Bỏ qua lỗi DB và tiếp tục trả về lỗi 401 chung
    }


    // 4. Đăng nhập thất bại (Nếu không phải admin hardcode và không phải student)
    res.status(401).json({ error: 'Thông tin đăng nhập không hợp lệ.' });
});

// -------------------------------------------------------------
// ❌ API ĐĂNG KÝ (Loại bỏ)
// -------------------------------------------------------------
// @route   POST /api/auth/register
// @desc    API đăng ký đã bị loại bỏ/vô hiệu hóa.
// @access  N/A
router.post('/register', (req, res) => {
    res.status(405).json({ error: 'Đăng ký người dùng mới đã bị vô hiệu hóa trên server.' });
});

module.exports = router;