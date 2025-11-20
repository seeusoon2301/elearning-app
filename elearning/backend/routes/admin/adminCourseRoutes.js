// routes/admin/adminCourseRoutes.js
const express = require('express');
const router = express.Router();
const adminAuth = require('../../middleware/adminAuth');
const ctrl = require('../../controllers/admin/adminCourseController');

router.post('/', adminAuth, ctrl.createCourse);
router.get('/', adminAuth, ctrl.listCourses);
router.get('/:id', adminAuth, ctrl.getCourse);
router.put('/:id', adminAuth, ctrl.updateCourse);
router.delete('/:id', adminAuth, ctrl.deleteCourse);

// add/remove student
router.post('/:courseId/add/:studentId', adminAuth, ctrl.addStudent);
router.post('/:courseId/remove/:studentId', adminAuth, ctrl.removeStudent);

module.exports = router;
