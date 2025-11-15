// src/models/course.js
const mongoose = require("mongoose");

const courseSchema = new mongoose.Schema({
  name: String,
  code: String,
  coverImage: String,
  instructorName: String,
  students: [String] // lưu email student
});

module.exports = mongoose.model("Course", courseSchema);
