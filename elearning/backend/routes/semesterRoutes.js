// routes/semesterRoutes.js
const express = require('express');
const router = express.Router();
const Semester = require('../models/Semester');
const ClassModel = require('../models/Class');

// Tạo học kỳ (body: { name, code })
router.post('/', async (req, res) => {
  try {
    const { name, code } = req.body;
    if (!name || !code) return res.status(400).json({ error: 'name và code là bắt buộc' });

    const existing = await Semester.findOne({ code });
    if (existing) return res.status(409).json({ error: 'Mã học kỳ đã tồn tại' });

    const sem = new Semester({ name, code });
    await sem.save();
    res.status(201).json(sem);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Lấy tất cả học kỳ (không populate classes theo mặc định)
router.get('/', async (req, res) => {
  try {
    const list = await Semester.find().sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Lấy 1 học kỳ và populate classes
router.get('/:id', async (req, res) => {
  try {
    // 🔑 Có thể thêm một trường ảo (virtual field) để tính tổng sinh viên ở đây sau này
    const sem = await Semester.findById(req.params.id).populate('classes');
    if (!sem) return res.status(404).json({ error: 'Not found' });
    res.json(sem);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 🔥 API MỚI: Lấy danh sách lớp học theo Semester ID (GET /:semesterId/classes)
// Endpoint này sẽ được Flutter gọi bằng hàm fetchClassesBySemesterId
router.get('/:semesterId/classes', async (req, res) => {
  try {
    const semesterId = req.params.semesterId;
    
    // 1. Kiểm tra Semester có tồn tại không
    const semester = await Semester.findById(semesterId);
    if (!semester) {
      return res.status(404).json({ error: 'Học kỳ không tồn tại.' });
    }

    // 2. 🔥 TRUY VẤN collection CLASS bằng trường 'semester'
    // Điều này đảm bảo chúng ta lấy được lớp 'OKOKO' dù mảng classes trong Semester rỗng.
    const classes = await ClassModel.find({ 
        semester: semesterId 
    });

    // 3. Trả về kết quả
    res.json({ 
        success: true, 
        data: classes 
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
module.exports = router;
