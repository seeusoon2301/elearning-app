// routes/classRoutes.js
const express = require('express');
const router = express.Router();
const Class = require('../models/Class');
const Semester = require('../models/Semester');
const { getStudentsInClass } = require('../controllers/classController');
const { createAnnouncement, getAnnouncementsByClass } = require('../controllers/AnnouncementController');

const uploadAssignmentFile = require('../middleware/upload');
const { createAssignment, getAssignmentsByClass } = require('../controllers/AssignmentController');
// =========================================================================
// 1. API TẠO LỚP HỌC (POST /api/admin/classes/create)
// =========================================================================
router.post('/create', async (req, res) => {
    try {
        // 🔑 Bổ sung semesterId từ body request
        const { name, instructor, room, subject, semesterId } = req.body; 

        // 1. Kiểm tra xem semesterId có hợp lệ và tồn tại không
        if (!semesterId) {
            return res.status(400).json({ success: false, message: 'semesterId là bắt buộc.' });
        }
        
        const semester = await Semester.findById(semesterId);
        if (!semester) {
            return res.status(404).json({ success: false, message: 'Học kỳ không tồn tại.' });
        }

        // 2. Tạo đối tượng lớp học mới và liên kết với Học kỳ
        const newClass = await Class.create({
            name,
            instructor,
            room,
            subject,
            // 🔑 Lưu ID học kỳ vào trường tham chiếu
            semester: semesterId, 
        });

        // 3. Cập nhật Semester (Liên kết ngược)
        // Đẩy ID lớp học mới vào mảng classes của Học kỳ
        semester.classes.push(newClass._id);
        await semester.save();

        // 4. Trả về đối tượng đã tạo thành công
        res.status(201).json({
            success: true,
            message: 'Lớp học đã được tạo và liên kết thành công.',
            class: newClass
        });

    } catch (error) {
        console.error(error);
        // Xử lý lỗi validation hoặc lỗi server
        // Nếu lỗi là do Mongoose Schema validation (ví dụ: semesterId sai format), error.message sẽ hiển thị
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

// --- LOGIC MỜI SINH VIÊN (Tích hợp Controller) ---
const { inviteStudent } = require('../controllers/inviteStudentController');

// =========================================================================
// 4. API MỜI SINH VIÊN VÀO LỚP HỌC (POST /api/admin/classes/:classId/invite)
// =========================================================================
router.post('/:classId/invite', inviteStudent);

// =========================================================================
// 5. API LẤY DANH SÁCH SINH VIÊN TRONG LỚP (GET /api/admin/classes/:classId/students) (MỚI)
// =========================================================================
router.get('/:classId/students', getStudentsInClass);



// =========================================================================
// ⭐️ API ĐĂNG BẢNG TIN (ANNOUNCEMENTS) (MỚI)
// =========================================================================
// Đảm bảo bạn đã import { createAnnouncement, getAnnouncementsByClass } ở đầu file
// Endpoint: /api/classes/:classId/announcements

// POST /api/admin/classes/:classId/announcements - Tạo bảng tin
router.post('/:classId/announcements', createAnnouncement);

// GET /api/admin/classes/:classId/announcements - Lấy danh sách bảng tin
router.get('/:classId/announcements', getAnnouncementsByClass);

// POST /api/admin/classes/:classId/assignments - Tạo bài tập mới
router.post(
    '/:classId/assignments', 
    uploadAssignmentFile, // ⭐️ MIDDLEWARE XỬ LÝ UPLOAD FILE
    createAssignment // Controller sẽ chạy SAU khi file đã được upload
);

// GET /api/admin/classes/:classId/assignments - Lấy danh sách bài tập của một lớp
router.get('/:classId/assignments', getAssignmentsByClass);
module.exports = router;