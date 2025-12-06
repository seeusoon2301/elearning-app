const mongoose = require('mongoose');

const CommentSchema = new mongoose.Schema({
    // ID của người bình luận (sinh viên hoặc giảng viên)
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Student', // Giả sử model User chứa cả sinh viên và giảng viên
        required: [true, 'ID người dùng là bắt buộc.'],
    },
    // Nội dung bình luận
    content: {
        type: String,
        required: [true, 'Nội dung bình luận là bắt buộc.'],
        trim: true,
        maxlength: 500, // Giới hạn độ dài bình luận
    },
    // Thời gian bình luận
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

const AnnouncementSchema = new mongoose.Schema({
    // Tham chiếu đến ID của Class mà bảng tin thuộc về (BẮT BUỘC)
    classId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Class', // Giả định tên model Class của bạn là 'Class'
        required: true,
    },
    content: {
        type: String,
        required: [true, 'Nội dung bảng tin không được để trống.'],
        trim: true,
        maxlength: 1000,
    },
    comments: [CommentSchema],
    // Tự động thêm timestamp tạo
}, { timestamps: true });

// Tạo Index để tăng hiệu suất truy vấn (query) theo classId
AnnouncementSchema.index({ classId: 1, createdAt: -1 });

module.exports = mongoose.model('Announcement', AnnouncementSchema);