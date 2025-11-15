// src/routes/course.js
const express = require("express");
const router = express.Router();
const Course = require("../models/course");

// GET all courses (giả lập cho student)
router.get("/", async (req, res) => {
  try {
    const courses = await Course.find();
    res.json(courses);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET courses by email
router.get("/student/:email", async (req, res) => {
  try {
    const email = req.params.email;
    const courses = await Course.find({ students: email });
    res.json(courses);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST create course (dành cho admin/instructor)
router.post("/", async (req, res) => {
  try {
    const { name, code, coverImage, instructorName, students } = req.body;
    const course = new Course({ name, code, coverImage, instructorName, students });
    await course.save();
    res.status(201).json(course);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
