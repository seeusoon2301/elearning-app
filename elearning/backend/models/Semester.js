// models/Semester.js
const mongoose = require('mongoose');

const SemesterSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Tên học kỳ là bắt buộc'],
        trim: true,
    },
    // Mã học kỳ (ví dụ: HK1-2025) — chỉ yêu cầu thêm code khi tạo
    code: {
        type: String,
        required: [true, 'Mã học kỳ là bắt buộc'],
        trim: true,
        unique: true
    },
    // Một học kỳ có nhiều lớp: mảng ObjectId tham chiếu tới model 'Class'
    classes: [
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Class'
        }
    ],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Semester', SemesterSchema);
