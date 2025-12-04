// routes/studentClassRoutes.js
const express = require('express');
const router = express.Router();
const { getClassesByStudentId } = require('../controllers/classController');
const { updateStudentProfile } = require('../controllers/studentController');
// GET /api/classes (Đường dẫn cuối cùng sẽ là /api/classes)

router.get('/:studentId/classes', getClassesByStudentId);
router.put('/:studentId/profile', updateStudentProfile);
module.exports = router;