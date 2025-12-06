const express = require('express');
const router = express.Router();
const Student = require('../models/Student');

// ==========================
//  Create Student
// ==========================
router.post('/create', async (req, res) => {
    try {
        const { email, password, mssv, name } = req.body;

        if (!email || !password || !mssv || !name)
            return res.status(400).json({ error: "Missing required fields" });

        const exist = await Student.findOne({ email });
        if (exist) return res.status(400).json({ error: "Email already exists" });

        const student = await Student.create({ email, password, mssv, name });

        res.status(201).json({
            message: "Student created",
            id: student._id
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ==========================
//  Get All Students
// ==========================
router.get('/', async (req, res) => {
    try {
        const students = await Student.find().select('-password');  // Ẩn password

        res.json(students);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ==========================
//  Get Single Student by ID
// ==========================
router.get('/:id', async (req, res) => {
    try {
        const student = await Student.findById(req.params.id).select('-password');

        // 404 nếu không tìm thấy sinh viên
        if (!student) {
            return res.status(404).json({ error: "Student not found" });
        }

        res.json(student);
    } catch (err) {
        // Xử lý lỗi khi ID không hợp lệ (ví dụ: định dạng không đúng của ObjectId)
        if (err.kind === 'ObjectId') {
             return res.status(400).json({ error: "Invalid student ID format" });
        }
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
