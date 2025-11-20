// models/Course.js
const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema({
  code: { type: String, required: true },
  name: { type: String, required: true },
  sessions: { type: Number, enum: [10, 15], default: 10 },
  semesterCode: String,
  students: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }]
}, { timestamps: true });

module.exports = mongoose.model('Course', courseSchema);
