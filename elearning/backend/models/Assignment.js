// models/Assignment.js
const mongoose = require('mongoose');

const AssignmentSchema = new mongoose.Schema({
    // 1. LIÊN KẾT VỚI LỚP HỌC (BẮT BUỘC)
    class: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Class',
        required: [true, 'Bài tập phải thuộc về một lớp học.'],
    },
    
    // 2. THÔNG TIN CHUNG
    title: {
        type: String,
        required: [true, 'Tiêu đề bài tập là bắt buộc.'],
        trim: true,
    },
    description: {
        type: String,
        default: '',
    },
    
    // 3. THÔNG TIN FILE (Metadata)
    // Lưu trữ tên gốc của file và tên file đã được lưu trên server/cloud
    file: {
        // Tên file người dùng upload (ví dụ: 'Baitap_chuong1.pdf')
        originalFileName: {
            type: String,
            trim: true,
            default: '',
        },
        // Tên file đã lưu trên server/S3 (ví dụ: '12345678-baitap.pdf')
        savedFileName: { 
            type: String,
            trim: true,
            default: '',
        },
        // ⭐️ Đường dẫn công khai để sinh viên tải/xem file
        fileUrl: {
            type: String,
            default: '',
        },
        // Loại file (ví dụ: 'application/pdf', 'image/jpeg')
        fileMimeType: {
            type: String,
            default: '',
        },
    },

    // 4. THỜI GIAN
    // Thời hạn nộp (Due Date)
    dueDate: {
        type: Date,
        required: [true, 'Thời hạn nộp là bắt buộc.'],
    },
    // Thời gian tạo (thời gian upload)
    uploadedAt: {
        type: Date,
        default: Date.now,
    },

    // 5. THÔNG TIN BÀI NỘP (SUBMISSIONS)
    // Mảng lưu trữ thông tin về các bài nộp của sinh viên
    submissions: [
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Submission' // Sẽ tạo model Submission sau
        }
    ]
    
}, {
    timestamps: true // Tự động thêm createdAt và updatedAt
});

module.exports = mongoose.model('Assignment', AssignmentSchema);