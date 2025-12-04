const Student = require('../models/Student');
const mongoose = require('mongoose');

// =========================================================================
// HÀM CẬP NHẬT TÊN SINH VIÊN (PUT /api/student/:studentId/profile)
// =========================================================================
exports.updateStudentProfile = async (req, res) => {
    // Lấy studentId từ URL parameter
    const { studentId } = req.params;
    // Lấy 'name' mới từ body request
    const { name } = req.body; 

    // 1. Kiểm tra tính hợp lệ của ID và Input
    if (!mongoose.Types.ObjectId.isValid(studentId)) {
        return res.status(400).json({ success: false, message: 'ID sinh viên không hợp lệ.' });
    }
    if (!name || name.trim() === '') {
        return res.status(400).json({ success: false, message: 'Tên mới là bắt buộc.' });
    }

    try {
        // 2. Tìm và Cập nhật Student trong Database
        const student = await Student.findByIdAndUpdate(
            studentId,
            { name: name.trim() }, // Chỉ cập nhật trường 'name'
            { 
                new: true, // Trả về document mới sau khi cập nhật
                runValidators: true, // Chạy validation của Mongoose (ví dụ: name là required)
                select: 'mssv name email' // Chỉ trả về các trường cần thiết
            } 
        );

        if (!student) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy thông tin sinh viên.' });
        }

        // 3. Trả về thông tin sinh viên đã cập nhật
        res.status(200).json({
            success: true,
            message: 'Cập nhật tên sinh viên thành công.',
            data: student
        });

    } catch (error) {
        console.error("Lỗi khi cập nhật profile sinh viên:", error);
        res.status(500).json({ success: false, message: 'Lỗi server khi cập nhật profile.' });
    }
};