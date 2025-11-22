// routes/classRoutes.js
const express = require('express');
const router = express.Router();
const Class = require('../models/Class');

// =========================================================================
// 1. API TẠO LỚP HỌC (POST /api/admin/classes/create)
// =========================================================================
router.post('/create', async (req, res) => {
    try {
        // Lấy dữ liệu từ body request
        const { name, section, room, subject } = req.body;

        // Tạo đối tượng lớp học mới
        const newClass = await Class.create({
            name,
            section,
            room,
            subject,
        });

        // Trả về đối tượng đã tạo thành công
        res.status(201).json({
            success: true,
            message: 'Lớp học đã được tạo thành công.',
            class: newClass
        });

    } catch (error) {
        console.error(error);
        // Xử lý lỗi validation hoặc lỗi server
        res.status(500).json({
            success: false,
            message: error.message || 'Lỗi server khi tạo lớp học.'
        });
    }
});

// =========================================================================
// 2. API LẤY TẤT CẢ LỚP HỌC (GET /api/admin/classes) - ĐÃ SỬA
// =========================================================================
// @route   GET /api/classes
// @desc    Lấy tất cả lớp học
// @access  Public
router.get('/', async (req, res) => {
    try {
        // ⭐️ SỬA ĐỔI: Sử dụng find() mà không có populate
        // Thêm .sort({ createdAt: -1 }) để lấy lớp mới nhất trước
        const classes = await Class.find().sort({ createdAt: -1 });

        // Trả về danh sách lớp học
        res.status(200).json({
            success: true,
            count: classes.length,
            data: classes
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Lỗi server khi lấy danh sách lớp học.'
        });
    }
});

// =========================================================================
// 3. ⭐️ API XÓA LỚP HỌC CỤ THỂ (DELETE /api/classes/:id)
// =========================================================================
// @route   DELETE /api/classes/:id
// @desc    Xóa một lớp học dựa trên ID
// @access  Private (Cần Token Admin/Giảng viên)
router.delete('/delete/:id', async (req, res) => {
    try {
        const classId = req.params.id;

        // Tìm và xóa lớp học theo ID
        // findByIdAndDelete là phương thức Mongoose tối ưu để xóa
        const classToDelete = await Class.findByIdAndDelete(classId);

        if (!classToDelete) {
            // Không tìm thấy lớp học
            return res.status(404).json({
                success: false,
                message: 'Không tìm thấy lớp học với ID này.'
            });
        }

        // Trả về kết quả thành công
        res.status(200).json({
            success: true,
            message: `Lớp học với ID ${classId} đã xóa thành công.`
        });

    } catch (error) {
        console.error(error);
        // Xử lý lỗi server (ví dụ: ID không đúng định dạng MongoDB)
        res.status(500).json({
            success: false,
            message: error.message || 'Lỗi server khi xóa lớp học.'
        });
    }
});

module.exports = router;