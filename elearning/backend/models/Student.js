// models/Student.js
const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
  mssv: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  dob: Date,
  avatar: String,
  courses: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Course' }]
}, { timestamps: true });

module.exports = mongoose.model('Student', studentSchema);
