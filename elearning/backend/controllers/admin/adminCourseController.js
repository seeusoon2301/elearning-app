// controllers/admin/adminCourseController.js
const Course = require('../../models/Course');
const Student = require('../../models/Student');

// Create course
exports.createCourse = async (req, res) => {
  try {
    const { code, name, sessions, semesterCode } = req.body;
    if (!code || !name) return res.status(400).json({ error: 'code and name required' });
    const exist = await Course.findOne({ code });
    if (exist) return res.status(400).json({ error: 'Course code exists' });
    const c = await Course.create({ code, name, sessions, semesterCode });
    res.status(201).json(c);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// List courses
exports.listCourses = async (req, res) => {
  try {
    const courses = await Course.find().sort({ createdAt: -1 });
    res.json(courses);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Get detail
exports.getCourse = async (req, res) => {
  try {
    const c = await Course.findById(req.params.id).populate('students', 'name email');
    if (!c) return res.status(404).json({ error: 'Course not found' });
    res.json(c);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Update
exports.updateCourse = async (req, res) => {
  try {
    const { code, name, sessions, semesterCode } = req.body;
    const c = await Course.findByIdAndUpdate(req.params.id, { code, name, sessions, semesterCode }, { new: true });
    if (!c) return res.status(404).json({ error: 'Course not found' });
    res.json(c);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Delete
exports.deleteCourse = async (req, res) => {
  try {
    const c = await Course.findByIdAndDelete(req.params.id);
    if (!c) return res.status(404).json({ error: 'Course not found' });
    res.json({ message: 'Deleted' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Add student to course
exports.addStudent = async (req, res) => {
  try {
    const { courseId, studentId } = req.params;
    const c = await Course.findById(courseId);
    const s = await Student.findById(studentId);
    if (!c || !s) return res.status(404).json({ error: 'Course or Student not found' });
    if (!c.students.includes(s._id)) c.students.push(s._id);
    if (!s.courses.includes(c._id)) s.courses.push(c._id);
    await c.save();
    await s.save();
    res.json({ message: 'Student added', course: c });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Remove student
exports.removeStudent = async (req, res) => {
  try {
    const { courseId, studentId } = req.params;
    const c = await Course.findById(courseId);
    const s = await Student.findById(studentId);
    if (!c || !s) return res.status(404).json({ error: 'Course or Student not found' });
    c.students.pull(s._id);
    s.courses.pull(c._id);
    await c.save();
    await s.save();
    res.json({ message: 'Removed' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};
