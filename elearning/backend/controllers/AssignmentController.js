// controllers/AssignmentController.js

const Assignment = require('../models/Assignment'); // Đảm bảo đã import Assignment Model
const Class = require('../models/Class'); 
const mongoose = require('mongoose');

// =========================================================================
// HÀM TẠO BÀI TẬP MỚI (POST /api/admin/classes/:classId/assignments)
// =========================================================================
exports.createAssignment = async (req, res) => {
    // Multer đã chạy xong, thông tin file nằm trong req.file
    // Các trường dữ liệu khác nằm trong req.body

    try {
        const { classId } = req.params;
        const { title, description, dueDate } = req.body;
        
        // 1. Kiểm tra lớp học tồn tại
        const existingClass = await Class.findById(classId);

        if (!existingClass) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy lớp học.' });
        }

        // 2. Lấy thông tin file đã upload (từ Multer)
        let fileData = {};
        if (req.file) {
            fileData = {
                originalFileName: req.file.originalname,
                savedFileName: req.file.filename,
                // Đường dẫn file lưu trữ công khai
                fileUrl: `/uploads/assignments/${req.file.filename}` 
            };
        } else if (!title || !description || !dueDate) {
             // Nếu không có file, phải có đủ title, description, dueDate
             return res.status(400).json({ success: false, message: 'Vui lòng nhập đầy đủ Tiêu đề, Mô tả và Hạn nộp.' });
        }

        // 3. Tạo bài tập mới
        const newAssignment = await Assignment.create({
            class: classId,
            title,
            description,
            dueDate,
            file: fileData // Lưu thông tin file (có thể là object rỗng nếu không có file)
        });

        // 4. Cập nhật mảng assignments trong Class model (Tùy chọn: nếu bạn muốn Class có mảng ref tới Assignment)
        // existingClass.assignments.push(newAssignment._id);
        // await existingClass.save();

        res.status(201).json({
            success: true,
            message: 'Đã tạo bài tập thành công.',
            data: newAssignment
        });

    } catch (error) {
        // Nếu Multer gặp lỗi (ví dụ: kích thước file quá lớn, loại file không hợp lệ), lỗi sẽ ở đây
        if (error.code === 'LIMIT_FILE_SIZE') {
             return res.status(400).json({ success: false, message: 'Kích thước file quá lớn. Tối đa 10MB.' });
        }
        
        console.error("Lỗi khi tạo bài tập:", error.message);
        res.status(500).json({
            success: false,
            message: error.message || 'Lỗi server khi tạo bài tập.'
        });
    }
};

// ... (Hàm getAssignmentsByClass sẽ ở bên dưới)

// =========================================================================
// HÀM 2: LẤY DANH SÁCH BÀI TẬP CỦA MỘT LỚP (GET)
// =========================================================================
exports.getAssignmentsByClass = async (req, res) => {
    const { classId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(classId)) {
        return res.status(400).json({ message: 'ID lớp học không hợp lệ.' });
    }

    try {
        // Tìm tất cả bài tập có class ID tương ứng và sắp xếp theo thời gian tạo
        const assignments = await Assignment.find({ class: classId })
                                            .sort({ uploadedAt: -1 });

        res.status(200).json({
            success: true,
            count: assignments.length,
            data: assignments,
        });
        
    } catch (error) {
        res.status(500).json({ message: error.message || 'Lỗi server khi lấy danh sách bài tập.' });
    }
};