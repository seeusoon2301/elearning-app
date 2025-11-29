const mongoose = require('mongoose');

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
    // Tự động thêm timestamp tạo
}, { timestamps: true });

// Tạo Index để tăng hiệu suất truy vấn (query) theo classId
AnnouncementSchema.index({ classId: 1, createdAt: -1 });

module.exports = mongoose.model('Announcement', AnnouncementSchema);