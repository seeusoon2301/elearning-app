// server.js
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Connect DB
connectDB();

// Routes
app.use('/api/admin/auth', require('./routes/admin/adminAuthRoutes'));
app.use('/api/admin/students', require('./routes/admin/adminStudentRoutes'));
app.use('/api/admin/courses', require('./routes/admin/adminCourseRoutes'));

// Health
app.get('/', (req, res) => res.send('Backend running'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API running on port ${PORT}`));
