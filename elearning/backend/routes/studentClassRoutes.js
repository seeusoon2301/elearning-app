// routes/studentClassRoutes.js
const express = require('express');
const router = express.Router();
// ⭐️ IMPORT uploadAvatar (Named Export)
const { uploadAvatar } = require('../middleware/upload'); 
const { getClassesByStudentId } = require('../controllers/classController');
const { updateStudentProfile } = require('../controllers/studentController');

router.get('/:studentId/classes', getClassesByStudentId);

// ⭐️ CẬP NHẬT: GẮN middleware uploadAvatar
// Đây là route gộp: Xử lý cả text (name) và file (avatar)
router.put(
    '/:studentId/profile', 
    uploadAvatar, // Middleware xử lý file upload, đặt dữ liệu text vào req.body
    updateStudentProfile // Controller xử lý logic cập nhật DB
);

module.exports = router;