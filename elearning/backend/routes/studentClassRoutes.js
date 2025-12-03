// routes/studentClassRoutes.js
const express = require('express');
const router = express.Router();
const { getClassesByStudentId } = require('../controllers/classController');

// GET /api/classes (Đường dẫn cuối cùng sẽ là /api/classes)

router.get('/:studentId/classes', getClassesByStudentId);

module.exports = router;