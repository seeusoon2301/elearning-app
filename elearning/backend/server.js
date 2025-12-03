// server.js
const express = require('express');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const classRoutes = require('./routes/classRoutes');
const authRoutes = require('./routes/authRoutes');
const semesterRoutes = require('./routes/semesterRoutes');
const studentRoutes = require('./routes/studentRoutes');
const studentClassRoutes = require('./routes/studentClassRoutes');
const cors = require('cors');
// Tải biến môi trường từ file .env
dotenv.config();

// Kết nối Database
connectDB();

const app = express();
app.use(cors());
// Middleware: Cho phép Express đọc JSON body
app.use(express.json());

app.use('/api/auth', authRoutes);
// Định nghĩa Routes
app.use('/api/admin/classes', classRoutes);
// Học kỳ
app.use('/api/admin/semesters', semesterRoutes);
// ⭐️ GẮN STUDENT ROUTES VÀO ĐƯỜNG DẪN CHÍNH
app.use('/api/admin/students', studentRoutes);
//api xem lop cua sinh vien
app.use('/api/student', studentClassRoutes);
// Khởi động server
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
    console.log(`Test API endpoint: \n  Login Admin and Student POST: http://localhost:5000/api/auth/login\n  Create Class POST http://localhost:${PORT}/api/admin/classes/create\n  Show all class GET http://localhost:5000/api/admin/classes\n  Delete 1 Class http://localhost:5000/api/admin/classes/delete/:id\n  Create Student POST http://localhost:5000/api/admin/students/create\n  Show all students GET http://localhost:5000/api/admin/students\n  Invite student to class POST http://localhost:5000/api/admin/classes/:classId/invite\n  Get all student of a class GET http://localhost:5000/api/admin/classes/:classId/students\n  Get all annoucncements of a class GET http://localhost:5000/api/admin/classes/:classId/announcements\n  Get classes by student ID GET http://localhost:5000/api/student/:studentId/classes\n  Get classes of student by semester ID GET http://localhost:5000/api/student/:studentId/classes?semesterId=:semesterId`);
});