// models/Class.js
const mongoose = require('mongoose');

const ClassSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Tên lớp học là bắt buộc'],
        trim: true,
    },
    instructor: {
        type: String,
        trim: true,
        default: ''
    },
    room: {
        type: String,
        trim: true,
        default: ''
    },
    subject: {
        type: String,
        trim: true,
        default: ''
    },
    semester: { 
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Semester',
        required: [true, 'Lớp học phải thuộc về một học kỳ'], // Bắt buộc
    },
    students: [
        { type: mongoose.Schema.Types.ObjectId, ref: "Student" }
    ],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Class', ClassSchema);