// routes/authRoutes.js

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken'); // ⭐️ Cần thư viện JWT để tạo Token

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
// ⭐️ API ĐĂNG NHẬP (Chỉ phục vụ Admin Hardcode)
// -------------------------------------------------------------
// @route   POST /api/auth/login
// @desc    Đăng nhập Admin cố định
// @access  Public
router.post('/login', (req, res) => {
    const { email, password } = req.body;

    // 1. Kiểm tra thiếu trường dữ liệu
    if (!email || !password) {
        return res.status(400).json({ error: 'Vui lòng cung cấp email và mật khẩu.' });
    }

    // 2. ⭐️ KIỂM TRA TÀI KHOẢN ADMIN CỐ ĐỊNH
    if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
        const adminId = 'admin_tdtu_id_001';
        const token = generateToken(adminId, 'admin', ADMIN_TOKEN_SECRET);

        // Đăng nhập thành công
        return res.status(200).json({
            success: true,
            message: 'Đăng nhập Admin thành công.',
            user: {
                id: adminId,
                name: 'Admin TDTU',
                email: ADMIN_EMAIL,
                role: 'admin', 
            },
            token: token,
        });
    }

    // 3. Đăng nhập thất bại (Nếu không phải admin hardcode)
    res.status(401).json({ error: 'Thông tin đăng nhập không hợp lệ.' });
});

// -------------------------------------------------------------
// ❌ API ĐĂNG KÝ (Loại bỏ theo yêu cầu của bạn)
// -------------------------------------------------------------
// @route   POST /api/auth/register
// @desc    API đăng ký đã bị loại bỏ/vô hiệu hóa.
// @access  N/A
router.post('/register', (req, res) => {
    res.status(405).json({ error: 'Đăng ký người dùng mới đã bị vô hiệu hóa trên server.' });
});

module.exports = router;