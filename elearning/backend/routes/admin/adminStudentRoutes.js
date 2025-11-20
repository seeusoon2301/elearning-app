// routes/admin/adminStudentRoutes.js
const express = require('express');
const router = express.Router();
const adminAuth = require('../../middleware/adminAuth');
const ctrl = require('../../controllers/admin/adminStudentController');

// All admin student routes protected
router.post('/', adminAuth, ctrl.createStudent);
router.get('/', adminAuth, ctrl.listStudents);
router.get('/:id', adminAuth, ctrl.getStudent);
router.put('/:id', adminAuth, ctrl.updateStudent);
router.delete('/:id', adminAuth, ctrl.deleteStudent);

module.exports = router;
