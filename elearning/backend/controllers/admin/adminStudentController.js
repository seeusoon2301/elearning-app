// controllers/admin/adminStudentController.js
const Student = require('../../models/Student');
const Course = require('../../models/Course');

// Create student
exports.createStudent = async (req, res) => {
  try {
    const { mssv, name, email, dob, avatar } = req.body;
    if (!mssv || !name || !email) return res.status(400).json({ error: 'MSSV, Name and email required' });
    const exist = await Student.findOne({ email });
    if (exist) return res.status(400).json({ error: 'Email already exists' });
    const s = await Student.create({ mssv, name, email, dob, avatar });
    res.status(201).json(s);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Get list students
exports.listStudents = async (req, res) => {
  try {
    const students = await Student.find().sort({ createdAt: -1 });
    res.json(students);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Get student detail
exports.getStudent = async (req, res) => {
  try {
    const s = await Student.findById(req.params.id).populate('courses', 'code name');
    if (!s) return res.status(404).json({ error: 'Student not found' });
    res.json(s);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Update student (no email change)
exports.updateStudent = async (req, res) => {
  try {
    const { name, dob, avatar } = req.body;
    const s = await Student.findByIdAndUpdate(req.params.id, { name, dob, avatar }, { new: true });
    if (!s) return res.status(404).json({ error: 'Student not found' });
    res.json(s);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};

// Delete student
exports.deleteStudent = async (req, res) => {
  try {
    const s = await Student.findByIdAndDelete(req.params.id);
    if (!s) return res.status(404).json({ error: 'Student not found' });
    // also remove from courses
    await Course.updateMany({}, { $pull: { students: s._id } });
    res.json({ message: 'Deleted' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
};
